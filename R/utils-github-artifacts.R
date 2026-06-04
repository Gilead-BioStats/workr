normalize_github_artifact_scalar <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NULL)
  }

  if (!is.atomic(x) || length(x) != 1) {
    return(NULL)
  }

  value <- as.character(x[[1]])
  if (!nzchar(value)) {
    return(NULL)
  }

  value
}

github_artifact_config <- function(lConfig, lWorkflow = NULL) {
  cfg <- lConfig$github_artifact %||% list()
  stop_if(!is.list(cfg), "`lConfig$github_artifact` must be a list when provided.")

  cfg$path <- normalize_github_artifact_scalar(cfg$path) %||% tempdir()
  cfg$download_dir <- normalize_github_artifact_scalar(cfg$download_dir) %||% tempdir()
  cfg$artifact_name <- normalize_github_artifact_scalar(cfg$artifact_name) %||%
    if (!is.null(lWorkflow)) {
      workflow_id <- lWorkflow$meta$ID %||% lWorkflow$uid %||% "workflow"
      paste0("workr-", workflow_id)
    } else {
      NULL
    }
  cfg$repo <- normalize_github_artifact_scalar(cfg$repo) %||%
    normalize_github_artifact_scalar(Sys.getenv("GITHUB_REPOSITORY", unset = ""))
  cfg$run_id <- normalize_github_artifact_scalar(cfg$run_id) %||%
    normalize_github_artifact_scalar(Sys.getenv("GITHUB_RUN_ID", unset = ""))
  cfg$policy <- normalize_github_artifact_scalar(cfg$policy)
  cfg$on_missing <- normalize_github_artifact_scalar(cfg$on_missing) %||% "fatal"

  cfg
}

github_artifact_match_rules <- function(keys, rules) {
  if (is.null(rules)) {
    return(rep(TRUE, length(keys)))
  }

  stop_if(!is.character(rules), "Artifact include/exclude rules must be character vectors.")

  vapply(
    keys,
    function(key) {
      any(vapply(
        rules,
        function(rule) {
          identical(key, rule) || grepl(rule, key, perl = TRUE)
        },
        logical(1)
      ))
    },
    logical(1)
  )
}

github_artifact_select_keys <- function(keys, include = NULL, exclude = NULL) {
  if (length(keys) == 0) {
    return(character(0))
  }

  selected <- github_artifact_match_rules(keys, include)
  if (!is.null(exclude)) {
    selected <- selected & !github_artifact_match_rules(keys, exclude)
  }

  keys[selected]
}

github_artifact_repo_parts <- function(repo) {
  repo <- normalize_github_artifact_scalar(repo)
  stop_if(is.null(repo), "`lConfig$github_artifact$repo` must be set for GitHub artifact resolution.")

  parts <- strsplit(repo, "/", fixed = TRUE)[[1]]
  stop_if(length(parts) != 2 || !all(nzchar(parts)), "`lConfig$github_artifact$repo` must use the form `owner/repo`.")

  list(owner = parts[[1]], repo = parts[[2]])
}

github_artifact_signal_missing <- function(reason, on_missing, run_id, policy) {
  msg <- glue::glue(
    "Artifact restore failed for run-id {run_id %||% '<unresolved>'} (policy: {policy}): {reason}"
  )

  stop_if(!on_missing %in% c("fatal", "warn"), "`on_missing` must be either `fatal` or `warn`.")

  if (identical(on_missing, "warn")) {
    LogMessage(level = "warn", message = "{msg}")
    return(invisible(FALSE))
  }

  stop(msg, call. = FALSE)
}

gh_actions_find_artifact <- function(repo, run_id, artifact_name) {
  parts <- github_artifact_repo_parts(repo)
  response <- gh::gh(
    "GET /repos/{owner}/{repo}/actions/runs/{run_id}/artifacts",
    owner = parts$owner,
    repo = parts$repo,
    run_id = run_id,
    per_page = 100
  )

  artifacts <- response$artifacts %||% list()
  if (length(artifacts) == 0) {
    return(NULL)
  }

  if (is.null(artifact_name)) {
    return(artifacts[[1]])
  }

  for (artifact in artifacts) {
    if (identical(artifact$name, artifact_name)) {
      return(artifact)
    }
  }

  NULL
}

