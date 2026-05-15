#' Pull workflow files from inst/workflow or inst/workflows for each package
#'
#' For each resolved package, checks `inst/workflow` first, then falls back to
#' `inst/workflows`. Only when both are absent is the package skipped with a
#' message. Matched files are merged directly into a `workflows/` subdirectory
#' under `path`. Duplicate output paths across packages are detected and can
#' emit warnings or errors.
#'
#' @param resolved List of resolved package metadata (each with org, repo, sha).
#' @param path Character. Output directory.
#' @param collision_action Character. How to handle collisions when multiple
#'   packages map to the same destination path in `workflows/`. One of
#'   `"warn"` (default) or `"error"`.
pull_workflows <- function(resolved, path, collision_action = c("warn", "error")) {
  collision_action <- match.arg(collision_action)
  workflows_dir <- file.path(path, "workflows")
  collision_registry <- new.env(parent = emptyenv())
  if (!dir.exists(workflows_dir)) {
    dir.create(workflows_dir, recursive = TRUE)
  }

  for (pkg in resolved) {
    full_repo <- paste0(pkg$org, "/", pkg$repo)
    workflow_dirs <- c("inst/workflow", "inst/workflows")
    entries <- NULL
    for (workflow_dir in workflow_dirs) {
      entries <- gh_list_contents(full_repo, workflow_dir, pkg$sha)
      if (!is.null(entries)) {
        break
      }
    }

    if (is.null(entries)) {
      message("  No workflows found in inst/workflow or inst/workflows for ", full_repo, " -- skipping")
      next
    }

    # Merge directly into workflows_dir (no per-repo subfolder)
    for (entry in entries) {
      if (entry$type == "dir") {
        pull_workflow_dir(
          full_repo, pkg$sha, entry$path, file.path(workflows_dir, entry$name),
          source_repo = full_repo,
          collision_registry = collision_registry,
          collision_action = collision_action
        )
      } else {
        pull_workflow_file(
          full_repo, pkg$sha, entry$path, file.path(workflows_dir, entry$name),
          source_repo = full_repo,
          collision_registry = collision_registry,
          collision_action = collision_action
        )
      }
    }
  }
}

#' List contents of a GitHub directory, returning name/type/path for each entry
#' @keywords internal
gh_list_contents <- function(full_repo, dir_path, sha) {
  json_str <- gh_api(
    c("api", paste0("repos/", full_repo, "/contents/", dir_path, "?ref=", sha))
  )

  if (length(json_str) == 0 || any(grepl("Not Found", json_str))) {
    return(NULL)
  }

  # Re-call gh with separate jq queries for each field.
  names <- gh_api(
    c("api", paste0("repos/", full_repo, "/contents/", dir_path, "?ref=", sha),
      "--jq", ".[].name")
  )
  types <- gh_api(
    c("api", paste0("repos/", full_repo, "/contents/", dir_path, "?ref=", sha),
      "--jq", ".[].type")
  )
  paths <- gh_api(
    c("api", paste0("repos/", full_repo, "/contents/", dir_path, "?ref=", sha),
      "--jq", ".[].path")
  )

  if (length(names) == 0) return(NULL)

  mapply(function(n, t, p) list(name = n, type = t, path = p),
         trimws(names), trimws(types), trimws(paths),
         SIMPLIFY = FALSE, USE.NAMES = FALSE)
}

#' Recursively pull a directory of workflow files
#' @keywords internal
pull_workflow_dir <- function(full_repo, sha, api_path, local_dir,
                              source_repo = full_repo,
                              collision_registry = NULL,
                              collision_action = "warn") {
  if (!dir.exists(local_dir)) {
    dir.create(local_dir, recursive = TRUE)
  }

  entries <- gh_list_contents(full_repo, api_path, sha)
  if (is.null(entries)) return(invisible(NULL))

  for (entry in entries) {
    if (entry$type == "dir") {
      pull_workflow_dir(
        full_repo, sha, entry$path, file.path(local_dir, entry$name),
        source_repo = source_repo,
        collision_registry = collision_registry,
        collision_action = collision_action
      )
    } else {
      pull_workflow_file(
        full_repo, sha, entry$path, file.path(local_dir, entry$name),
        source_repo = source_repo,
        collision_registry = collision_registry,
        collision_action = collision_action
      )
    }
  }
}

#' Pull a single workflow file from GitHub
#' @keywords internal
pull_workflow_file <- function(full_repo, sha, api_path, local_path,
                               source_repo = full_repo,
                               collision_registry = NULL,
                               collision_action = "warn") {
  if (!is.null(collision_registry)) {
    collision_key <- normalizePath(local_path, winslash = "/", mustWork = FALSE)
    if (exists(collision_key, envir = collision_registry, inherits = FALSE)) {
      previous_repo <- get(collision_key, envir = collision_registry, inherits = FALSE)
      if (!identical(previous_repo, source_repo)) {
        msg <- paste0(
          "Collision detected for destination path '", local_path, "' between ",
          previous_repo, " and ", source_repo
        )
        if (identical(collision_action, "error")) {
          stop(msg)
        }
        warning(msg, call. = FALSE)
      }
    }
    assign(collision_key, source_repo, envir = collision_registry)
  }

  file_content <- gh_api(
    c("api", paste0("repos/", full_repo, "/contents/", api_path, "?ref=", sha),
      "--jq", ".content")
  )

  if (length(file_content) > 0 && !any(grepl("Not Found", file_content))) {
    decoded <- rawToChar(base64enc::base64decode(paste0(file_content, collapse = "")))
    writeLines(decoded, local_path)
    message("  Pulled ", basename(local_path), " from ", full_repo)
  }
}
