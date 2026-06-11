test_that("RunProject runs all phases in sorted order (#26)", {
  sum_step <- function(lData, y) lData$value + y
  assign("sum_step", sum_step, envir = globalenv())
  on.exit(rm("sum_step", envir = globalenv()), add = TRUE)

  project_path <- test_path("project")
  lData <- list(value = 5)

  result <- RunProject(
    strPath = project_path,
    lData = lData
  )

  expect_type(result, "list")
  expect_named(result, c("phase_A", "phase_B"))
  expect_true("phase1_add_ten" %in% names(result$phase_A))
  expect_true("phase2_add_twenty" %in% names(result$phase_B))
})

test_that("RunProject passes data between phases (#26)", {
  sum_step <- function(lData, y) lData$value + y
  assign("sum_step", sum_step, envir = globalenv())
  on.exit(rm("sum_step", envir = globalenv()), add = TRUE)

  project_path <- test_path("project")
  lData <- list(value = 5)

  result <- RunProject(
    strPath = project_path,
    lData = lData,
    bReturnResult = FALSE
  )

  # Phase A result
  p1 <- result$phase_A[["phase1_add_ten"]]
  expect_true(!is.null(p1$lData))
  expect_equal(p1$lData$result_p1, 10) # 5 + 5

  # Phase B gets data from Phase A
  p2 <- result$phase_B[["phase2_add_twenty"]]
  expect_true(!is.null(p2$lData))
})

test_that("RunProject respects strPhases subset and order (#26)", {
  sum_step <- function(lData, y) lData$value + y
  assign("sum_step", sum_step, envir = globalenv())
  on.exit(rm("sum_step", envir = globalenv()), add = TRUE)

  project_path <- test_path("project")
  lData <- list(value = 5)

  # Only run phase_B
  result <- RunProject(
    strPath = project_path,
    lData = lData,
    strPhases = "phase_B"
  )

  expect_named(result, "phase_B")

  # Reverse order
  result2 <- RunProject(
    strPath = project_path,
    lData = lData,
    strPhases = c("phase_B", "phase_A")
  )

  expect_named(result2, c("phase_B", "phase_A"))
})

test_that("RunProject errors on missing strPath (#26)", {
  expect_error(
    RunProject(strPath = "/nonexistent/path/xyz"),
    "strPath"
  )
})

test_that("RunProject errors on missing requested phases (#26)", {
  project_path <- test_path("project")

  RunProject(
    strPath = project_path,
    strPhases = c("phase_A", "nonexistent_phase")
  ) |>
    expect_error("strPhases")
})

test_that("RunProject errors on empty project directory (#26)", {
  tmp <- tempdir()
  empty_dir <- file.path(tmp, "empty_project_test")
  dir.create(empty_dir, showWarnings = FALSE)
  on.exit(unlink(empty_dir, recursive = TRUE), add = TRUE)

  RunProject(strPath = empty_dir) |>
    expect_error("No phase folders")
})

test_that("RunProject discovers phases in alphabetical order by default (#63)", {
  sum_step <- function(lData, y) lData$value + y
  assign("sum_step", sum_step, envir = globalenv())
  on.exit(rm("sum_step", envir = globalenv()), add = TRUE)

  result <- RunProject(
    strPath = test_path("project_ordered"),
    lData = list(value = 5)
  )

  # Folders 3_x, 1_y, 2_z on disk -> alphabetical discovery: 1_y, 2_z, 3_x
  expect_named(result, c("1_y", "2_z", "3_x"))
})

test_that("RunProject runs strPhases in caller order, not sorted (#63)", {
  sum_step <- function(lData, y) lData$value + y
  assign("sum_step", sum_step, envir = globalenv())
  on.exit(rm("sum_step", envir = globalenv()), add = TRUE)

  result <- RunProject(
    strPath = test_path("project_ordered"),
    lData = list(value = 5),
    strPhases = c("3_x", "1_y", "2_z")
  )

  expect_named(result, c("3_x", "1_y", "2_z"))
})

test_that("RunProject errors when strPath is not a directory (#63)", {
  expect_error(
    RunProject(strPath = test_path("project_ordered", "1_y", "y_step.yaml")),
    "not a directory"
  )
})

