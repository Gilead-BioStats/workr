#' Run a multi-phase workflow project
#'
#' @description
#' `r lifecycle::badge("stable")`
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
#' Per-phase `_config.yaml` files may define `input` and `output` maps. The
#' `input` map accepts `from_phases`, `from_results`, `include_workflows`, and
#' `extra`. The `output` map accepts `wrap_as` and `transform`. Unknown keys are
#' fatal errors. Without `_config.yaml`, phases retain the default carry-forward
#' behavior: all prior phase outputs are available to the next phase.
#'
#' `input.from_phases` is a character vector of prior phase folder names to
#' merge into `lData`; by default all prior phases are included.
#' `input.from_results` is a named map of `target_name: source_phase` that adds
#' a prior phase result under a target key. `input.include_workflows` may be
#' `true` to add the current phase workflow list as `lData$lWorkflows`, or
#' `{from_phase: <name>}` to add a prior phase workflow list. `input.extra` is a
#' static named map merged last, so it takes precedence over prior phase data.
#' String values in `extra` are passed literally.
#'
#' `output.wrap_as` wraps the phase result under one named key before downstream
#' input assembly. `output.transform` may name a function resolved from the
#' calling environment; the function receives the phase result and its return
#' value replaces that result. Transform errors fail the phase and identify the
#' transform reference.
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
  stop_if(!is.list(lData), "[ lData ] must be a list.")

  lPhaseResults <- list()
  lPhaseData <- list()
  lPhaseWorkflows <- list()
  transform_env <- parent.frame()

  for (phase in strPhases) {
    phase_path <- file.path(strPath, phase)
    phase_config <- .read_phase_config(phase_path, phase)

    lWorkflows <- MakeWorkflowList(
      strPath = phase_path,
      strPackage = NULL,
      bRecursive = bRecursive
    )
    lPhaseWorkflows[[phase]] <- lWorkflows

    if (length(lWorkflows) == 0) {
      LogMessage(level = "warn", message = "Phase '{phase}' has no workflows. Skipping.")
      next
    }

    phase_data <- .assemble_phase_data(
      lInitialData = lData,
      lPhaseData = lPhaseData,
      lPhaseResults = lPhaseResults,
      lPhaseWorkflows = lPhaseWorkflows,
      lCurrentWorkflows = lWorkflows,
      lPhaseConfig = phase_config,
      strPhase = phase
    )

    LogMessage(
      level = "info",
      message = "Phase '{phase}': running {length(lWorkflows)} workflow(s)",
      cli_detail = "h2"
    )

    phase_result <- RunWorkflows(
      lWorkflows = lWorkflows,
      lData = phase_data,
      lConfig = lConfig,
      bReturnResult = bReturnResult,
      bKeepInputData = bKeepInputData,
      strResultNames = strResultNames
    )

    phase_result <- .apply_phase_output_config(
      phase_result = phase_result,
      lOutputConfig = phase_config$output,
      strPhase = phase,
      transform_env = transform_env
    )

    lPhaseResults[[phase]] <- phase_result
    lPhaseData[[phase]] <- .phase_result_to_data(
      phase_result = phase_result,
      bReturnResult = bReturnResult,
      lOutputConfig = phase_config$output,
      strPhase = phase
    )
  }

  return(lPhaseResults)
}

.read_phase_config <- function(strPhasePath, strPhase) {
  config_path <- file.path(strPhasePath, "_config.yaml")
  alt_config_path <- file.path(strPhasePath, "_config.yml")

  stop_if(
    file.exists(config_path) && file.exists(alt_config_path),
    "Phase '{strPhase}' has both _config.yaml and _config.yml. Use only one phase config file."
  )

  if (!file.exists(config_path) && file.exists(alt_config_path)) {
    config_path <- alt_config_path
  }

  if (!file.exists(config_path)) {
    return(.normalize_phase_config(NULL, strPhase))
  }

  .normalize_phase_config(yaml::read_yaml(config_path), strPhase)
}

