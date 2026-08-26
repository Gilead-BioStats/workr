#' Run a project from a configuration file
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' `RunStudy()` runs a [RunProject()] project described entirely by a YAML
#' configuration file: which phases exist, which subset of them a given stage
#' runs, which load/save hooks are attached at which scope, and where the run's
#' evidence is written.
#'
#' It exists so a study repository holds configuration rather than scripts. A
#' cron job, an AWS batch job or an `rv run` invocation needs one line:
#'
#' ```
#' rv run -- Rscript -e 'workr::RunStudy(strStage = Sys.getenv("STAGE", "all"))'
#' ```
#'
#' Any string in the configuration may interpolate the environment as
#' `${VAR}` or `${VAR:-default}`, so a schedule varies a run by its
#' environment rather than by editing the study.
#'
#' @details
#' # Configuration
#'
#' ```yaml
#' project:
#'   path: workflow              # catalog: directory of phase folders
#'   run_path: data/workflows-run # staged copy that actually runs
#'   include:                    # optional: the catalog subset to stage
#'     1_mappings: [AE.yaml]
#'   overlay: workflow-patches   # optional: study-owned workflow overrides
#'   phases: [1_mappings, 2_metrics, 3_reporting]
#'   stages:                     # optional named phase subsets
#'     mapping: [1_mappings]
#'     analysis: [2_metrics, 3_reporting]
#'   continue_on_error: true     # default TRUE: record failures, keep going
#'   expected_failures: []       # workflows allowed to fail
#' packages:
#'   require: [gsm.template]     # loaded so their providers self-register
#'   attach: [gsm.core]          # attached for unqualified step names
#' hooks:
#'   LoadData: gsm.template.load           # registered provider name
#'   SaveData: gsm.template.save
#'   phases:
#'     4_modules:
#'       SaveData: gsm.template.save.module
#'   project:
#'     LoadData: gsm.template::ProjectLoad # project scope takes pkg::fn
#'     SaveData: gsm.template::ProjectSave
#' config:                       # merged into lConfig for providers to read
#'   builder: gsm.template::UpdateConfig   # optional: build it from a package
#'   args:
#'     strStudyID: AA-AA-000-0000
#'     strSnapshotDate: ${SNAPSHOT_DATE:-2025-06-30}
#'   S3:
#'     bucket: data
#' run:
#'   before: [gsm.template::PrepareStorage]  # called before the project runs
#' output:
#'   dir: data/output            # evidence lands here, per stage
#' ```
#'
#' `hooks$LoadData` and `hooks$SaveData` -- and any `hooks$phases` entry -- name
#' providers registered with [register_load_provider()] /
#' [register_save_provider()]. `hooks$project` entries are functions, which
#' `RunStudy()` resolves from `"package::function"` strings, because
#' [RunProject()] validates project-scope hooks by formals rather than by name.
#'
#' # Evidence
#'
#' Whatever the outcome, the stage's output directory gets:
#'
#' * `hook-trace.csv` -- every hook invocation ([HookTrace()]).
#' * `hook-checks.csv` -- the generic assertions in [CheckHookTrace()].
#' * `run-status.yaml` -- status, stage, phases, failures, check results.
#' * `failure-context.yaml` -- error and traceback, when the run stops.
#'
#' That is the difference between "the 2am job failed" and "the save hook for
#' `Mapped_AE` raised `NoSuchBucket` after loading 6 domains".
#'
#' @param strConfigPath `character` Path to the YAML configuration file.
#'   Default `"study.yaml"`.
#' @param strStage `character` Stage to run: a name from `project$stages`, or
#'   `"all"` for every phase in `project$phases`. Default `"all"`.
#' @param lParams `list` Extra named values seeded into `lData` before the run,
#'   e.g. a snapshot date resolved by the caller. Default `NULL`.
#' @param strOutputDir `character` Override the evidence directory. Default
#'   `NULL`, i.e. `output$dir` from the configuration (with a `stages/<stage>`
#'   subdirectory for a single-stage run).
#'
#' @return Invisibly, a list with `stage`, `phases`, `summary` (the
#'   [RunProject()] result), `trace` and `checks`.
#'
#' @examples
#' \dontrun{
#' RunStudy("study.yaml")
#' RunStudy("study.yaml", strStage = "analysis")
#' }
#'
#' @export
RunStudy <- function(
  strConfigPath = "study.yaml",
  strStage = "all",
  lParams = NULL,
  strOutputDir = NULL
) {
  stop_if(
    !is.character(strConfigPath) || length(strConfigPath) != 1,
    "[ strConfigPath ] must be a single character string."
  )
  stop_if(
    !file.exists(strConfigPath),
    "[ strConfigPath ] does not exist: {strConfigPath}"
  )

  lStudy <- study_expand_env(yaml::read_yaml(strConfigPath))
  lProject <- lStudy$project %||% list()
  stop_if(
    !is.list(lProject) || is.null(lProject$path),
    "[ {strConfigPath} ] must define `project$path`."
  )

  strPhases <- study_stage_phases(lProject, strStage)
  strOutputDir <- strOutputDir %||% study_output_dir(lStudy, strStage)
  dir.create(strOutputDir, recursive = TRUE, showWarnings = FALSE)
  unlink(file.path(strOutputDir, "failure-context.yaml"), force = TRUE)

  study_load_packages(lStudy$packages)
  HookTraceReset()

  lConfig <- study_run_config(lStudy)
  # Callbacks and hooks see the project block too, so a check that belongs to
  # the catalog -- is the projection complete, do its pins still match -- can
  # read what this run intends to execute.
  lConfig$Project <- lProject

  LogMessage(
    level = "info",
    message = "Running stage '{strStage}': {paste(strPhases, collapse = ', ')}",
    cli_detail = "h1"
  )

  # Anything the run needs done before it starts -- validating the workflow
  # projection, clearing a snapshot's storage, restoring a prior stage's state
  # -- is a configured function rather than a script the study has to carry.
  study_run_callbacks(lStudy$run$before, lConfig, strStage, strOutputDir)

  # Stage the catalog subset this study runs, so `project$path` stays the
  # pristine library and `run_path` is what actually executes.
  strProjectPath <- lProject$path
  if (!is.null(lProject$include) || !is.null(lProject$run_path)) {
    strProjectPath <- lProject$run_path %||% file.path("data", "workflows-run")
    StageProject(
      strPath = lProject$path,
      lInclude = lProject$include,
      strRunPath = strProjectPath,
      strOverlayPath = lProject$overlay
    )
  }
  lData <- utils::modifyList(as.list(lStudy$data %||% list()), as.list(lParams %||% list()))

  bContinueOnError <- lProject$continue_on_error %||% TRUE
  lSummary <- tryCatch(
    RunProject(
      strPath = strProjectPath,
      lData = lData,
      lConfig = lConfig,
      strPhases = strPhases,
      bRecursive = isTRUE(lProject$recursive),
      bReturnResult = TRUE,
      bContinueOnError = isTRUE(bContinueOnError)
    ),
    error = function(error) {
      study_write_failure(strOutputDir, error, strStage)
      stop(error)
    }
  )

  dfTrace <- HookTrace()
  dfFailures <- if (isTRUE(bContinueOnError)) lSummary$failures
  dfChecks <- CheckHookTrace(dfTrace, lConfig = lConfig, dfFailures = dfFailures)

  study_write_evidence(
    strOutputDir = strOutputDir,
    strStage = strStage,
    strPhases = strPhases,
    dfTrace = dfTrace,
    dfChecks = dfChecks,
    dfFailures = dfFailures
  )

  study_run_callbacks(lStudy$run$after, lConfig, strStage, strOutputDir)
  study_report_checks(dfChecks)

  strExpected <- as.character(unlist(lProject$expected_failures %||% character()))
  strUnexpected <- setdiff(as.character(dfFailures$workflow %||% character()), strExpected)
  if (length(strUnexpected) > 0) {
    error <- simpleError(sprintf(
      "Unexpected workflow failures: %s (see %s)",
      paste(strUnexpected, collapse = ", "), file.path(strOutputDir, "run-status.yaml")
    ))
    study_write_failure(strOutputDir, error, strStage)
    stop(error)
  }
  if (any(!dfChecks$ok)) {
    error <- simpleError(sprintf(
      "Hook checks failed: %s (see %s)",
      paste(dfChecks$check[!dfChecks$ok], collapse = "; "),
      file.path(strOutputDir, "hook-checks.csv")
    ))
    study_write_failure(strOutputDir, error, strStage)
    stop(error)
  }

  LogMessage(
    level = "info",
    message = "Stage '{strStage}' completed.",
    cli_detail = "h1"
  )

  invisible(list(
    stage = strStage,
    phases = strPhases,
    summary = lSummary,
    trace = dfTrace,
    checks = dfChecks
  ))
}

