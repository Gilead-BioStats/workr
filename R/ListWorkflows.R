#' List workflow YAML files in a package/directory.
#'
#' @description `r lifecycle::badge("stable")`
#'
#'   Returns a named character vector of paths to workflow YAML files, similar
#'   to [fs::dir_ls()]. Use [ListWorkflowNames()] to get just the bare workflow
#'   names, or [MakeWorkflowList()] to load and validate the workflows.
#'
#' @param strPath `character` The location of workflow YAML files, relative to
#'   either the working directory or the `strPackage` installation directory.
#' @param strPackage `character` The package name where the workflow YAML files
#'   are located. If `NULL`, uses an absolute path.
#' @param bRecursive `logical` Find files in nested folders? Default `TRUE`.
#'
#' @return `character` A named character vector of absolute paths to YAML files,
#'   where names are the bare filenames (e.g. `"cars.yaml"`).
#'
#' @examples
#' ListWorkflows(strPath = "workflow", strPackage = "workr")
#'
#' @export
ListWorkflows <- function(
  strPath = "workflow",
  strPackage = NULL,
  bRecursive = TRUE
) {
  .workflow_path(strPath, strPackage) |>
    .discover_yaml_files(bRecursive)
}

#' List workflow names in a package/directory.
#'
#' @description `r lifecycle::badge("stable")`
#'
#'   Returns the bare workflow names (without the `.yaml` extension) for all
#'   workflow YAML files discovered in the given location. This is suitable for
#'   passing directly to the `strNames` argument of [MakeWorkflowList()].
#'
#'   Note: this function only inspects filenames — it does not read the workflow
#'   files. Active/inactive filtering happens inside [MakeWorkflowList()].
#'
#' @inheritParams ListWorkflows
#'
#' @return `character` A character vector of workflow names (IDs), with class
#'   `"AsIs"` so that [MakeWorkflowList()] treats them as exact matches.
#'
#' @examples
#' ListWorkflowNames(strPath = "workflow", strPackage = "workr")
#'
#' @export
ListWorkflowNames <- function(
  strPath = "workflow",
  strPackage = NULL,
  bRecursive = TRUE
) {
  I(sub(
    "\\.(yaml|yml)$",
    "",
    names(ListWorkflows(strPath, strPackage, bRecursive))
  ))
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
    pattern = "\\.(yaml|yml)$",
    full.names = TRUE,
    recursive = bRecursive
  )
  yaml_files <- yaml_files[!basename(yaml_files) %in% c("_config.yaml", "_config.yml")]
  names(yaml_files) <- basename(yaml_files)
  yaml_files
}