test_that("RunProject warns on empty phase folder and proceeds (#63)", {
  sum_step <- function(lData, y) lData$value + y
  assign("sum_step", sum_step, envir = globalenv())
  on.exit(rm("sum_step", envir = globalenv()), add = TRUE)

  # Build a project with one populated phase and one empty phase
  proj <- tempfile("project_empty_phase_test")
  dir.create(file.path(proj, "1_populated"), recursive = TRUE, showWarnings = FALSE)
  dir.create(file.path(proj, "2_empty"), recursive = TRUE, showWarnings = FALSE)
  on.exit(unlink(proj, recursive = TRUE), add = TRUE)

  file.copy(
    test_path("project_ordered", "1_y", "y_step.yaml"),
    file.path(proj, "1_populated", "y_step.yaml")
  )

  # Assign inside expect_message(): it returns the matched condition, not the
  # value of the expression, so capture RunProject()'s result via assignment.
  result <- NULL
  expect_message(
    result <- RunProject(strPath = proj, lData = list(value = 5)),
    "no workflows"
  )

  # Empty phase is skipped (warning, not error); populated phase still runs
  expect_named(result, "1_populated")
})

test_that("RunProject bReturnResult and bKeepInputData pass through (#26)", {
  sum_step <- function(lData, y) lData$value + y
  assign("sum_step", sum_step, envir = globalenv())
  on.exit(rm("sum_step", envir = globalenv()), add = TRUE)

  project_path <- test_path("project")
  lData <- list(value = 5)

  # bReturnResult = TRUE returns just the final step output
  result_true <- RunProject(
    strPath = project_path,
    lData = lData,
    strPhases = "phase_A",
    bReturnResult = TRUE
  )
  expect_equal(result_true$phase_A[["phase1_add_ten"]], 10)

  # bReturnResult = FALSE returns the full workflow object
  result_false <- RunProject(
    strPath = project_path,
    lData = lData,
    strPhases = "phase_A",
    bReturnResult = FALSE
  )
  expect_true(is.list(result_false$phase_A[["phase1_add_ten"]]))
  expect_true("lData" %in% names(result_false$phase_A[["phase1_add_ten"]]))
})

write_project_workflow <- function(project_path, phase, id, step_name, output, params = list()) {
  phase_path <- file.path(project_path, phase)
  dir.create(phase_path, recursive = TRUE, showWarnings = FALSE)

  workflow <- list(
    meta = list(Type = "phase", ID = id),
    steps = list(
      list(name = step_name, output = output, params = params)
    )
  )

  yaml::write_yaml(workflow, file.path(phase_path, paste0(id, ".yaml")))
}

test_that("RunProject validates per-phase _config.yaml schema (#64)", {
  project_path <- file.path(tempdir(), "project_config_schema_test")
  unlink(project_path, recursive = TRUE)
  on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

  write_project_workflow(
    project_path,
    phase = "1_phase",
    id = "capture",
    step_name = "identity",
    output = "captured",
    params = list(x = "value")
  )

  writeLines(
    c(
      "input:",
      "  unexpected: true"
    ),
    file.path(project_path, "1_phase", "_config.yaml")
  )

  expect_error(
    RunProject(project_path, lData = list(value = 1)),
    "Phase '1_phase'.*unknown input key.*unexpected"
  )
})

test_that("RunProject rejects empty or whitespace-only output config strings (#64)", {
  project_path <- file.path(tempdir(), "project_config_empty_string_test")
  unlink(project_path, recursive = TRUE)
  on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

  write_project_workflow(
    project_path,
    phase = "1_phase",
    id = "capture",
    step_name = "identity",
    output = "captured",
    params = list(x = "value")
  )

  writeLines(
    c(
      "output:",
      "  wrap_as: '   '"
    ),
    file.path(project_path, "1_phase", "_config.yaml")
  )

  expect_error(
    RunProject(project_path, lData = list(value = 1)),
    "Phase '1_phase'.*output.wrap_as must be a non-empty string"
  )

  writeLines(
    c(
      "output:",
      "  transform: ''"
    ),
    file.path(project_path, "1_phase", "_config.yaml")
  )

  expect_error(
    RunProject(project_path, lData = list(value = 1)),
    "Phase '1_phase'.*output.transform must be a non-empty string"
  )
})

