#' Get names of active workflows from a package/directory.
#'
#' @description `r lifecycle::badge("experimental")`
#'
#'   Discovers YAML workflow files in the given location and returns the names
#'   of those whose `meta$MetricActive` is not explicitly `FALSE`. This is the
#'   same discovery logic used by [MakeWorkflowList()], and its result is
#'   suitable for passing directly to its `strNames` argument.
#'
#' @param strNames `array of character` Optional subset of workflow names to
#'   consider. `NULL` (the default) considers all discovered workflows.
#' @param strPath `character` The location of workflow YAML files, relative to
#'   either the working directory or the `strPackage` installation directory.
#' @param strPackage `character` The package name where the workflow YAML files
#'   are located. If `NULL`, an absolute path is used.
#' @param bExact `logical` Should `strNames` matches be exact? Default `FALSE`.
#' @param bRecursive `logical` Find files in nested folders? Default `TRUE`.
#'
#' @return `character` A character vector of workflow names (IDs) whose
#'   `meta$MetricActive` is absent or `TRUE`.
#'
#' @examples
#' GetActiveWorkflows(
#'   strPath = "workflows",
#'   strPackage = "workr"
#' )
#'
#' @export
GetActiveWorkflows <- function(
  strNames = NULL,
  strPath = "workflow",
  strPackage = NULL,
  bExact = FALSE,
  bRecursive = TRUE
) {
  path <- .workflow_path(strPath, strPackage)
  yaml_files <- .discover_yaml_files(path, bRecursive)
  yaml_files <- .filter_yaml_files(yaml_files, strNames, bExact)

  active_files <- purrr::keep(yaml_files, function(yaml_file) {
    wf <- suppressWarnings(yaml::read_yaml(yaml_file))
    metric_active <- wf$meta$MetricActive
    is.null(metric_active) || isTRUE(metric_active)
  })

  I(sub("\\.yaml$", "", names(active_files)))
}

#' Resolve and validate a workflow directory path
#'
#' @keywords internal
#' @noRd
.workflow_path <- function(strPath, strPackage) {
  path <- strPath
  if (length(strPackage)) {
    path <- system.file(strPath, package = strPackage)
  }
  stop_if(!dir.exists(path), "[ strPath ] must exist.")
  tools::file_path_as_absolute(path)
}

#' Discover all YAML files under a path
#'
#' @keywords internal
#' @noRd
.discover_yaml_files <- function(path, bRecursive) {
  yaml_files <- list.files(
    path,
    pattern = "\\.yaml$",
    full.names = TRUE,
    recursive = bRecursive
  )
  names(yaml_files) <- list.files(
    path,
    pattern = "\\.yaml$",
    full.names = FALSE,
    recursive = bRecursive
  )
  names(yaml_files) <- basename(names(yaml_files))
  yaml_files
}

#' Subset a yaml_files vector to those matching strNames
#'
#' @keywords internal
#' @noRd
.filter_yaml_files <- function(yaml_files, strNames, bExact) {
  if (is.null(strNames)) {
    return(yaml_files)
  }
  good_strNames <- c(strNames, paste0(strNames, ".yaml"))
  if (bExact) {
    purrr::keep(yaml_files, names(yaml_files) %in% good_strNames)
  } else {
    purrr::keep(
      yaml_files,
      grepl(paste(strNames, collapse = "|"), names(yaml_files))
    )
  }
}
