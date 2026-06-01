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

test_that("ListWorkflows returns named character vector of yaml paths (#53)", {
  result <- ListWorkflows(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active")
  )
  expect_type(result, "character")
  expect_true(all(grepl("\\.yaml$", result)))
  expect_true(all(file.exists(result)))
  expect_true(all(grepl("\\.yaml$", names(result))))
})

test_that("ListWorkflows resolves strPackage (#53)", {
  result <- ListWorkflows(strPath = "workflow", strPackage = "workr")
  expect_type(result, "character")
  expect_true(length(result) > 0)
  expect_true(all(file.exists(result)))
})

test_that("ListWorkflows errors on invalid strPath (#53)", {
  ListWorkflows(strPath = "nonexistent_path_xyz") |>
    expect_error("strPath")
})

test_that("ListWorkflows bRecursive = FALSE only returns top-level files (#53)", {
  result_recursive <- ListWorkflows(
    strPath = test_path("_fixtures", "workflow", "normal"),
    bRecursive = TRUE
  )
  result_flat <- ListWorkflows(
    strPath = test_path("_fixtures", "workflow", "normal"),
    bRecursive = FALSE
  )
  expect_true(length(result_recursive) >= length(result_flat))
})

test_that("ListWorkflowNames returns AsIs character vector without .yaml (#53)", {
  result <- ListWorkflowNames(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active")
  )
  expect_type(result, "character")
  expect_s3_class(result, "AsIs")
  expect_false(any(grepl("\\.yaml$", result)))
})

test_that("ListWorkflowNames includes all workflows regardless of Active (#53)", {
  result <- ListWorkflowNames(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active")
  )
  expect_true("active_metric" %in% result)
  expect_true("inactive_metric" %in% result)
  expect_true("no_active_field" %in% result)
})

test_that("ListWorkflowNames resolves strPackage (#53)", {
  result <- ListWorkflowNames(strPath = "workflow", strPackage = "workr")
  expect_type(result, "character")
  expect_true(length(result) > 0)
})