# Phases a stage runs. Stages are named subsets of `project$phases`, so a cron
# schedule can run one part of the pipeline per job without a second config.
study_stage_phases <- function(lProject, strStage) {
  strPhases <- as.character(unlist(lProject$phases %||% character()))
  lStages <- lProject$stages %||% list()
  strChoices <- c("all", names(lStages))

  stop_if(
    !is.character(strStage) || length(strStage) != 1 || !strStage %in% strChoices,
    "[ strStage ] must be one of: {paste(strChoices, collapse = ', ')}"
  )

  if (identical(strStage, "all")) {
    stop_if(length(strPhases) == 0, "[ project$phases ] must name at least one phase.")
    return(strPhases)
  }

  strStagePhases <- as.character(unlist(lStages[[strStage]]))
  strMissing <- setdiff(strStagePhases, strPhases)
  stop_if(
    length(strMissing) > 0,
    "Stage '{strStage}' names phases missing from `project$phases`: {paste(strMissing, collapse = ', ')}"
  )
  strStagePhases
}

# `run$before` / `run$after`: "package::function" entries, each called with the
# resolved configuration, the stage and the evidence directory.
study_run_callbacks <- function(value, lConfig, strStage, strOutputDir) {
  for (entry in as.list(value %||% list())) {
    fn <- resolve_function_reference(entry, strSource = "run$before/run$after")
    fn(lConfig = lConfig, strStage = strStage, strOutputDir = strOutputDir)
  }
  invisible(TRUE)
}

