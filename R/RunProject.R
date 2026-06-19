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
#' Phase folders and order:
#'
#' * `strPath` must exist and be a directory; otherwise execution stops.
#' * By default phases are the immediate subdirectories of `strPath`, executed
#'   in alphabetical order.
#' * When `strPhases` is supplied, phases run in the exact order given (caller
#'   order is preserved, not re-sorted).
#' * A `strPhases` entry that does not exist on disk stops execution.
#' * A phase folder that contains no workflow YAMLs is skipped with a workflow
#'   log message; execution proceeds with the remaining phases.
#'
#' Per-phase `_config.yaml` files may define `input` and `output` maps. Unknown
#' keys stop execution. Without `_config.yaml`, all prior phase outputs are
#' available to the next phase.
#'
#' Use `input.from_phases` or `input.from_results` to select earlier phase data,
#' `input.include_workflows` to pass workflow definitions, and `input.extra` for
#' static values. Use `output.wrap_as` to store a phase result under one name or
#' `output.transform` to apply a function before later phases use the result.
#'
#' Load/save hooks:
#'
#' * Put `LoadData` or `SaveData` at the top level of `lConfig` to use it for
#'   every phase.
#' * Put hooks under `lConfig$phases[[phase_name]]` to use them only for that
#'   phase. Phase hooks override top-level hooks with the same name.
#' * Put `LoadData` or `SaveData` under `lConfig$project` to run once before or
#'   after the whole project. Project `LoadData` must return an `lData` list;
#'   project `SaveData` receives the project result.
#'
#' @param strPath `character` Path to the project directory. Must contain one or
#'   more subdirectories, each holding workflow YAML files.
#' @param lData `list` Initial named list of data objects. Default `NULL`.
#' @param lConfig `list` Configuration hooks. Top-level hooks are passed to
#'   `RunWorkflows()` for every phase. Use `lConfig$phases` for phase-specific
#'   hooks and `lConfig$project` for hooks that run once for the whole project.
#' @param strPhases `character` Optional vector of phase folder names to run. If
#'   `NULL` (the default), all sorted subdirectories of `strPath` are used.
#' @param bRecursive `logical` Passed to `MakeWorkflowList()`. Default `FALSE`.
#' @param bReturnResult `logical` Passed to `RunWorkflows()`. Default `TRUE`.
#' @param bKeepInputData `logical` Passed to `RunWorkflows()`. Default `FALSE`.
#' @param strResultNames `character` Vector of length two passed to
#'   `RunWorkflows()`. Default `c("Type", "ID")`.
#' @param bContinueOnError `logical` Passed to `RunWorkflows()`. If `TRUE`,
#'   failed workflows are recorded and later workflows/phases still run.
#'   Default `FALSE`.
#'
#' @return A named list with one element per phase. Each element contains the
#'   result returned by `RunWorkflows()` for that phase. When
#'   `bContinueOnError = TRUE`, returns a summary with `results`, `status`, and
#'   `failures`.
#'
#' @examples
#' \dontrun{
#' results <- RunProject("inst/example_workflows")
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
  strResultNames = c("Type", "ID"),
  bContinueOnError = FALSE
) {
  stop_if(
    !is.character(strPath) || length(strPath) != 1,
    "[ strPath ] must be a single character string."
  )
  stop_if(!file.exists(strPath), "[ strPath ] path does not exist: {strPath}")
  stop_if(
    !dir.exists(strPath),
    "[ strPath ] path is not a directory: {strPath}"
  )
  stop_if(
    !is.logical(bContinueOnError) ||
      length(bContinueOnError) != 1 ||
      is.na(bContinueOnError),
    "[ bContinueOnError ] must be TRUE or FALSE."
  )

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

  if (is.null(lData)) {
    lData <- list()
  }
  stop_if(!is.list(lData), "[ lData ] must be a list.")
  .validate_project_hook_config(lConfig)
  lData <- .apply_project_load_config(lData, lConfig)

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
      LogMessage(
        level = "warn",
        message = "Phase '{phase}' has no workflows. Skipping."
      )
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
      lConfig = .phase_workflow_config(lConfig, phase),
      bReturnResult = bReturnResult,
      bKeepInputData = bKeepInputData,
      strResultNames = strResultNames,
      bContinueOnError = bContinueOnError
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

  project_result <- lPhaseResults
  if (isTRUE(bContinueOnError)) {
    project_result <- .project_run_summary(lPhaseResults)
  }

  .apply_project_save_config(project_result, lConfig)
  return(project_result)
}

