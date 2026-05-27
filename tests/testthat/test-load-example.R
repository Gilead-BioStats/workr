test_that("loadExample returns input data when initData.R is missing (#9, #26)", {
  wf <- list(path = tempfile(fileext = ".yaml"))
  lData <- list(x = 1)

  expect_equal(loadExample(wf, lData = lData), lData)
})

test_that("loadExample loads initData.R and merges with lData (#9, #26)", {
  td <- tempfile("workflow_dir_")
  dir.create(td, recursive = TRUE)

  init_path <- file.path(td, "initData.R")
  writeLines(
    c(
      "initData <- function() {",
      "  list(a = 1, b = 2)",
      "}"
    ),
    init_path
  )

  wf <- list(path = file.path(td, "example.yaml"))
  result <- loadExample(wf, lData = list(b = 99, c = 3))

  expect_equal(result$a, 1)
  expect_equal(result$b, 99)
  expect_equal(result$c, 3)
})

test_that("loadExample validates initData return type (#9, #26)", {
  td <- tempfile("workflow_dir_")
  dir.create(td, recursive = TRUE)

  init_path <- file.path(td, "initData.R")
  writeLines(
    c(
      "initData <- function() {",
      "  42",
      "}"
    ),
    init_path
  )

  wf <- list(path = file.path(td, "example.yaml"))
  expect_error(loadExample(wf, lData = list()), "must return a list")
})

test_that("loadExample does not create duplicate names on repeated calls (#9, #26)", {
  td <- tempfile("workflow_dir_")
  dir.create(td, recursive = TRUE)

  init_path <- file.path(td, "initData.R")
  writeLines(
    c(
      "initData <- function() {",
      "  list(df = datasets::cars)",
      "}"
    ),
    init_path
  )

  wf <- list(path = file.path(td, "example.yaml"))
  l1 <- loadExample(wf, lData = list())
  l2 <- loadExample(wf, lData = l1)

  expect_equal(anyDuplicated(names(l2)), 0)
  expect_true("df" %in% names(l2))
})
