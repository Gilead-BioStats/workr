#' Generate a package list from a manifest.csv file
#'
#' Reads a manifest.csv and returns a character vector of GitHub refs
#' formatted for use with \code{pkgManifest()}.
#'
#' @param path Character. Path to the manifest.csv file.
#' @return Character vector of GitHub refs in "org/repo" format.
#'
#' @examples
#' \dontrun{
#' pkgs <- pkgListFromManifest("manifest.csv")
#' pkgManifest(packageList = pkgs, branch = "dev")
#' }
pkgListFromManifest <- function(path = "manifest.csv") {
  if (!file.exists(path)) {
    stop("Manifest file not found: ", path)
  }

  manifest <- read.csv(path, stringsAsFactors = FALSE)

  required_cols <- c("org", "package")
  missing <- setdiff(required_cols, names(manifest))
  if (length(missing) > 0) {
    stop("Manifest is missing required columns: ", paste(missing, collapse = ", "))
  }

  paste0(manifest$org, "/", manifest$package)
}
