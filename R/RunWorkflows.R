#' Convenience function to run multiple workflows
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' This function takes a list of workflows and a list of data as input. It runs each workflow and returns the
#' results as a named list where the names of the list correspond to the workflow ID (`meta$ID`).
#'
#' Workflows are run in the order they are provided in `lWorkflows`. The results from each workflow are passed
#' as inputs (along with `lData`) for later workflows.
#'
#' @param lWorkflows `list` A named list of metadata defining how the workflow should be run.
#' @param lData `list` A named list of domain-level data frames.
#' @param lConfig `list` Optional configuration object passed through to
#'   `RunWorkflow()`. Supported hook fields:
#' - `LoadData`: Optional function or registered provider name used before
#'   spec validation. Functions must accept `lWorkflow`, `lConfig`, and
#'   `lData` as named formals. `{workr}` includes a built-in `"gsm.datasim"`
#'   provider that reads adapter settings from `lConfig$gsm.datasim`.
#' - `SaveData`: Optional function or registered provider name used before
#'   returning results when `bReturnResult = TRUE`. Functions must accept
#'   `lWorkflow` and `lConfig` as named formals.
#' @param bReturnResult `boolean` should *only* the result from the last step (`lResults`) be returned? If false,
#' the full workflow (including `lResults`) is returned. Default is `TRUE`.
#' @param bKeepInputData `boolean` should the input data be included in `lData` after the workflow is run? Only
#' relevant when bReturnResult is FALSE. Default is `TRUE`.
#' @param strResultNames `string` vector of length two, which describes the meta fields used to name the output.
#' @param bContinueOnError `logical` If `TRUE`, failed workflows are recorded
#'   and later workflows still run. Default `FALSE` retains the existing
#'   fail-fast behavior.
#'
#' @return A named list of results from `RunWorkflow()`, where the names
#' correspond to the workflow ID. When `bContinueOnError = TRUE`, returns a
#' summary with `results`, `status`, and `failures`.
#'
#' @examples
#' sum_step <- function(x, y) {x + y}
#' lWorkflows <- list(
#'   list(
#'     meta = list(Type = "demo", ID = "001"),
#'     steps = list(
#'       list(name = "sum_step", output = "result", params = list(x = "value1", y = "value2"))
#'     )
#'   )
#' )
#' lData <- list(value1 = 1, value2 = 2)
#' RunWorkflows(lWorkflows, lData)
#'
#' @export

RunWorkflows <- function(
  lWorkflows,
  lData = NULL,
  lConfig = NULL,
  bKeepInputData = FALSE,
  bReturnResult = TRUE,
  strResultNames = c("Type", "ID"),
  bContinueOnError = FALSE
) {
  stop_if(
    !is.logical(bContinueOnError) ||
      length(bContinueOnError) != 1 ||
      is.na(bContinueOnError),
    "[ bContinueOnError ] must be TRUE or FALSE."
  )

  LogMessage(
    level = "info",
    message = "Running {length(lWorkflows)} Workflows",
    cli_detail = "h1"
  )

  lResults <- list()
  status <- .workflow_status_frame()
  for (workflow in lWorkflows) {
    resultName <- .workflow_result_name(workflow, strResultNames)

    run_workflow <- function() {
      RunWorkflow(
        lWorkflow = workflow,
        lData = c(lResults, lData),
        lConfig = lConfig,
        bReturnResult = bReturnResult,
        bKeepInputData = bKeepInputData
      )
    }

    if (isTRUE(bContinueOnError)) {
      lResult <- tryCatch(run_workflow(), error = function(err) err)
      if (inherits(lResult, "error")) {
        err_message <- conditionMessage(lResult)
        LogMessage(
          level = "error",
          message = "Workflow '{resultName}' failed: {err_message}"
        )
        status <- .append_workflow_status(
          status,
          resultName,
          "error",
          err_message
        )
        next
      }

      status <- .append_workflow_status(status, resultName, "success")
    } else {
      lResult <- run_workflow()
    }

    lResults[[resultName]] <- lResult
  }

  if (isTRUE(bContinueOnError)) {
    return(.workflow_run_summary(lResults, status))
  }

  return(lResults)
}

.workflow_result_name <- function(workflow, strResultNames) {
  resultName <- vapply(
    strResultNames,
    function(name) {
      value <- workflow$meta[[name]]
      stop_if(
        is.null(value) || length(value) != 1,
        "[ strResultNames ] field '{name}' is missing or not scalar in workflow meta."
      )
      as.character(value)
    },
    character(1)
  )

  paste0(resultName, collapse = "_")
}

.workflow_status_frame <- function() {
  data.frame(
    workflow = character(),
    status = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

.append_workflow_status <- function(
  status,
  workflow,
  state,
  message = NA_character_
) {
  rbind(
    status,
    data.frame(
      workflow = workflow,
      status = state,
      message = message,
      stringsAsFactors = FALSE
    )
  )
}

.workflow_run_summary <- function(results, status) {
  failures <- status[status$status == "error", , drop = FALSE]
  structure(
    list(
      results = results,
      status = status,
      failures = failures
    ),
    class = c("workr_run_summary", "list")
  )
}

.is_workr_run_summary <- function(value) {
  inherits(value, "workr_run_summary") &&
    is.list(value) &&
    all(c("results", "status", "failures") %in% names(value))
}

.workflow_summary_results <- function(value) {
  if (.is_workr_run_summary(value)) {
    return(value$results)
  }

  value
}
