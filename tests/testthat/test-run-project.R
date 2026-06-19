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
  dir.create(
    file.path(proj, "1_populated"),
    recursive = TRUE,
    showWarnings = FALSE
  )
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

test_that("RunProject validates per-phase _config.yaml schema (#64)", {
  project_path <- withr::local_tempdir("project_config_schema_test")
  write_project_workflow(project_path, phase = "1_phase", id = "capture")
  write_phase_config(
    project_path,
    "1_phase",
    c(
      "input:",
      "  unexpected: true"
    )
  )

  expect_error(
    RunProject(project_path, lData = list(value = 1)),
    "Phase '1_phase'.*unknown input key.*unexpected"
  )
})

test_that("RunProject rejects empty or whitespace-only output config strings (#64)", {
  project_path <- withr::local_tempdir("project_config_empty_string_test")
  write_project_workflow(project_path, phase = "1_phase", id = "capture")
  write_phase_config(
    project_path,
    "1_phase",
    c(
      "output:",
      "  wrap_as: '   '"
    )
  )

  expect_error(
    RunProject(project_path, lData = list(value = 1)),
    "Phase '1_phase'.*output.wrap_as must be a non-empty string"
  )

  write_phase_config(
    project_path,
    "1_phase",
    c(
      "output:",
      "  transform: ''"
    )
  )

  expect_error(
    RunProject(project_path, lData = list(value = 1)),
    "Phase '1_phase'.*output.transform must be a non-empty string"
  )
})

test_that("RunProject assembles phase input from config rules (#65)", {
  project_path <- withr::local_tempdir("project_config_input_test")
  write_project_workflow(project_path, phase = "1_source", id = "p1")
  write_project_workflow(project_path, phase = "2_source", id = "p2")
  write_project_workflow(
    project_path,
    phase = "3_capture",
    id = "capture",
    params = list(x = "lData")
  )

  write_phase_config(
    project_path,
    "3_capture",
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
    )
  )

  result <- RunProject(project_path, lData = list(seed = "initial"))
  captured <- result$`3_capture`$phase_capture

  expect_equal(captured$seed, "initial")
  expect_equal(captured$phase_p1, "extra_wins")
  expect_false("phase_p2" %in% names(captured))
  expect_equal(captured$aliased_p2$phase_p2, "p2")
  expect_equal(names(captured$lWorkflows), "p2")
  expect_equal(captured$literal_date, "Sys.Date()")
})

test_that("RunProject wraps and transforms phase output (#66)", {
  project_path <- withr::local_tempdir("project_config_output_test")
  write_project_workflow(project_path, phase = "1_source", id = "p1")
  write_project_workflow(
    project_path,
    phase = "2_capture",
    id = "capture",
    params = list(x = "lData")
  )

  write_phase_config(
    project_path,
    "1_source",
    c(
      "output:",
      "  wrap_as: wrapped",
      "  transform: base::unlist"
    )
  )
  write_phase_config(
    project_path,
    "2_capture",
    c(
      "input:",
      "  from_phases: [1_source]"
    )
  )

  result <- RunProject(project_path)
  captured <- result$`2_capture`$phase_capture

  expect_named(result$`1_source`, "wrapped")
  expect_equal(captured$wrapped, c(phase_p1 = "p1"))
  expect_false("phase_p1" %in% names(captured))
})

test_that("RunProject transform failures identify the transform reference (#66)", {
  bad_transform <- function(result) stop("boom")

  project_path <- withr::local_tempdir("project_config_transform_failure_test")
  write_project_workflow(project_path, phase = "1_source", id = "p1")
  write_phase_config(
    project_path,
    "1_source",
    c(
      "output:",
      "  transform: bad_transform"
    )
  )

  expect_error(
    RunProject(project_path),
    "output.transform 'bad_transform' failed: boom"
  )
})
