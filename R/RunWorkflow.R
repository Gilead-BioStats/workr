#' Run a workflow via its specification.
#'
#' @description
#' Attempts to run a single assessment (`lWorkflow`) using shared data (`lData`)
#' and metadata (`lMapping`). Calls `RunStep` for each item in
#' `lWorkflow$steps` and saves the results to `lWorkflow`.
#'
#' @param lWorkflow `list` A named list of metadata defining how the workflow
#'   should be run.
#' @param lData `list` A named list of domain-level data frames.
#' @param lConfig `list` A configuration object with two methods:
#' - `LoadData`: A function that loads data specified in `lWorkflow$spec`.
#' - `SaveData`: A function that saves data returned by the last step in `lWorkflow$steps`.
#' @param bKeepInputData `boolean` should the input data be included in `lData`
#'   after the workflow is run? Only relevant when bReturnResult is FALSE.
#'   Default is `TRUE`.
#' @param bReturnResult `boolean` should *only* the result from the last step
#'   (`lResults`) be returned? If false, the full workflow (including
#'   `lResults`) is returned. Default is `TRUE`.
#'
#' @return Object containing the results of the workflow's last step (if
#'   `bReturnResult` is `TRUE`) or the full workflow object (if `bReturnResult`
#'   is `FALSE`).
#'
#' @examples
#' sum_step <- function(x, y) x + y
#' lWorkflow <- list(
#'   meta = list(Type = "demo", ID = "001"),
#'   steps = list(
#'     list(name = "sum_step", output = "result", params = list(x = "lData", y = "value"))
#'   )
#' )
#' lData <- list(value = 2)
#' RunWorkflow(lWorkflow, lData)
#'
#' @export

RunWorkflow <- function(
  lWorkflow,
  lData = NULL,
  lConfig = NULL,
  bReturnResult = TRUE,
  bKeepInputData = TRUE
) {
  uid <- paste0(lWorkflow$meta$Type, "_", lWorkflow$meta$ID)
  LogMessage(level = "info", message = "Initializing `{uid}` Workflow", cli_detail = "h1")

  if (length(lWorkflow$steps) == 0) {
    LogMessage(level = "info", message = "Workflow `{uid}` has no `steps` property.", cli_detail = "alert")
  }

  if (!"meta" %in% names(lWorkflow)) {
    LogMessage(level = "info", message = "Workflow `{uid}` has no `meta` property.", cli_detail = "alert")
  }

  if (!is.null(lConfig)) {
    if (
      exists("LoadData", lConfig) &&
        is.function(lConfig$LoadData) &&
        all(c("lWorkflow", "lConfig", "lData") %in% names(formals(lConfig$LoadData)))
    ) {
      LogMessage(level = "info", message = "Loading data with `lConfig$LoadData`.", cli_detail = "h3")

      lData <- lConfig$LoadData(
        lWorkflow = lWorkflow,
        lConfig = lConfig,
        lData = lData
      )
    } else {
      LogMessage(
        level = "error",
        message = "`lConfig` must include a function named `LoadData` with three named parameters: `lWorkflow`, `lConfig`, and `lData`."
      )
    }
  }

  lWorkflow$lData <- lData

  if ("spec" %in% names(lWorkflow)) {
    LogMessage(level = "info", message = "Checking data against spec", cli_detail = "h3")
    CheckSpec(lData, lWorkflow$spec)
  } else {
    lWorkflow$spec <- NULL
    LogMessage(level = "info", message = "No spec found in workflow. Proceeding without checking data.", cli_detail = "h3")
  }

  stepCount <- 1
  for (step in lWorkflow$steps) {
    LogMessage(
      level = "info",
      message = paste0("Workflow Step ", stepCount, " of ", length(lWorkflow$steps), ": `", step$name, "`"),
      cli_detail = "h2"
    )
    result <- RunStep(
      lStep = step,
      lData = lWorkflow$lData,
      lMeta = lWorkflow$meta,
      lSpec = lWorkflow$spec
    )

    if (step$output %in% names(lData)) {
      LogMessage(level = "warn", message = "Overwriting existing data in `lData`.")
    }

    lWorkflow$lData[[step$output]] <- result
    lWorkflow$lResult <- result

    if (is.data.frame(result)) {
      LogMessage(
        level = "info",
        message = "{paste(dim(result),collapse='x')} data.frame saved as `lData${step$output}`.",
        cli_detail = "h3"
      )
    } else {
      LogMessage(
        level = "info",
        message = "{typeof(result)} of length {length(result)} saved as `lData${step$output}`.",
        cli_detail = "h3"
      )
    }

    stepCount <- stepCount + 1
  }

  if (bReturnResult) {
    if (is.data.frame(lWorkflow$lResult)) {
      LogMessage(
        level = "info",
        message = "Returning results from final step: {paste(dim(lWorkflow$lResult),collapse='x')} data.frame`.",
        cli_detail = "h2"
      )
    } else {
      LogMessage(
        level = "info",
        message = "Returning results from final step: {typeof(lWorkflow$lResult)} of length {length(lWorkflow$lResult)}`.",
        cli_detail = "h2"
      )
    }

    if (!is.null(lConfig)) {
      if (
        exists("SaveData", lConfig) &&
          is.function(lConfig$SaveData) &&
          all(c("lWorkflow", "lConfig") %in% names(formals(lConfig$SaveData)))
      ) {
        LogMessage(
          level = "info",
          message = "Saving data with `lConfig$SaveData`.",
          cli_detail = "h3"
        )

        lConfig$SaveData(
          lWorkflow = lWorkflow,
          lConfig = lConfig
        )
      } else {
        LogMessage(
          level = "error",
          message = "`lConfig` must include a function named `SaveData` with two named parameters: `lWorkflow` and `lConfig`."
        )
      }
    }

    LogMessage(level = "info", message = "Completed `{uid}` Workflow", cli_detail = "h1")

    return(lWorkflow$lResult)
  }

  if (!bKeepInputData) {
    outputs <- purrr::map_chr(lWorkflow$steps, ~ .x$output)
    lWorkflow$lData <- lWorkflow$lData[outputs]
    LogMessage(
      level = "info",
      message = "Keeping only workflow outputs in $lData: {names(lWorkflow$lData)}",
      cli_detail = "alert_info"
    )
  } else {
    LogMessage(
      level = "info",
      message = "Keeping workflow inputs and outputs in $lData: {names(lWorkflow$lData)}",
      cli_detail = "alert_info"
    )
  }
  LogMessage(
    level = "info",
    message = "Returning full workflow object.",
    cli_detail = "h2"
  )
  LogMessage(level = "info", message = "Completed `{uid}` Workflow", cli_detail = "h1")
  return(lWorkflow)
}