gh_actions_download_artifact_bundle <- function(repo, run_id, artifact_name, download_dir) {
  artifact <- gh_actions_find_artifact(repo, run_id, artifact_name)
  if (is.null(artifact)) {
    stop(
      glue::glue("Artifact `{artifact_name %||% '<first>'}` not found for run-id {run_id}."),
      call. = FALSE
    )
  }

  bundle_dir <- file.path(download_dir, artifact$name)
  dir.create(bundle_dir, recursive = TRUE, showWarnings = FALSE)

  zip_path <- file.path(bundle_dir, "artifact.zip")
  parts <- github_artifact_repo_parts(repo)
  gh::gh(
    "GET /repos/{owner}/{repo}/actions/artifacts/{artifact_id}/zip",
    owner = parts$owner,
    repo = parts$repo,
    artifact_id = artifact$id,
    .destfile = zip_path
  )

  utils::unzip(zip_path, exdir = bundle_dir)
  unlink(zip_path)

  bundle_dir
}

github_artifact_resolve_run_id <- function(cfg, lWorkflow, lConfig) {
  if (!is.null(cfg$run_id)) {
    return(cfg$run_id)
  }

  policy <- cfg$policy %||% "latest_success"
  if (is.function(cfg$run_resolver)) {
    return(as.character(cfg$run_resolver(
      repo = cfg$repo,
      policy = policy,
      lWorkflow = lWorkflow,
      lConfig = lConfig
    )))
  }

  if (!identical(policy, "latest_success")) {
    stop(glue::glue("Unsupported GitHub artifact policy `{policy}`."), call. = FALSE)
  }

  parts <- github_artifact_repo_parts(cfg$repo)
  response <- gh::gh(
    "GET /repos/{owner}/{repo}/actions/runs",
    owner = parts$owner,
    repo = parts$repo,
    status = "success",
    per_page = 1
  )

  runs <- response$workflow_runs %||% list()
  if (length(runs) == 0) {
    stop("No successful workflow runs found.", call. = FALSE)
  }

  as.character(runs[[1]]$id)
}

github_artifact_save_provider <- function(lWorkflow, lConfig) {
  cfg <- github_artifact_config(lConfig = lConfig, lWorkflow = lWorkflow)
  keys <- names(lWorkflow$lData %||% list())
  selected_keys <- github_artifact_select_keys(
    keys = keys,
    include = cfg$include,
    exclude = cfg$exclude
  )

  bundle_dir <- file.path(cfg$path, cfg$artifact_name)
  payload_dir <- file.path(bundle_dir, "payload")
  dir.create(payload_dir, recursive = TRUE, showWarnings = FALSE)

  entries <- lapply(seq_along(selected_keys), function(index) {
    key <- selected_keys[[index]]
    safe_key <- gsub("[^A-Za-z0-9._-]", "_", key)
    rel_path <- sprintf("payload/%03d-%s.rds", index, safe_key)
    saveRDS(lWorkflow$lData[[key]], file.path(bundle_dir, rel_path))
    list(key = key, file = rel_path)
  })

  manifest <- list(
    provider = "github_artifact",
    artifact_name = cfg$artifact_name,
    run_id = cfg$run_id,
    workflow_id = lWorkflow$meta$ID %||% NULL,
    retention_days = cfg$retention_days %||% NULL,
    entries = entries
  )

  manifest_path <- file.path(bundle_dir, "manifest.yaml")
  yaml::write_yaml(manifest, manifest_path)

  if (is.function(cfg$uploader)) {
    cfg$uploader(
      bundle_dir = bundle_dir,
      artifact_name = cfg$artifact_name,
      retention_days = cfg$retention_days %||% NULL,
      manifest_path = manifest_path,
      lWorkflow = lWorkflow,
      lConfig = lConfig
    )
  }

  invisible(list(
    bundle_dir = bundle_dir,
    manifest_path = manifest_path,
    selected_keys = selected_keys
  ))
}

