#' Load example data for workflow execution
#'
#' @description
#' `loadExample()` is a convenience `LoadData` hook for `RunWorkflow()` and
#' `RunWorkflows()`. If an `initData.R` file exists in the same folder as the
#' workflow YAML, it sources that script and calls `initData()` to get starter
#' `lData`.
#'
#' The return value is merged with incoming `lData` so caller-provided values
#' override defaults from `initData()`.
#'
#' @param lWorkflow `list` Workflow object. Must include `path` (set by
#'   `MakeWorkflowList()`) to locate `initData.R`.
#' @param lConfig `list` Unused. Included to match the `LoadData` hook
#'   interface expected by `RunWorkflow()`.
#' @param lData `list` Existing input data.
#'
#' @return `list` Data to use as workflow input.
#' @export
loadExample <- function(lWorkflow, lConfig = NULL, lData = NULL) {
  if (is.null(lData)) {
    lData <- list()
  }

  stop_if(!is.list(lData), "[ lData ] must be a list.")
  stop_if(is.null(lWorkflow$path), "[ lWorkflow$path ] is required for loadExample().")

  initPath <- file.path(dirname(lWorkflow$path), "initData.R")
  if (!file.exists(initPath)) {
    return(lData)
  }

  initEnv <- new.env(parent = baseenv())
  sys.source(initPath, envir = initEnv)

  stop_if(!exists("initData", envir = initEnv, mode = "function"),
    "[ initData.R ] must define an initData() function."
  )

  initData <- get("initData", envir = initEnv, mode = "function")
  initList <- initData()
  stop_if(!is.list(initList), "initData() must return a list.")

  initSummary <- vapply(names(initList), function(nm) {
    obj <- initList[[nm]]
    if (is.data.frame(obj)) {
      paste0(nm, "=data.frame[", nrow(obj), "x", ncol(obj), "]")
    } else {
      paste0(nm, "=", class(obj)[1], "[", length(obj), "]")
    }
  }, character(1))

  LogMessage(
    level = "info",
    message = "initData() created {length(initList)} object(s): {paste(initSummary, collapse = ', ')}",
    cli_detail = "h3"
  )

  c(lData, initList)
}
