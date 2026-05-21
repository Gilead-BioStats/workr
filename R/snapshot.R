#' Create a Package Manifest
#'
#' Creates a reproducible manifest of a list of GitHub-hosted R packages,
#' generating a manifest.csv, rproject.toml, and pulling workflow files.
#' This function captures the versions and workflow definitions for a set of packages
#' at a given point in time, enabling reproducible package environments.
#'
#' @param path Character. Path to save the manifest output. Default: "."
#' @param packageList Character vector of GitHub refs in the format
#'   "org/repo", "org/repo@tag", or "org/repo@sha".
#' @param date Date or character (YYYY-MM-DD). If no tag/sha is provided in a
#'   ref, resolve the most recent release on or before this date. Default: NULL
#'   (uses the latest release or default branch HEAD).
#' @param branch Character or NULL. If provided, use this branch for any refs
#'   that don't specify a tag/sha. Overrides date-based resolution.
#'
#' @return Invisibly returns the manifest data frame.
#'
#' @examples
#' \dontrun{
#' pkgManifest(
#'   path = "2025-q4-release",
#'   packageList = c(
#'     "Gilead-BioStats/gsm@v1.8.4",
#'     "Gilead-BioStats/grail"
#'   ),
#'   branch = "dev"
#' )
#' }
#' @export
pkgManifest <- function(path = ".", packageList = character(), date = NULL,
                        branch = NULL) {
  if (length(packageList) == 0) {
    stop("packageList must contain at least one GitHub ref (e.g., 'org/repo@tag')")
  }

  if (!is.null(date)) {
    date <- as.Date(date)
  }

  # Parse refs
  parsed <- lapply(packageList, parse_github_ref)

  # Resolve each package
  resolved <- lapply(parsed, function(pkg) {
    ref <- pkg$ref
    if (is.null(ref) && !is.null(branch)) {
      ref <- branch
    }
    resolve_package(pkg$org, pkg$repo, ref, date)
  })

  manifest <- do.call(rbind, lapply(resolved, function(r) {
    data.frame(
      org = r$org,
      package = r$repo,
      version = r$version,
      repository = r$repository,
      url = r$url,
      sha = r$sha,
      stringsAsFactors = FALSE
    )
  }))

  # Create output directory
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE)
  }

  # Write manifest.csv
  write.csv(manifest, file.path(path, "manifest.csv"), row.names = FALSE)
  message("Wrote manifest.csv")

  # Write rproject.toml
  write_rproject_toml(manifest, path)
  message("Wrote rproject.toml")

  # Pull workflows
  pull_workflows(resolved, path)
  message("Pulled workflows")

  invisible(manifest)
}
