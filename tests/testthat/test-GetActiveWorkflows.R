test_that(".workflow_path resolves package path (#53)", {
  path <- .workflow_path("workflow", "workr")
  expect_true(dir.exists(path))
  expect_true(grepl("workr", path, fixed = TRUE))
})

test_that(".workflow_path errors on missing directory (#53)", {
  .workflow_path("nonexistent_xyz", NULL) |>
    expect_error("strPath")
})

test_that(".discover_yaml_files returns named character vector (#53)", {
  path <- test_path("_fixtures", "workflow", "normal", "01_Active")
  result <- .discover_yaml_files(path, bRecursive = TRUE)

  expect_type(result, "character")
  expect_true(all(grepl("\\.yaml$", result)))
  expect_true(all(grepl("\\.yaml$", names(result))))
  # names should be bare filenames, not paths
  expect_false(any(grepl("/", names(result), fixed = TRUE)))
})

test_that(".filter_yaml_files NULL strNames returns all (#53)", {
  path <- test_path("_fixtures", "workflow", "normal", "01_Active")
  yaml_files <- .discover_yaml_files(path, bRecursive = TRUE)
  result <- .filter_yaml_files(
    yaml_files,
    strNames = NULL,
    bExact = FALSE
  )

  expect_equal(result, yaml_files)
})

test_that(".filter_yaml_files exact match works (#53)", {
  path <- test_path("_fixtures", "workflow", "normal", "01_Active")
  yaml_files <- .discover_yaml_files(path, bRecursive = TRUE)
  result <- .filter_yaml_files(
    yaml_files,
    strNames = "active_metric",
    bExact = TRUE
  )

  expect_equal(names(result), "active_metric.yaml")
})

test_that(".filter_yaml_files partial match works (#53)", {
  path <- test_path("_fixtures", "workflow", "normal", "01_Active")
  yaml_files <- .discover_yaml_files(path, bRecursive = TRUE)
  result <- .filter_yaml_files(
    yaml_files,
    strNames = "metric",
    bExact = FALSE
  )

  expect_true(all(grepl("metric", names(result))))
})

## Tests for GetActiveWorkflows() — see #53

test_that("GetActiveWorkflows includes workflow with MetricActive: true (#53)", {
  result <- GetActiveWorkflows(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active")
  )

  expect_true("active_metric" %in% result)
})

test_that("GetActiveWorkflows excludes workflow with MetricActive: false (#53)", {
  result <- GetActiveWorkflows(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active")
  )

  expect_false("inactive_metric" %in% result)
})

test_that("GetActiveWorkflows includes workflow with no MetricActive field (#53)", {
  result <- GetActiveWorkflows(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active")
  )

  expect_true("no_active_field" %in% result)
})

test_that("GetActiveWorkflows returns character vector (#53)", {
  result <- GetActiveWorkflows(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active")
  )

  expect_type(result, "character")
})

test_that("GetActiveWorkflows errors on invalid strPath (#53)", {
  GetActiveWorkflows(strPath = "nonexistent_path_xyz") |>
    expect_error("strPath")
})

test_that("GetActiveWorkflows respects strNames filter (#53)", {
  result <- GetActiveWorkflows(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active"),
    strNames = "active_metric",
    bExact = TRUE
  )

  expect_equal(as.character(result), "active_metric")
})

test_that("GetActiveWorkflows with strPackage loads from package (#53)", {
  result <- GetActiveWorkflows(
    strPath = "workflow",
    strPackage = "workr"
  )

  expect_type(result, "character")
  expect_true(length(result) > 0)
})