study_output_dir <- function(lStudy, strStage) {
  strBase <- lStudy$output$dir %||% "data/output"
  if (identical(strStage, "all")) strBase else file.path(strBase, "stages", strStage)
}

# Load provider packages (their `.onLoad()` registers providers) and attach the
# packages whose step functions workflows call without a namespace prefix.
study_load_packages <- function(lPackages) {
  for (strPackage in as.character(unlist(lPackages$require %||% character()))) {
    stop_if(
      !requireNamespace(strPackage, quietly = TRUE),
      "Configured package is not installed: {strPackage}"
    )
  }
  for (strPackage in as.character(unlist(lPackages$attach %||% character()))) {
    stop_if(
      !requireNamespace(strPackage, quietly = TRUE),
      "Configured package is not installed: {strPackage}"
    )
    suppressPackageStartupMessages(
      library(strPackage, character.only = TRUE)
    )
  }
  invisible(TRUE)
}

#' Resolve a study configuration
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Returns the `lConfig` a [RunStudy()] run would use: the configuration file's
#' `config` block with its environment references expanded, built by
#' `config$builder` when one is named, and with the `project` block attached as
#' `Project`.
#'
#' Use it wherever a tool needs the same view of a study the pipeline has --
#' pulling its workflow library, moving its stored state between environments --
#' so those entry points stay wiring rather than a second implementation of the
#' configuration.
#'
#' @param strConfigPath `character` Path to the YAML configuration file.
#'   Default `"study.yaml"`.
#' @param bLoadPackages `logical` Load and attach the packages the
#'   configuration names, so a builder or provider it references is available.
#'   Default `TRUE`.
#'
#' @return `list` The resolved configuration.
#'
#' @examples
#' \dontrun{
#' lConfig <- StudyConfig()
#' lConfig$StudyID
#' }
#'
#' @export
StudyConfig <- function(strConfigPath = "study.yaml", bLoadPackages = TRUE) {
  stop_if(
    !file.exists(strConfigPath),
    "[ strConfigPath ] does not exist: {strConfigPath}"
  )

  lStudy <- study_expand_env(yaml::read_yaml(strConfigPath))
  if (isTRUE(bLoadPackages)) {
    study_load_packages(lStudy$packages)
  }

  lConfig <- study_run_config(lStudy)
  lConfig$Project <- lStudy$project %||% list()
  lConfig
}

