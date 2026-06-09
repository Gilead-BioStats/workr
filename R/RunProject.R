#' Run a multi-phase workflow project
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `RunProject()` runs multiple workflow phase folders in sequence, sharing one
#' `lData` object across phases. Each subdirectory of `strPath` is treated as a
#' phase. Phases are executed in sorted order (or in the order specified by
#' `strPhases`). Within each phase, workflows are loaded via
#' `MakeWorkflowList()` and run via `RunWorkflows()`.
#'
#' @details
#' Phase-discovery and ordering contract:
#'
#' * `strPath` must exist and be a directory; otherwise execution stops.
#' * By default phases are the immediate subdirectories of `strPath`, executed
#'   in alphabetical order.
#' * When `strPhases` is supplied, phases run in the exact order given (caller
#'   order is preserved, not re-sorted).
#' * A `strPhases` entry that does not exist on disk is a fatal error.
#' * A phase folder that contains no workflow YAMLs emits a warning and is
#'   skipped; execution proceeds with the remaining phases.
#'
#' @param strPath `character` Path to the project directory. Must contain one or
#'   more subdirectories, each holding workflow YAML files.
#' @param lData `list` Initial named list of data objects. Default `NULL`.
#' @param lConfig `list` Configuration hooks passed to `RunWorkflows()`.
#'   Default `NULL`.
#' @param strPhases `character` Optional vector of phase folder names to run. If
#'   `NULL` (the default), all sorted subdirectories of `strPath` are used.
#' @param bRecursive `logical` Passed to `MakeWorkflowList()`. Default `FALSE`.
#' @param bReturnResult `logical` Passed to `RunWorkflows()`. Default `TRUE`.
#' @param bKeepInputData `logical` Passed to `RunWorkflows()`. Default `FALSE`.
#' @param strResultNames `character` Vector of length two passed to
#'   `RunWorkflows()`. Default `c("Type", "ID")`.
#'
#' @return A named list with one element per phase. Each element contains the
#'   result returned by `RunWorkflows()` for that phase.
#'
#' @examples
#' \dontrun{
#' results <- RunProject("inst/workflow")
#' }
#'
#' @export

RunProject <- function(
  strPath,
  lData = NULL,
  lConfig = NULL,
  strPhases = NULL,
  bRecursive = FALSE,
  bReturnResult = TRUE,
  bKeepInputData = FALSE,
  strResultNames = c("Type", "ID")
) {
  stop_if(!is.character(strPath) || length(strPath) != 1, "[ strPath ] must be a single character string.")
  stop_if(!file.exists(strPath), "[ strPath ] path does not exist: {strPath}")
  stop_if(!dir.exists(strPath), "[ strPath ] path is not a directory: {strPath}")

  # Discover phase folders
  all_dirs <- list.dirs(strPath, full.names = FALSE, recursive = FALSE)
  all_dirs <- sort(all_dirs)

  if (is.null(strPhases)) {
    strPhases <- all_dirs
  } else {
    missing <- setdiff(strPhases, all_dirs)
    stop_if(
      length(missing) > 0,
      "[ strPhases ] requested phases not found: {paste(missing, collapse = ', ')}"
    )
  }

  stop_if(length(strPhases) == 0, "No phase folders found in {strPath}.")

  LogMessage(
    level = "info",
    message = "Running project with {length(strPhases)} phase(s): {paste(strPhases, collapse = ', ')}",
    cli_detail = "h1"
  )

  if (is.null(lData)) lData <- list()

  lPhaseResults <- list()
  current_data <- lData

  for (phase in strPhases) {
    phase_path <- file.path(strPath, phase)

    lWorkflows <- MakeWorkflowList(
      strPath = phase_path,
      strPackage = NULL,
      bRecursive = bRecursive
    )

    if (length(lWorkflows) == 0) {
      LogMessage(level = "warn", message = "Phase '{phase}' has no workflows. Skipping.")
      next
    }

    LogMessage(
      level = "info",
      message = "Phase '{phase}': running {length(lWorkflows)} workflow(s)",
      cli_detail = "h2"
    )

    phase_result <- RunWorkflows(
      lWorkflows = lWorkflows,
      lData = current_data,
      lConfig = lConfig,
      bReturnResult = bReturnResult,
      bKeepInputData = bKeepInputData,
      strResultNames = strResultNames
    )

    lPhaseResults[[phase]] <- phase_result

    # Carry forward data: merge workflow outputs into current_data
    if (!bReturnResult) {
      # When bReturnResult is FALSE, each result is a full workflow object with $lData
      # Merge outputs into current_data so downstream phases retain earlier data
      for (res in phase_result) {
        if (is.list(res) && !is.null(res$lData)) {
          for (nm in names(res$lData)) {
            current_data[[nm]] <- res$lData[[nm]]
          }
        }
      }
    } else {
      # When bReturnResult is TRUE, results are the final step outputs
      # Add them to current_data so downstream phases can access them
      for (nm in names(phase_result)) {
        current_data[[nm]] <- phase_result[[nm]]
      }
    }
  }

  return(lPhaseResults)
}