test_that("RunProject assembles phase input from config rules (#65)", {
  emit_value <- function(value) value
  capture_data <- function(lData) lData
  assign("emit_value", emit_value, envir = globalenv())
  assign("capture_data", capture_data, envir = globalenv())
  on.exit(
    {
      rm("emit_value", envir = globalenv())
      rm("capture_data", envir = globalenv())
    },
    add = TRUE
  )

  project_path <- file.path(tempdir(), "project_config_input_test")
  unlink(project_path, recursive = TRUE)
  on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

  write_project_workflow(
    project_path,
    phase = "1_source",
    id = "p1",
    step_name = "emit_value",
    output = "out",
    params = list(value = "phase1")
  )
  write_project_workflow(
    project_path,
    phase = "2_source",
    id = "p2",
    step_name = "emit_value",
    output = "out",
    params = list(value = "phase2")
  )
  write_project_workflow(
    project_path,
    phase = "3_capture",
    id = "capture",
    step_name = "capture_data",
    output = "captured",
    params = list(lData = "lData")
  )

  writeLines(
    c(
      "input:",
      "  from_phases: [1_source]",
      "  from_results:",
      "    aliased_p2: 2_source",
      "  include_workflows:",
      "    from_phase: 2_source",
      "  extra:",
      "    phase_p1: extra_wins",
      "    literal_date: Sys.Date()"
    ),
    file.path(project_path, "3_capture", "_config.yaml")
  )

  result <- RunProject(project_path, lData = list(seed = "initial"))
  captured <- result$`3_capture`$phase_capture

  expect_equal(captured$seed, "initial")
  expect_equal(captured$phase_p1, "extra_wins")
  expect_false("phase_p2" %in% names(captured))
  expect_equal(captured$aliased_p2$phase_p2, "phase2")
  expect_equal(names(captured$lWorkflows), "p2")
  expect_equal(captured$literal_date, "Sys.Date()")
})

test_that("RunProject wraps and transforms phase output (#66)", {
  emit_value <- function(value) value
  capture_data <- function(lData) lData
  append_suffix <- function(result) {
    result$phase_p1 <- paste0(result$phase_p1, "_transformed")
    result
  }
  assign("emit_value", emit_value, envir = globalenv())
  assign("capture_data", capture_data, envir = globalenv())
  on.exit(
    {
      rm("emit_value", envir = globalenv())
      rm("capture_data", envir = globalenv())
    },
    add = TRUE
  )

  project_path <- file.path(tempdir(), "project_config_output_test")
  unlink(project_path, recursive = TRUE)
  on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

  write_project_workflow(
    project_path,
    phase = "1_source",
    id = "p1",
    step_name = "emit_value",
    output = "out",
    params = list(value = "phase1")
  )
  write_project_workflow(
    project_path,
    phase = "2_capture",
    id = "capture",
    step_name = "capture_data",
    output = "captured",
    params = list(lData = "lData")
  )

  writeLines(
    c(
      "output:",
      "  wrap_as: wrapped",
      "  transform: append_suffix"
    ),
    file.path(project_path, "1_source", "_config.yaml")
  )
  writeLines(
    c(
      "input:",
      "  from_phases: [1_source]"
    ),
    file.path(project_path, "2_capture", "_config.yaml")
  )

  result <- RunProject(project_path)
  captured <- result$`2_capture`$phase_capture

  expect_named(result$`1_source`, "wrapped")
  expect_equal(captured$wrapped$phase_p1, "phase1_transformed")
  expect_false("phase_p1" %in% names(captured))
})

test_that("RunProject transform failures identify the transform reference (#66)", {
  emit_value <- function(value) value
  bad_transform <- function(result) stop("boom")
  assign("emit_value", emit_value, envir = globalenv())
  on.exit(rm("emit_value", envir = globalenv()), add = TRUE)

  project_path <- file.path(tempdir(), "project_config_transform_failure_test")
  unlink(project_path, recursive = TRUE)
  on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

  write_project_workflow(
    project_path,
    phase = "1_source",
    id = "p1",
    step_name = "emit_value",
    output = "out",
    params = list(value = "phase1")
  )

  writeLines(
    c(
      "output:",
      "  transform: bad_transform"
    ),
    file.path(project_path, "1_source", "_config.yaml")
  )

  expect_error(
    RunProject(project_path),
    "output.transform 'bad_transform' failed: boom"
  )
})