# `${VAR}` and `${VAR:-default}` in any string value, resolved from the
# environment. A scheduled run differs from an interactive one by its
# environment, not by its configuration file: `SNAPSHOT_DATE=2026-01-31 rv run
# -- Rscript -e 'workr::RunStudy()'`.
study_expand_env <- function(value) {
  if (is.list(value)) {
    return(lapply(value, study_expand_env))
  }
  if (!is.character(value)) {
    return(value)
  }

  vapply(
    value,
    function(string) {
      matches <- gregexpr("\\$\\{[^}]+\\}", string)[[1]]
      if (matches[[1]] == -1) {
        return(string)
      }

      for (strToken in unique(regmatches(string, gregexpr("\\$\\{[^}]+\\}", string))[[1]])) {
        strBody <- substr(strToken, 3, nchar(strToken) - 1)
        parts <- strsplit(strBody, ":-", fixed = TRUE)[[1]]
        strValue <- Sys.getenv(parts[[1]], unset = "")
        if (!nzchar(strValue)) {
          stop_if(
            length(parts) < 2,
            "Configuration refers to unset environment variable: {parts[[1]]}"
          )
          strValue <- paste(parts[-1], collapse = ":-")
        }
        string <- gsub(strToken, strValue, string, fixed = TRUE)
      }

      string
    },
    character(1),
    USE.NAMES = FALSE
  )
}

# Turn the `hooks` and `config` blocks into the lConfig RunProject() expects.
study_run_config <- function(lStudy) {
  lHooks <- lStudy$hooks %||% list()
  lConfig <- as.list(lStudy$config %||% list())

  # `config$builder` lets a domain package assemble the configuration -- e.g.
  # gsm.template::UpdateConfig() resolving a study's config/ directory for a
  # snapshot -- with the rest of the `config` block merged over the result.
  if (!is.null(lConfig$builder)) {
    fnBuilder <- resolve_function_reference(lConfig$builder, strSource = "config$builder")
    lBuilt <- do.call(fnBuilder, as.list(lConfig$args %||% list()))
    stop_if(!is.list(lBuilt), "[ config$builder ] must return a list.")
    lConfig <- utils::modifyList(
      lBuilt,
      lConfig[setdiff(names(lConfig), c("builder", "args"))]
    )
  }

  for (strField in c("LoadData", "SaveData")) {
    if (!is.null(lHooks[[strField]])) lConfig[[strField]] <- lHooks[[strField]]
  }

  if (!is.null(lHooks$phases)) {
    lConfig$phases <- lHooks$phases
  }

  if (!is.null(lHooks$project)) {
    lProjectHooks <- lHooks$project
    for (strField in c("LoadData", "SaveData")) {
      if (!is.null(lProjectHooks[[strField]])) {
        # Keep the configured name: once resolved, the hook is an anonymous
        # function, and "project load via <function>" is a poor trace row.
        if (is.character(lProjectHooks[[strField]])) {
          lProjectHooks[[paste0(strField, "Name")]] <- lProjectHooks[[strField]]
        }
        lProjectHooks[[strField]] <- resolve_function_reference(
          lProjectHooks[[strField]],
          strSource = paste0("hooks$project$", strField)
        )
      }
    }
    # Project hooks receive `lConfig$project` as their lConfig, so provider
    # settings have to be reachable from there too.
    lConfig$project <- utils::modifyList(
      lConfig[setdiff(names(lConfig), c("phases", "project"))],
      lProjectHooks
    )
  }

  lConfig
}