github_artifact_load_provider <- function(lWorkflow, lConfig, lData) {
  cfg <- github_artifact_config(lConfig = lConfig, lWorkflow = lWorkflow)
  policy <- if (!is.null(cfg$run_id)) "explicit" else cfg$policy %||% "latest_success"

  run_id <- tryCatch(
    github_artifact_resolve_run_id(cfg, lWorkflow, lConfig),
    error = function(e) {
      github_artifact_signal_missing(
        reason = conditionMessage(e),
        on_missing = cfg$on_missing,
        run_id = cfg$run_id,
        policy = policy
      )
      NULL
    }
  )
  if (is.null(run_id)) {
    return(lData)
  }

  bundle_dir <- tryCatch(
    if (is.function(cfg$artifact_fetcher)) {
      cfg$artifact_fetcher(
        repo = cfg$repo,
        run_id = run_id,
        artifact_name = cfg$artifact_name,
        download_dir = cfg$download_dir,
        lWorkflow = lWorkflow,
        lConfig = lConfig
      )
    } else {
      gh_actions_download_artifact_bundle(
        repo = cfg$repo,
        run_id = run_id,
        artifact_name = cfg$artifact_name,
        download_dir = cfg$download_dir
      )
    },
    error = function(e) {
      github_artifact_signal_missing(
        reason = conditionMessage(e),
        on_missing = cfg$on_missing,
        run_id = run_id,
        policy = policy
      )
      NULL
    }
  )
  if (is.null(bundle_dir)) {
    return(lData)
  }

  manifest_paths <- list.files(
    bundle_dir,
    pattern = "^manifest\\.ya?ml$",
    recursive = TRUE,
    full.names = TRUE
  )
  manifest_path <- if (length(manifest_paths) == 0) NULL else manifest_paths[[1]]
  if (is.null(manifest_path)) {
    github_artifact_signal_missing(
      reason = "manifest.yaml is missing from the downloaded artifact bundle.",
      on_missing = cfg$on_missing,
      run_id = run_id,
      policy = policy
    )
    return(lData)
  }

  manifest <- tryCatch(
    yaml::read_yaml(manifest_path),
    error = function(e) {
      github_artifact_signal_missing(
        reason = paste0("manifest.yaml could not be parsed: ", conditionMessage(e)),
        on_missing = cfg$on_missing,
        run_id = run_id,
        policy = policy
      )
      NULL
    }
  )
  if (is.null(manifest)) {
    return(lData)
  }

  entries <- manifest$entries %||% list()
  manifest_dir <- dirname(manifest_path)
  restored <- lData

  for (entry in entries) {
    key <- entry$key %||% NULL
    rel_path <- entry$file %||% NULL

    if (is.null(key) || is.null(rel_path)) {
      github_artifact_signal_missing(
        reason = "manifest entry is missing `key` or `file`.",
        on_missing = cfg$on_missing,
        run_id = run_id,
        policy = policy
      )
      next
    }

    payload_path <- file.path(manifest_dir, rel_path)
    if (!file.exists(payload_path)) {
      github_artifact_signal_missing(
        reason = glue::glue("payload file `{rel_path}` is missing for key `{key}`."),
        on_missing = cfg$on_missing,
        run_id = run_id,
        policy = policy
      )
      next
    }

    value <- tryCatch(
      readRDS(payload_path),
      error = function(e) {
        github_artifact_signal_missing(
          reason = glue::glue("payload file `{rel_path}` is corrupt for key `{key}`: {conditionMessage(e)}"),
          on_missing = cfg$on_missing,
          run_id = run_id,
          policy = policy
        )
        NULL
      }
    )

    if (!is.null(value)) {
      restored[[key]] <- value
    }
  }

  restored
}

workr_register_builtin_providers <- function() {
  register_load_provider("github_artifact", github_artifact_load_provider)
  register_save_provider("github_artifact", github_artifact_save_provider)
  invisible(TRUE)
}

.onLoad <- function(libname, pkgname) {
  workr_register_builtin_providers()
  invisible(NULL)
}