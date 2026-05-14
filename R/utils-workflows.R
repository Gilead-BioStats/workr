#' Pull workflow files from inst/workflow for each package
#'
#' @param resolved List of resolved package metadata (each with org, repo, sha).
#' @param path Character. Output directory.
pull_workflows <- function(resolved, path) {
  workflows_dir <- file.path(path, "workflows")
  if (!dir.exists(workflows_dir)) {
    dir.create(workflows_dir, recursive = TRUE)
  }

  for (pkg in resolved) {
    full_repo <- paste0(pkg$org, "/", pkg$repo)
    # List inst/workflow contents as JSON
    entries <- gh_list_contents(full_repo, "inst/workflow", pkg$sha)

    if (is.null(entries)) {
      message("  No inst/workflow found for ", full_repo, " -- skipping")
      next
    }

    # Merge directly into workflows_dir (no per-repo subfolder)
    for (entry in entries) {
      if (entry$type == "dir") {
        pull_workflow_dir(full_repo, pkg$sha, entry$path, file.path(workflows_dir, entry$name))
      } else {
        pull_workflow_file(full_repo, pkg$sha, entry$path, file.path(workflows_dir, entry$name))
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

  # Minimal JSON parsing — extract name, type, path from each object
  json_text <- paste0(json_str, collapse = "\n")

  # Use R's built-in JSON-ish parsing via the gh CLI --jq, but since that's

  # problematic with escaping, parse the raw JSON with a simple approach
  # We'll re-call gh with separate jq queries for each field
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
pull_workflow_dir <- function(full_repo, sha, api_path, local_dir) {
  if (!dir.exists(local_dir)) {
    dir.create(local_dir, recursive = TRUE)
  }

  entries <- gh_list_contents(full_repo, api_path, sha)
  if (is.null(entries)) return(invisible(NULL))

  for (entry in entries) {
    if (entry$type == "dir") {
      pull_workflow_dir(full_repo, sha, entry$path, file.path(local_dir, entry$name))
    } else {
      pull_workflow_file(full_repo, sha, entry$path, file.path(local_dir, entry$name))
    }
  }
}

#' Pull a single workflow file from GitHub
#' @keywords internal
pull_workflow_file <- function(full_repo, sha, api_path, local_path) {
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