# `"package::function"` -> the function. Project-scope hooks are validated by
# formals rather than looked up in the provider registry, so a config that
# names one has to be resolved here.
resolve_function_reference <- function(value, strSource) {
  if (is.function(value)) {
    return(value)
  }

  stop_if(
    !is.character(value) || length(value) != 1 || !nzchar(value),
    "[ {strSource} ] must be a function or a \"package::function\" string."
  )
  parts <- strsplit(value, "::", fixed = TRUE)[[1]]
  stop_if(
    length(parts) != 2,
    "[ {strSource} ] must be written as \"package::function\". Got: {value}"
  )
  stop_if(
    !requireNamespace(parts[[1]], quietly = TRUE),
    "[ {strSource} ] needs package {parts[[1]]}, which is not installed."
  )

  fn <- get0(parts[[2]], envir = asNamespace(parts[[1]]), mode = "function")
  stop_if(
    is.null(fn),
    "[ {strSource} ] not found: {value}"
  )
  fn
}

study_write_evidence <- function(strOutputDir, strStage, strPhases, dfTrace, dfChecks, dfFailures) {
  utils::write.csv(dfTrace, file.path(strOutputDir, "hook-trace.csv"), row.names = FALSE)
  utils::write.csv(dfChecks, file.path(strOutputDir, "hook-checks.csv"), row.names = FALSE)

  yaml::write_yaml(
    list(
      status = if (NROW(dfFailures) > 0) {
        "completed_with_failures"
      } else if (all(dfChecks$ok)) {
        "ok"
      } else {
        "failed"
      },
      stage = strStage,
      phases = strPhases,
      run_time_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
      hooks = stats::setNames(
        as.list(sprintf("%s %s", dfTrace$scope, dfTrace$action)[dfTrace$event == "hook"]),
        NULL
      ),
      failures = if (NROW(dfFailures) > 0) {
        sprintf("%s/%s: %s", dfFailures$phase, dfFailures$workflow, dfFailures$message)
      },
      checks = stats::setNames(as.list(dfChecks$ok), dfChecks$check)
    ),
    file.path(strOutputDir, "run-status.yaml")
  )
  invisible(strOutputDir)
}

study_write_failure <- function(strOutputDir, error, strStage) {
  dir.create(strOutputDir, recursive = TRUE, showWarnings = FALSE)
  dfTrace <- tryCatch(HookTrace(), error = function(...) NULL)
  if (!is.null(dfTrace)) {
    utils::write.csv(dfTrace, file.path(strOutputDir, "hook-trace.csv"), row.names = FALSE)
  }

  # The last hook to run is almost always the thing that broke, so name it
  # rather than making the reader open the trace to find out.
  strLastHook <- NA_character_
  if (!is.null(dfTrace) && nrow(dfTrace) > 0) {
    dfHooks <- dfTrace[dfTrace$event == "hook", , drop = FALSE]
    if (nrow(dfHooks) > 0) {
      last <- dfHooks[nrow(dfHooks), ]
      strLastHook <- sprintf(
        "%s %s via %s for %s (%s)",
        last$scope, last$action, last$provider, last$workflow, last$status
      )
    }
  }

  yaml::write_yaml(
    list(
      error = conditionMessage(error),
      stage = strStage,
      last_hook = strLastHook,
      traceback = vapply(sys.calls(), function(call) deparse1(call), character(1))
    ),
    file.path(strOutputDir, "failure-context.yaml")
  )
  invisible(strOutputDir)
}

study_report_checks <- function(dfChecks) {
  if (NROW(dfChecks) == 0) {
    return(invisible(NULL))
  }
  LogMessage(level = "info", message = "Hook checks", cli_detail = "h2")
  for (i in seq_len(nrow(dfChecks))) {
    LogMessage(
      level = if (isTRUE(dfChecks$ok[i])) "info" else "error",
      message = "[{ifelse(dfChecks$ok[i], 'PASS', 'FAIL')}] {dfChecks$check[i]} ({dfChecks$detail[i]})",
      cli_detail = "alert_info"
    )
  }
  invisible(dfChecks)
}
