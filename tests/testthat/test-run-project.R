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
