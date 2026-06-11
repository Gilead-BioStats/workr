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
#'   `lData` as named formals. {workr} includes a built-in `"gsm.datasim"`
#'   provider that reads adapter settings from `lConfig$gsm.datasim`.
#' - `SaveData`: Optional function or registered provider name used before
#'   returning results when `bReturnResult = TRUE`. Functions must accept
#'   `lWorkflow` and `lConfig` as named formals.
#' @param bReturnResult `boolean` should *only* the result from the last step (`lResults`) be returned? If false,
#' the full workflow (including `lResults`) is returned. Default is `TRUE`.
#' @param bKeepInputData `boolean` should the input data be included in `lData` after the workflow is run? Only
#' relevant when bReturnResult is FALSE. Default is `TRUE`.
#' @param strResultNames `string` vector of length two, which describes the meta fields used to name the output.
#'
#' @return A named list of results from `RunWorkflow()`, where the names correspond to the names of
#' the workflow ID
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
  strResultNames = c("Type", "ID")
) {
  LogMessage(
    level = "info",
    message = "Running {length(lWorkflows)} Workflows",
    cli_detail = "h1"
  )

  lResults <- list()
  for (wf in lWorkflows) {
    lResult <- RunWorkflow(
      lWorkflow = wf,
      lData = c(lResults, lData),
      lConfig = lConfig,
      bReturnResult = bReturnResult,
      bKeepInputData = bKeepInputData
    )

    resultName <- purrr::map(strResultNames, function(name) wf$meta[[name]])
    resultName <- paste0(resultName, collapse = "_")

    lResults[[resultName]] <- lResult
  }

  return(lResults)
}