test_that("RunProject without phase configs preserves flat carry-forward behavior (#67)", {
  emit_value <- function(value) value
  capture_data <- function(lData) lData
  assign("emit_value", emit_value, envir = globalenv())
  assign("capture_data", capture_data, envir = globalenv())
  on.exit(
    {
      rm("emit_value", envir = globalenv())
      rm("capture_data", envir = globalenv())
    },
    add = TRUE
  )

  project_path <- file.path(tempdir(), "project_no_config_regression_test")
  unlink(project_path, recursive = TRUE)
  on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

  write_project_workflow(
    project_path,
    phase = "1_source",
    id = "p1",
    step_name = "emit_value",
    output = "out",
    params = list(value = "phase1")
  )
  write_project_workflow(
    project_path,
    phase = "2_source",
    id = "p2",
    step_name = "emit_value",
    output = "out",
    params = list(value = "phase2")
  )
  write_project_workflow(
    project_path,
    phase = "3_capture",
    id = "capture",
    step_name = "capture_data",
    output = "captured",
    params = list(lData = "lData")
  )

  result <- RunProject(project_path, lData = list(seed = "initial"))
  captured <- result$`3_capture`$phase_capture

  expect_equal(captured$seed, "initial")
  expect_equal(captured$phase_p1, "phase1")
  expect_equal(captured$phase_p2, "phase2")
  expect_false("lWorkflows" %in% names(captured))
  expect_false("lAnalyzed" %in% names(captured))
})

test_that("RunProject supports a four-phase configured project scenario (#67)", {
  make_mapped <- function(lData) {
    list(
      mapped_subjects = lData$raw_subjects,
      source_names = names(lData)
    )
  }
  make_metrics <- function(lData) {
    list(
      has_mapping = "phase_mapped" %in% names(lData),
      workflow_names = names(lData$lWorkflows),
      GroupID = factor("G1")
    )
  }
  make_reporting <- function(lData) {
    list(
      has_mapping = "phase_mapped" %in% names(lData),
      has_flat_metrics = "phase_metrics" %in% names(lData),
      has_analyzed = "lAnalyzed" %in% names(lData),
      analyzed_group_type = typeof(lData$lAnalyzed$phase_metrics$GroupID),
      workflow_names = names(lData$lWorkflows),
      snapshot_date = lData$dSnapshotDate
    )
  }
  make_modules <- function(lData) {
    list(
      has_reports = "lReports" %in% names(lData),
      has_mapping = "phase_mapped" %in% names(lData),
      has_flat_metrics = "phase_metrics" %in% names(lData),
      has_analyzed = "lAnalyzed" %in% names(lData),
      report_names = names(lData$lReports)
    )
  }
  coerce_group_id <- function(phase_result) {
    phase_result$phase_metrics$GroupID <- as.character(phase_result$phase_metrics$GroupID)
    phase_result
  }
  assign("make_mapped", make_mapped, envir = globalenv())
  assign("make_metrics", make_metrics, envir = globalenv())
  assign("make_reporting", make_reporting, envir = globalenv())
  assign("make_modules", make_modules, envir = globalenv())
  on.exit(
    {
      rm("make_mapped", envir = globalenv())
      rm("make_metrics", envir = globalenv())
      rm("make_reporting", envir = globalenv())
      rm("make_modules", envir = globalenv())
    },
    add = TRUE
  )

  project_path <- file.path(tempdir(), "project_four_phase_config_test")
  unlink(project_path, recursive = TRUE)
  on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

  write_project_workflow(
    project_path,
    phase = "1_mappings",
    id = "mapped",
    step_name = "make_mapped",
    output = "mapped",
    params = list(lData = "lData")
  )
  write_project_workflow(
    project_path,
    phase = "2_metrics",
    id = "metrics",
    step_name = "make_metrics",
    output = "metrics",
    params = list(lData = "lData")
  )
  write_project_workflow(
    project_path,
    phase = "3_reporting",
    id = "reporting",
    step_name = "make_reporting",
    output = "reporting",
    params = list(lData = "lData")
  )
  write_project_workflow(
    project_path,
    phase = "4_modules",
    id = "modules",
    step_name = "make_modules",
    output = "modules",
    params = list(lData = "lData")
  )

  writeLines(
    c(
      "input:",
      "  from_phases: [1_mappings]",
      "  include_workflows: true",
      "output:",
      "  transform: coerce_group_id"
    ),
    file.path(project_path, "2_metrics", "_config.yaml")
  )
  writeLines(
    c(
      "input:",
      "  from_phases: [1_mappings]",
      "  from_results:",
      "    lAnalyzed: 2_metrics",
      "  include_workflows:",
      "    from_phase: 2_metrics",
      "  extra:",
      "    dSnapshotDate: \"2026-06-09\"",
      "output:",
      "  wrap_as: lReports"
    ),
    file.path(project_path, "3_reporting", "_config.yaml")
  )
  writeLines(
    c(
      "input:",
      "  from_phases: [3_reporting]"
    ),
    file.path(project_path, "4_modules", "_config.yaml")
  )

  result <- RunProject(
    project_path,
    lData = list(raw_subjects = data.frame(SubjectID = c("01", "02")))
  )

  metrics <- result$`2_metrics`$phase_metrics
  reporting <- result$`3_reporting`$lReports$phase_reporting
  modules <- result$`4_modules`$phase_modules

  expect_true(metrics$has_mapping)
  expect_equal(metrics$workflow_names, "metrics")
  expect_type(metrics$GroupID, "character")

  expect_true(reporting$has_mapping)
  expect_false(reporting$has_flat_metrics)
  expect_true(reporting$has_analyzed)
  expect_equal(reporting$analyzed_group_type, "character")
  expect_equal(reporting$workflow_names, "metrics")
  expect_equal(reporting$snapshot_date, "2026-06-09")

  expect_named(result$`3_reporting`, "lReports")
  expect_true(modules$has_reports)
  expect_false(modules$has_mapping)
  expect_false(modules$has_flat_metrics)
  expect_false(modules$has_analyzed)
  expect_equal(modules$report_names, "phase_reporting")
})

