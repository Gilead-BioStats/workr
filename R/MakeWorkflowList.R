#' Load workflows from a package/directory.
#'
#' @description `r lifecycle::badge("stable")`
#'
#'   Create a list of workflows for use in pipelines.
#'
#' @param strNames `array of character` List of workflows to include. Defaults
#'   to the result of [GetActiveWorkflows()], which excludes any workflow with
#'   `meta$MetricActive: false`. Pass `NULL` explicitly to include all workflows
#'   regardless of their `MetricActive` setting.
#' @param strPackage `character` The package name where the workflow YAML files
#'   are located. If `NULL`, the package will use an absolute path.
#' @param strPath `character` The location of workflow YAML files, relative to
#'   either the working directory or the `strPackage` installation directory.
#' @param bExact `logical` Should `strNames` matches be exact? Defaults to
#'   `TRUE` when `strNames` has class `"AsIs"` (as it does if it comes from
#'   [GetActiveWorkflows()]), `FALSE` otherwise.
#' @param bRecursive `logical` Find files in nested folders? Default `TRUE`.
#'
#' @examples
#' # get specific workflow files
#' workflow <- MakeWorkflowList(
#'   strName = "cars",
#'   strPath = "workflow",
#'   strPackage = "workr"
#' )
#'
#' @return `list` A list of workflows with workflow and parameter metadata.
#'
#' @export
MakeWorkflowList <- function(
  strNames = GetActiveWorkflows(
    strPath = strPath,
    strPackage = strPackage,
    bRecursive = bRecursive
  ),
  strPath = "workflow",
  strPackage = NULL,
  bExact = inherits(strNames, "AsIs"),
  bRecursive = TRUE
) {
  path <- .workflow_path(strPath, strPackage)

  # list all files to loop through to build the workflow list.
  yaml_files <- .discover_yaml_files(path, bRecursive)
  yaml_files <- .filter_yaml_files(yaml_files, strNames, bExact)

  workflows <- purrr::map2(
    yaml_files,
    names(yaml_files),
    function(yaml_file, file_name) {
      # read the individual YAML file
      # Note: YAML may contain !expr tags which are kept as-is (not evaluated here)
      # They will be evaluated later when needed (e.g., during RunStep execution)
      # Suppress parser warnings for !expr tags and minor file-format issues
      # because workflow expressions are intentionally handled at execution time.
      workflow <- suppressWarnings(yaml::read_yaml(yaml_file))

      # set the `path` for logging purposes
      workflow$path <- yaml_file

      # each workflow should have an $meta and $steps $meta$ID attributes
      if (!rlang::has_name(workflow, "meta")) {
        LogMessage(
          level = "fatal",
          message = "{file_name} must contain `meta` attributes."
        )
      }
      if (!rlang::has_name(workflow, "steps")) {
        LogMessage(
          level = "fatal",
          message = "{file_name} must contain `steps` attributes."
        )
      }
      if (!rlang::has_name(workflow$meta, "Type")) {
        LogMessage(
          level = "fatal",
          message = "{file_name} must contain `Type` attribute in `meta` section."
        )
      }
      if (!rlang::has_name(workflow$meta, "ID")) {
        LogMessage(
          level = "fatal",
          message = "{file_name} must contain `ID` attribute in `meta` section."
        )
      }
      # warn user if file name doesn't match ID specified
      if (gsub(".yaml", "", file_name) != workflow$meta$ID) {
        LogMessage(
          level = "warn",
          message = "`ID` attribute does not match name of the file, {file_name}."
        )
      }

      return(workflow)
    }
  )
  workflows <- stats::setNames(
    workflows,
    purrr::map_chr(workflows, list("meta", "ID"))
  )

  # Sort the list according to the $meta$priority property

  # Set priority to 0 if not defined
  workflows <- workflows %>%
    map(function(wf) {
      if (is.null(wf$meta$Priority)) {
        wf$meta$Priority <- 0
      }
      return(wf)
    })
  workflows <- workflows[order(workflows %>% map_dbl(~ .x$meta$Priority))]

  # throw a warning if no workflows are found
  if (length(workflows) == 0) {
    LogMessage(level = "warn", message = "No workflows found.")
  }

  return(workflows)
}