.normalize_phase_config <- function(lConfig, strPhase) {
  if (is.null(lConfig)) {
    lConfig <- list()
  }

  .validate_named_config_list(lConfig, strPhase, "top-level")
  .reject_unknown_config_keys(lConfig, c("input", "output"), strPhase, "top-level")

  input <- lConfig$input %||% list()
  output <- lConfig$output %||% list()

  .validate_named_config_list(input, strPhase, "input")
  .validate_named_config_list(output, strPhase, "output")
  .reject_unknown_config_keys(
    input,
    c("from_phases", "from_results", "include_workflows", "extra"),
    strPhase,
    "input"
  )
  .reject_unknown_config_keys(output, c("wrap_as", "transform"), strPhase, "output")

  list(
    input = list(
      from_phases = .normalize_phase_vector(input$from_phases, strPhase, "input.from_phases", allow_null = TRUE),
      from_results = .normalize_phase_mapping(input$from_results, strPhase, "input.from_results"),
      include_workflows = .normalize_include_workflows(input$include_workflows, strPhase),
      extra = .normalize_extra_inputs(input$extra, strPhase)
    ),
    output = list(
      wrap_as = .normalize_single_string(output$wrap_as, strPhase, "output.wrap_as", allow_null = TRUE),
      transform = .normalize_single_string(output$transform, strPhase, "output.transform", allow_null = TRUE)
    )
  )
}

.validate_named_config_list <- function(value, strPhase, strSection) {
  unnamed <- length(value) > 0 && (is.null(names(value)) || any(!nzchar(names(value))))
  stop_if(
    !is.list(value) || is.data.frame(value) || unnamed,
    "Phase '{strPhase}' _config.yaml {strSection} must be a map."
  )
  invisible(TRUE)
}

.reject_unknown_config_keys <- function(value, valid_keys, strPhase, strSection) {
  unknown_keys <- setdiff(names(value), valid_keys)
  stop_if(
    length(unknown_keys) > 0,
    "Phase '{strPhase}' _config.yaml contains unknown {strSection} key(s): {paste(unknown_keys, collapse = ', ')}"
  )
  invisible(TRUE)
}

.normalize_phase_vector <- function(value, strPhase, strField, allow_null = FALSE) {
  if (is.null(value)) {
    if (allow_null) {
      return(NULL)
    }
    .phase_config_stop(strPhase, "{strField} must be a character vector.")
  }

  if (is.list(value) && !is.data.frame(value)) {
    if (length(value) == 0) {
      return(character())
    }
    value <- unlist(value, recursive = FALSE, use.names = FALSE)
  }

  if (!is.character(value)) {
    .phase_config_stop(strPhase, "{strField} must be a character vector.")
  }

  as.character(value)
}

.normalize_phase_mapping <- function(value, strPhase, strField) {
  if (is.null(value)) {
    return(list())
  }

  if (is.list(value) && length(value) == 0) {
    return(list())
  }

  if (!is.list(value) || is.data.frame(value) || is.null(names(value)) || any(!nzchar(names(value)))) {
    .phase_config_stop(strPhase, "{strField} must be a named map of target_name: source_phase.")
  }

  values <- unlist(value, recursive = FALSE, use.names = FALSE)
  if (!is.character(values) || length(values) != length(value)) {
    .phase_config_stop(strPhase, "{strField} values must be phase folder names.")
  }

  stats::setNames(as.list(as.character(values)), names(value))
}

.normalize_include_workflows <- function(value, strPhase) {
  if (is.null(value) || isFALSE(value)) {
    return(FALSE)
  }

  if (isTRUE(value)) {
    return(TRUE)
  }

  if (
    is.list(value) &&
      !is.data.frame(value) &&
      identical(names(value), "from_phase") &&
      is.character(value$from_phase) &&
      length(value$from_phase) == 1
  ) {
    return(list(from_phase = value$from_phase))
  }

  .phase_config_stop(strPhase, "input.include_workflows must be true, false, or a map with from_phase.")
}

.normalize_extra_inputs <- function(value, strPhase) {
  if (is.null(value)) {
    return(list())
  }

  if (is.list(value) && length(value) == 0) {
    return(list())
  }

  if (!is.list(value) || is.data.frame(value) || is.null(names(value)) || any(!nzchar(names(value)))) {
    .phase_config_stop(strPhase, "input.extra must be a named map.")
  }

  value
}

.normalize_single_string <- function(value, strPhase, strField, allow_null = FALSE) {
  if (is.null(value)) {
    if (allow_null) {
      return(NULL)
    }
    .phase_config_stop(strPhase, "{strField} must be a single string.")
  }

  if (!is.character(value) || length(value) != 1 || is.na(value)) {
    .phase_config_stop(strPhase, "{strField} must be a single string or null.")
  }

  value
}