.validate_project_hook_config <- function(lConfig) {
  if (is.null(lConfig)) {
    return(invisible(TRUE))
  }

  stop_if(!is.list(lConfig), "[ lConfig ] must be a list.")
  if ("project" %in% names(lConfig)) {
    stop_if(
      !is.null(lConfig$project) &&
        (!is.list(lConfig$project) || is.data.frame(lConfig$project)),
      "[ lConfig$project ] must be a list."
    )
  }
  if ("phases" %in% names(lConfig)) {
    phase_config <- lConfig$phases
    stop_if(
      !is.null(phase_config) &&
        (!is.list(phase_config) ||
          is.data.frame(phase_config) ||
          is.null(names(phase_config)) ||
          any(!nzchar(names(phase_config)))),
      "[ lConfig$phases ] must be a named list of phase configuration lists."
    )
    for (phase in names(phase_config)) {
      stop_if(
        !is.null(phase_config[[phase]]) &&
          (!is.list(phase_config[[phase]]) ||
            is.data.frame(phase_config[[phase]])),
        "[ lConfig$phases${phase} ] must be a list."
      )
    }
  }

  invisible(TRUE)
}

.project_config <- function(lConfig) {
  if (is.null(lConfig) || is.null(lConfig$project)) {
    return(NULL)
  }

  lConfig$project
}

.apply_project_load_config <- function(lData, lConfig) {
  project_config <- .project_config(lConfig)
  if (is.null(project_config) || !exists("LoadData", project_config)) {
    return(lData)
  }

  stop_if(
    !is.function(project_config$LoadData) ||
      !all(c("lConfig", "lData") %in% names(formals(project_config$LoadData))),
    "[ lConfig$project$LoadData ] must be a function with parameters: lConfig, lData."
  )

  LogMessage(
    level = "info",
    message = "Loading data with `lConfig$project$LoadData`.",
    cli_detail = "h3"
  )
  loaded_data <- project_config$LoadData(
    lConfig = project_config,
    lData = lData
  )
  stop_if(
    !is.list(loaded_data),
    "[ lConfig$project$LoadData ] must return a list."
  )
  loaded_data
}

.apply_project_save_config <- function(lProject, lConfig) {
  project_config <- .project_config(lConfig)
  if (is.null(project_config) || !exists("SaveData", project_config)) {
    return(invisible(TRUE))
  }

  stop_if(
    !is.function(project_config$SaveData) ||
      !all(
        c("lProject", "lConfig") %in% names(formals(project_config$SaveData))
      ),
    "[ lConfig$project$SaveData ] must be a function with parameters: lProject, lConfig."
  )

  LogMessage(
    level = "info",
    message = "Saving project data with `lConfig$project$SaveData`.",
    cli_detail = "h3"
  )
  project_config$SaveData(lProject = lProject, lConfig = project_config)
  invisible(TRUE)
}

.phase_workflow_config <- function(lConfig, strPhase) {
  if (is.null(lConfig)) {
    return(NULL)
  }

  has_scoped_config <- "project" %in%
    names(lConfig) ||
    "phases" %in% names(lConfig)
  if (!has_scoped_config) {
    return(lConfig)
  }

  workflow_config <- lConfig[setdiff(names(lConfig), c("project", "phases"))]
  phase_config <- lConfig$phases[[strPhase]]
  if (!is.null(phase_config)) {
    workflow_config <- utils::modifyList(workflow_config, phase_config)
  }

  if (
    !exists("LoadData", workflow_config) && !exists("SaveData", workflow_config)
  ) {
    return(NULL)
  }

  workflow_config
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
  .reject_unknown_config_keys(
    lConfig,
    c("input", "output"),
    strPhase,
    "top-level"
  )

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
  .reject_unknown_config_keys(
    output,
    c("wrap_as", "transform"),
    strPhase,
    "output"
  )

  list(
    input = list(
      from_phases = .normalize_phase_vector(
        input$from_phases,
        strPhase,
        "input.from_phases",
        allow_null = TRUE
      ),
      from_results = .normalize_phase_mapping(
        input$from_results,
        strPhase,
        "input.from_results"
      ),
      include_workflows = .normalize_include_workflows(
        input$include_workflows,
        strPhase
      ),
      extra = .normalize_extra_inputs(input$extra, strPhase)
    ),
    output = list(
      wrap_as = .normalize_single_string(
        output$wrap_as,
        strPhase,
        "output.wrap_as",
        allow_null = TRUE
      ),
      transform = .normalize_single_string(
        output$transform,
        strPhase,
        "output.transform",
        allow_null = TRUE
      )
    )
  )
}

.validate_named_config_list <- function(value, strPhase, strSection) {
  unnamed <- length(value) > 0 &&
    (is.null(names(value)) || any(!nzchar(names(value))))
  stop_if(
    !is.list(value) || is.data.frame(value) || unnamed,
    "Phase '{strPhase}' _config.yaml {strSection} must be a map."
  )
  invisible(TRUE)
}

.reject_unknown_config_keys <- function(
  value,
  valid_keys,
  strPhase,
  strSection
) {
  unknown_keys <- setdiff(names(value), valid_keys)
  stop_if(
    length(unknown_keys) > 0,
    "Phase '{strPhase}' _config.yaml contains unknown {strSection} key(s): {paste(unknown_keys, collapse = ', ')}"
  )
  invisible(TRUE)
}

