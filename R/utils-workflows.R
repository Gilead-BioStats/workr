#' Pull workflow files from inst/workflow for each package
#'
#' For each resolved package, pulls files from `inst/workflow`. If that
#' directory is missing but `inst/workflows` exists, a warning asks maintainers
#' to rename to the preferred convention and re-run `snapshot()`. Pulled files
#' are merged directly into a `workflows/` subdirectory under `path`.
#' Destination filename collisions across repositories emit a warning and the
#' most recently pulled file wins.
#'
#' @param resolved List of resolved package metadata (each with org, repo, sha).
#' @param path Character. Output directory.
pull_workflows <- function(resolved, path) {
  workflows_dir <- file.path(path, "workflows")
  seen_files <- new.env(parent = emptyenv())
  if (!dir.exists(workflows_dir)) {
    dir.create(workflows_dir, recursive = TRUE)
  }

  for (pkg in resolved) {
    full_repo <- paste0(pkg$org, "/", pkg$repo)
    entries <- gh_list_contents(full_repo, "inst/workflow", pkg$sha)

    if (is.null(entries)) {
      plural_entries <- gh_list_contents(full_repo, "inst/workflows", pkg$sha)
      if (!is.null(plural_entries)) {
        warning(
          "Directory 'inst/workflow' not found for ",
          full_repo,
          ". Found 'inst/workflows' instead; rename to 'inst/workflow' and re-run snapshot().",
          call. = FALSE
        )
      } else {
        message("  No inst/workflow found for ", full_repo, " -- skipping")
      }
      next
    }

    for (entry in entries) {
      if (entry$type == "dir") {
        pull_workflow_dir(
          full_repo, pkg$sha, entry$path, file.path(workflows_dir, entry$name),
          source_repo = full_repo,
          seen_files = seen_files
        )
      } else {
        pull_workflow_file(
          full_repo, pkg$sha, entry$path, file.path(workflows_dir, entry$name),
          source_repo = full_repo,
          seen_files = seen_files
        )
      }
    }
  }
}

#' List contents of a GitHub directory, returning name/type/path for each entry
#' @keywords internal
gh_list_contents <- function(full_repo, dir_path, sha) {
  json_str <- gh_api_client(
    c("api", paste0("repos/", full_repo, "/contents/", dir_path, "?ref=", sha))
  )

  if (length(json_str) == 0 || any(grepl("Not Found", json_str))) {
    return(NULL)
  }

  # Re-call gh with separate jq queries for each field.
  names <- gh_api_client(
    c("api", paste0("repos/", full_repo, "/contents/", dir_path, "?ref=", sha),
      "--jq", ".[].name")
  )
  types <- gh_api_client(
    c("api", paste0("repos/", full_repo, "/contents/", dir_path, "?ref=", sha),
      "--jq", ".[].type")
  )
  paths <- gh_api_client(
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
                              seen_files = NULL) {
  if (file.exists(local_dir) && !dir.exists(local_dir)) {
    warning(
      "Cannot create workflow directory '",
      local_dir,
      "' for ",
      source_repo,
      ": a file already exists at this path. Skipping.",
      call. = FALSE
    )
    return(invisible(NULL))
  }

  if (!dir.exists(local_dir)) {
    dir.create(local_dir, recursive = TRUE)
  }

  entries <- gh_list_contents(full_repo, api_path, sha)
  if (is.null(entries)) {
    return(invisible(NULL))
  }

  for (entry in entries) {
    if (entry$type == "dir") {
      pull_workflow_dir(
        full_repo, sha, entry$path, file.path(local_dir, entry$name),
        source_repo = source_repo,
        seen_files = seen_files
      )
    } else {
      pull_workflow_file(
        full_repo, sha, entry$path, file.path(local_dir, entry$name),
        source_repo = source_repo,
        seen_files = seen_files
      )
    }
  }
}

#' Pull a single workflow file from GitHub
#' @keywords internal
pull_workflow_file <- function(full_repo, sha, api_path, local_path,
                               source_repo = full_repo,
                               seen_files = NULL) {
  file_content <- gh_api_client(
    c("api", paste0("repos/", full_repo, "/contents/", api_path, "?ref=", sha),
      "--jq", ".content")
  )

  if (length(file_content) == 0 || any(grepl("Not Found", file_content))) {
    return(invisible(NULL))
  }

  warn_workflow_collision(local_path, source_repo, seen_files)

  decoded <- rawToChar(base64enc::base64decode(paste0(file_content, collapse = "")))
  writeLines(decoded, local_path)
  register_workflow_file(local_path, source_repo, seen_files)
  message("  Pulled ", basename(local_path), " from ", full_repo)
}

warn_workflow_collision <- function(local_path, source_repo, seen_files) {
  if (is.null(seen_files)) {
    return(invisible(FALSE))
  }

  collision_key <- normalizePath(local_path, winslash = "/", mustWork = FALSE)
  existing_keys <- ls(seen_files, all.names = TRUE)
  if (!(collision_key %in% existing_keys)) {
    return(invisible(FALSE))
  }

  previous_repo <- get(collision_key, envir = seen_files, inherits = FALSE)
  if (!identical(previous_repo, source_repo)) {
    warning(
      "Workflow destination collision for '",
      local_path,
      "' between ",
      previous_repo,
      " and ",
      source_repo,
      ". Keeping latest file.",
      call. = FALSE
    )
    return(invisible(TRUE))
  }

  invisible(FALSE)
}

register_workflow_file <- function(local_path, source_repo, seen_files) {
  if (is.null(seen_files)) {
    return(invisible(NULL))
  }

  collision_key <- normalizePath(local_path, winslash = "/", mustWork = FALSE)
  assign(collision_key, source_repo, envir = seen_files)
  invisible(NULL)
}
