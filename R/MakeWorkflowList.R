#' Load workflows from a package/directory.
#'
#' @description `r lifecycle::badge("stable")`
#'
#'   Create a list of workflows for use in pipelines.
#'
#' @param strNames `array of character` Workflow names to include. Defaults to
#'   all workflow names found at `strPath`/`strPackage`. Pass an `I()`-wrapped
#'   vector for exact matching (as returned by [ListWorkflowNames()]).
#' @param strPackage `character` The package name where the workflow YAML files
#'   are located. If `NULL`, the package will use an absolute path.
#' @param strPath `character` The location of workflow YAML files, relative to
#'   either the working directory or the `strPackage` installation directory.
#' @param bExact `logical` Should `strNames` matches be exact? Defaults to
#'   `TRUE` when `strNames` has class `"AsIs"` (as returned by
#'   [ListWorkflowNames()]), `FALSE` otherwise.
#' @param bRecursive `logical` Find files in nested folders? Default `TRUE`.
#' @param bActiveOnly `logical` Should workflows with `meta$Active: false`
#'   be excluded? Default `TRUE`. Set to `FALSE` to load all workflows
#'   regardless of their `Active` setting.
#'
#' @examples
#' # Load all active workflows from a package
#' workflow <- MakeWorkflowList(
#'   strPath = "example_workflows",
#'   strPackage = "workr"
#' )
#'
#' # Load a specific workflow by name
#' workflow <- MakeWorkflowList(
#'   strNames = "cars",
#'   strPath = "example_workflows",
#'   strPackage = "workr"
#' )
#'
#' @return `list` A list of workflows with workflow and parameter metadata.
#'
#' @export
MakeWorkflowList <- function(
  strNames = ListWorkflowNames(
    strPath = strPath,
    strPackage = strPackage,
    bRecursive = bRecursive
  ),
  strPath = "example_workflows",
  strPackage = NULL,
  bExact = inherits(strNames, "AsIs"),
  bRecursive = TRUE,
  bActiveOnly = TRUE
) {
  ListWorkflows(strPath, strPackage, bRecursive) |>
    .filter_yaml_files(strNames, bExact) |>
    .load_workflows() |>
    .filter_active_workflows(bActiveOnly) |>
    .validate_workflows() |>
    .sort_workflows() |>
    .warn_if_empty("No workflows found.")
}

#' Subset a yaml_files vector to those matching strNames
#'
#' @keywords internal
#' @noRd
.filter_yaml_files <- function(yaml_files, strNames, bExact) {
  if (!length(strNames)) {
    return(yaml_files)
  }
  fuzzy_match <- !bExact & .yaml_files_match(yaml_files, strNames)
  yaml_files[fuzzy_match | .is_named_yaml_file(yaml_files, strNames)]
}

#' Check whether each yaml_files entry has a name matching strNames exactly
#' (with or without .yaml/.yml extension)
#'
#' @keywords internal
#' @noRd
.is_named_yaml_file <- function(yaml_files, strNames) {
  names(yaml_files) %in%
    c(
      strNames,
      paste0(strNames, ".yaml"),
      paste0(strNames, ".yml")
    )
}

#' Check whether each yaml_files entry has a name matching any strNames pattern
#'
#' @keywords internal
#' @noRd
.yaml_files_match <- function(yaml_files, strNames) {
  grepl(
    paste(gsub("\\.", "\\\\.", strNames), collapse = "|"),
    names(yaml_files)
  )
}

#' Load raw workflow objects from a named vector of YAML paths
#'
#' @keywords internal
#' @noRd
.load_workflows <- function(yaml_files) {
  purrr::map2(yaml_files, names(yaml_files), function(yaml_file, file_name) {
    # Note: YAML may contain !expr tags which are kept as-is (not evaluated
    # here). They will be evaluated later when needed (e.g., during RunStep
    # execution). Suppress parser warnings for !expr tags and minor
    # file-format issues because workflow expressions are intentionally
    # handled at execution time.
    workflow <- suppressWarnings(yaml::read_yaml(yaml_file))
    workflow$path <- yaml_file
    workflow
  })
}

#' Filter a workflow list to those that are not explicitly inactive
#'
#' A workflow is considered active when `meta$Active` is absent or `TRUE`.
#' Only `isFALSE(meta$Active)` causes a workflow to be dropped.
#'
#' @keywords internal
#' @noRd
.filter_active_workflows <- function(workflows, bActiveOnly) {
  if (!bActiveOnly) {
    return(workflows)
  }
  purrr::keep(workflows, \(wf) {
    !isFALSE(wf$meta$Active)
  })
}

#' Validate required fields in a list of loaded workflows
#'
#' @keywords internal
#' @noRd
.validate_workflows <- function(workflows) {
  validated <- purrr::map2(
    workflows,
    names(workflows),
    function(workflow, file_name) {
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
      if (gsub(".yaml", "", file_name) != workflow$meta$ID) {
        LogMessage(
          level = "warn",
          message = "`ID` attribute does not match name of the file, {file_name}."
        )
      }
      workflow
    }
  )

  stats::setNames(
    validated,
    purrr::map_chr(validated, list("meta", "ID"))
  )
}

#' Sort a workflow list by meta$Priority (ascending), defaulting missing to 0
#'
#' @keywords internal
#' @noRd
.sort_workflows <- function(workflows) {
  workflows <- purrr::map(workflows, function(wf) {
    if (is.null(wf$meta$Priority)) {
      wf$meta$Priority <- 0
    }
    wf
  })
  workflows[order(purrr::map_dbl(workflows, ~ .x$meta$Priority))]
}

#' Warn if a list or vector is empty, then return it invisibly
#'
#' @keywords internal
#' @noRd
.warn_if_empty <- function(x, msg) {
  if (!length(x)) {
    LogMessage(level = "warn", message = msg)
  }
  x
}