.normalize_phase_vector <- function(
  value,
  strPhase,
  strField,
  allow_null = FALSE
) {
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

  if (
    !is.list(value) ||
      is.data.frame(value) ||
      is.null(names(value)) ||
      any(!nzchar(names(value)))
  ) {
    .phase_config_stop(
      strPhase,
      "{strField} must be a named map of target_name: source_phase."
    )
  }

  values <- unlist(value, recursive = FALSE, use.names = FALSE)
  if (!is.character(values) || length(values) != length(value)) {
    .phase_config_stop(
      strPhase,
      "{strField} values must be phase folder names."
    )
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

  .phase_config_stop(
    strPhase,
    "input.include_workflows must be true, false, or a map with from_phase."
  )
}

.normalize_extra_inputs <- function(value, strPhase) {
  if (is.null(value)) {
    return(list())
  }

  if (is.list(value) && length(value) == 0) {
    return(list())
  }

  if (
    !is.list(value) ||
      is.data.frame(value) ||
      is.null(names(value)) ||
      any(!nzchar(names(value)))
  ) {
    .phase_config_stop(strPhase, "input.extra must be a named map.")
  }

  value
}

.normalize_single_string <- function(
  value,
  strPhase,
  strField,
  allow_null = FALSE
) {
  if (is.null(value)) {
    if (allow_null) {
      return(NULL)
    }
    .phase_config_stop(strPhase, "{strField} must be a single string.")
  }

  if (!is.character(value) || length(value) != 1 || is.na(value)) {
    .phase_config_stop(strPhase, "{strField} must be a single string or null.")
  }

  value <- trimws(value)
  if (!nzchar(value)) {
    .phase_config_stop(strPhase, "{strField} must be a non-empty string.")
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
    .require_prior_phase(
      source_phase,
      lPhaseData,
      strPhase,
      "input.from_phases"
    )
    lData <- .merge_named_lists(lData, lPhaseData[[source_phase]])
  }

  for (target_name in names(input$from_results)) {
    source_phase <- input$from_results[[target_name]]
    .require_prior_phase(
      source_phase,
      lPhaseResults,
      strPhase,
      "input.from_results"
    )
    lData[[target_name]] <- .workflow_summary_results(lPhaseResults[[
      source_phase
    ]])
  }

  if (isTRUE(input$include_workflows)) {
    lData$lWorkflows <- lCurrentWorkflows
  } else if (is.list(input$include_workflows)) {
    source_phase <- input$include_workflows$from_phase
    if (identical(source_phase, strPhase)) {
      lData$lWorkflows <- lCurrentWorkflows
    } else {
      .require_prior_phase(
        source_phase,
        lPhaseWorkflows,
        strPhase,
        "input.include_workflows.from_phase"
      )
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

.apply_phase_output_config <- function(
  phase_result,
  lOutputConfig,
  strPhase,
  transform_env
) {
  if (.is_workr_run_summary(phase_result)) {
    phase_result$results <- .apply_phase_output_config(
      phase_result = phase_result$results,
      lOutputConfig = lOutputConfig,
      strPhase = strPhase,
      transform_env = transform_env
    )
    return(phase_result)
  }

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
    stop_if(
      length(parts) != 2,
      "output.transform '{transform_ref}' is not a valid namespaced function reference."
    )
    return(getExportedValue(parts[[1]], parts[[2]]))
  }

  if (
    exists(
      transform_ref,
      envir = transform_env,
      mode = "function",
      inherits = TRUE
    )
  ) {
    return(get(
      transform_ref,
      envir = transform_env,
      mode = "function",
      inherits = TRUE
    ))
  }

  stop(
    "output.transform '",
    transform_ref,
    "' could not be resolved as a function.",
    call. = FALSE
  )
}

.phase_result_to_data <- function(
  phase_result,
  bReturnResult,
  lOutputConfig,
  strPhase
) {
  if (
    .is_workr_run_summary(phase_result) && length(phase_result$results) == 0
  ) {
    return(list())
  }

  phase_result <- .workflow_summary_results(phase_result)
  output_was_shaped <- !is.null(lOutputConfig$wrap_as) ||
    !is.null(lOutputConfig$transform)
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
    !is.list(phase_result) ||
      is.data.frame(phase_result) ||
      is.null(names(phase_result)) ||
      any(!nzchar(names(phase_result))),
    "Phase '{strPhase}' output must be a named list to be used by downstream phases."
  )

  phase_result
}

.project_run_summary <- function(results) {
  status_parts <- lapply(names(results), function(phase) {
    phase_result <- results[[phase]]
    if (
      !.is_workr_run_summary(phase_result) || nrow(phase_result$status) == 0
    ) {
      return(NULL)
    }

    data.frame(
      phase = phase,
      phase_result$status,
      stringsAsFactors = FALSE
    )
  })
  status_parts <- status_parts[!vapply(status_parts, is.null, logical(1))]

  if (length(status_parts) == 0) {
    status <- data.frame(
      phase = character(),
      workflow = character(),
      status = character(),
      message = character(),
      stringsAsFactors = FALSE
    )
  } else {
    status <- do.call(rbind, status_parts)
    row.names(status) <- NULL
  }

  failures <- status[status$status == "error", , drop = FALSE]
  structure(
    list(
      results = results,
      status = status,
      failures = failures
    ),
    class = c("workr_project_summary", "list")
  )
}