.phase_config_stop <- function(strPhase, strMessage) {
  detail <- glue::glue(strMessage, .envir = parent.frame())
  stop(glue::glue("Phase '{strPhase}' _config.yaml {detail}"), call. = FALSE)
}

.assemble_phase_data <- function(
  lInitialData,
  lPhaseData,
  lPhaseResults,
  lPhaseWorkflows,
  lCurrentWorkflows,
  lPhaseConfig,
  strPhase
) {
  input <- lPhaseConfig$input
  source_phases <- input$from_phases %||% names(lPhaseData)
  lData <- lInitialData

  for (source_phase in source_phases) {
    .require_prior_phase(source_phase, lPhaseData, strPhase, "input.from_phases")
    lData <- .merge_named_lists(lData, lPhaseData[[source_phase]])
  }

  for (target_name in names(input$from_results)) {
    source_phase <- input$from_results[[target_name]]
    .require_prior_phase(source_phase, lPhaseResults, strPhase, "input.from_results")
    lData[[target_name]] <- lPhaseResults[[source_phase]]
  }

  if (isTRUE(input$include_workflows)) {
    lData$lWorkflows <- lCurrentWorkflows
  } else if (is.list(input$include_workflows)) {
    source_phase <- input$include_workflows$from_phase
    if (identical(source_phase, strPhase)) {
      lData$lWorkflows <- lCurrentWorkflows
    } else {
      .require_prior_phase(source_phase, lPhaseWorkflows, strPhase, "input.include_workflows.from_phase")
      lData$lWorkflows <- lPhaseWorkflows[[source_phase]]
    }
  }

  .merge_named_lists(lData, input$extra)
}

.require_prior_phase <- function(source_phase, lPrior, strPhase, strField) {
  stop_if(
    !source_phase %in% names(lPrior),
    "Phase '{strPhase}' _config.yaml {strField} references unavailable phase '{source_phase}'."
  )
  invisible(TRUE)
}

.merge_named_lists <- function(lTarget, lSource) {
  for (nm in names(lSource)) {
    lTarget[[nm]] <- lSource[[nm]]
  }
  lTarget
}

.apply_phase_output_config <- function(phase_result, lOutputConfig, strPhase, transform_env) {
  if (!is.null(lOutputConfig$transform)) {
    transform_ref <- lOutputConfig$transform
    transform_fn <- .resolve_phase_transform(transform_ref, transform_env)
    phase_result <- tryCatch(
      transform_fn(phase_result),
      error = function(err) {
        stop(
          glue::glue(
            "Phase '{strPhase}' output.transform '{transform_ref}' failed: {conditionMessage(err)}"
          ),
          call. = FALSE
        )
      }
    )
  }

  if (!is.null(lOutputConfig$wrap_as)) {
    phase_result <- stats::setNames(list(phase_result), lOutputConfig$wrap_as)
  }

  phase_result
}

.resolve_phase_transform <- function(transform_ref, transform_env) {
  if (grepl("::", transform_ref, fixed = TRUE)) {
    parts <- strsplit(transform_ref, "::", fixed = TRUE)[[1]]
    stop_if(length(parts) != 2, "output.transform '{transform_ref}' is not a valid namespaced function reference.")
    return(getExportedValue(parts[[1]], parts[[2]]))
  }

  if (exists(transform_ref, envir = transform_env, mode = "function", inherits = TRUE)) {
    return(get(transform_ref, envir = transform_env, mode = "function", inherits = TRUE))
  }

  stop("output.transform '", transform_ref, "' could not be resolved as a function.", call. = FALSE)
}

.phase_result_to_data <- function(phase_result, bReturnResult, lOutputConfig, strPhase) {
  output_was_shaped <- !is.null(lOutputConfig$wrap_as) || !is.null(lOutputConfig$transform)
  if (output_was_shaped || bReturnResult) {
    return(.validate_phase_data_result(phase_result, strPhase))
  }

  lData <- list()
  for (result_item in phase_result) {
    if (is.list(result_item) && !is.null(result_item$lData)) {
      lData <- .merge_named_lists(lData, result_item$lData)
    }
  }
  lData
}

.validate_phase_data_result <- function(phase_result, strPhase) {
  stop_if(
    !is.list(phase_result) || is.data.frame(phase_result) || is.null(names(phase_result)) || any(!nzchar(names(phase_result))),
    "Phase '{strPhase}' output must be a named list to be used by downstream phases."
  )

  phase_result
}