test_that("RunProject continue-on-error returns project failure summary (#11)", {
  fail_value <- function(value) stop("phase boom")
  capture_data <- function(lData) lData
  assign("fail_value", fail_value, envir = globalenv())
  assign("capture_data", capture_data, envir = globalenv())
  on.exit(
    {
      rm("fail_value", envir = globalenv())
      rm("capture_data", envir = globalenv())
    },
    add = TRUE
  )

  project_path <- file.path(tempdir(), "project_continue_on_error_test")
  unlink(project_path, recursive = TRUE)
  on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

  write_project_workflow(
    project_path,
    phase = "1_failing_source",
    id = "bad",
    step_name = "fail_value",
    output = "out",
    params = list(value = "seed")
  )
  write_project_workflow(
    project_path,
    phase = "2_capture",
    id = "capture",
    step_name = "capture_data",
    output = "captured",
    params = list(lData = "lData")
  )

  result <- RunProject(
    project_path,
    lData = list(seed = "initial"),
    bContinueOnError = TRUE
  )

  expect_s3_class(result, "workr_project_summary")
  expect_equal(result$failures$phase, "1_failing_source")
  expect_equal(result$failures$workflow, "phase_bad")
  expect_match(result$failures$message, "phase boom")
  expect_equal(length(result$results$`1_failing_source`$results), 0)
  expect_true("2_capture" %in% names(result$results))
  expect_equal(result$results$`2_capture`$results$phase_capture$seed, "initial")
})

test_that("RunProject supports phase-scoped and project-scoped hooks (#17)", {
  capture_data <- function(lData) lData
  assign("capture_data", capture_data, envir = globalenv())
  on.exit(rm("capture_data", envir = globalenv()), add = TRUE)

  project_path <- file.path(tempdir(), "project_hook_scope_test")
  unlink(project_path, recursive = TRUE)
  on.exit(unlink(project_path, recursive = TRUE), add = TRUE)

  write_project_workflow(
    project_path,
    phase = "1_source",
    id = "source",
    step_name = "capture_data",
    output = "captured",
    params = list(lData = "lData")
  )
  write_project_workflow(
    project_path,
    phase = "2_capture",
    id = "capture",
    step_name = "capture_data",
    output = "captured",
    params = list(lData = "lData")
  )

  project_load_count <- 0
  project_save_count <- 0
  phase_save_count <- 0
  phase_load_count <- 0
  lConfig <- list(
    project = list(
      LoadData = function(lConfig, lData) {
        project_load_count <<- project_load_count + 1
        c(lData, list(project_seed = "loaded"))
      },
      SaveData = function(lProject, lConfig) {
        project_save_count <<- project_save_count + 1
      }
    ),
    phases = list(
      `1_source` = list(
        SaveData = function(lWorkflow, lConfig) {
          phase_save_count <<- phase_save_count + 1
        }
      ),
      `2_capture` = list(
        LoadData = function(lWorkflow, lConfig, lData) {
          phase_load_count <<- phase_load_count + 1
          c(lData, list(phase_loaded = TRUE))
        }
      )
    )
  )

  result <- RunProject(project_path, lData = list(seed = "initial"), lConfig = lConfig)

  expect_equal(project_load_count, 1)
  expect_equal(project_save_count, 1)
  expect_equal(phase_save_count, 1)
  expect_equal(phase_load_count, 1)
  expect_equal(result$`1_source`$phase_source$project_seed, "loaded")
  expect_true(isTRUE(result$`2_capture`$phase_capture$phase_loaded))
})
