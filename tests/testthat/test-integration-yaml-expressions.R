################################################################################
# Integration Tests: YAML Loading → MakeWorkflowList → RunStep Pipeline
# Issue #26: Verify that workflows can be loaded from YAML and executed
################################################################################

test_that("MakeWorkflowList loads YAML and RunStep executes workflow correctly #26", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("dplyr")
  
  # Create a temporary directory with a test workflow
  tmp_dir <- tempdir()
  tmp_workflow_dir <- file.path(tmp_dir, "test_workflows_integration")
  dir.create(tmp_workflow_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Write a simple workflow that pulls a column
  yaml_content <- "meta:
  ID: pull_x
  Type: Test
  Priority: 1
steps:
  - name: dplyr::pull
    output: values
    params:
      .data: df
      var: x
"
  
  yaml_file <- file.path(tmp_workflow_dir, "pull_x.yaml")
  writeLines(yaml_content, yaml_file)
  
  # Load the workflow with MakeWorkflowList
  workflows <- MakeWorkflowList(strPath = tmp_workflow_dir)
  
  # Verify workflow was loaded with structure intact
  expect_true("pull_x" %in% names(workflows))
  expect_true(!is.null(workflows$pull_x$steps))
  expect_equal(workflows$pull_x$meta$ID, "pull_x")
  expect_true("steps" %in% names(workflows$pull_x))
  
  # Execute the workflow step with RunStep
  df <- data.frame(x = 1:10, y = 11:20)
  lData <- list(df = df)
  lMeta <- workflows$pull_x$meta
  lSpec <- workflows$pull_x$spec %||% NULL
  lStep <- workflows$pull_x$steps[[1]]
  
  # RunStep should execute dplyr::pull to extract column x
  expect_no_error({
    suppressMessages({
      result <- RunStep(lStep, lData, lMeta, lSpec)
    })
  })
  
  # Verify result is the x column as a vector
  expect_true(is.vector(result))
  expect_equal(result, 1:10)
})

test_that("Complex workflow: multi-step loaded from YAML and executed end-to-end #26", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("dplyr")
  
  # Create a temporary directory with a multi-step workflow
  tmp_dir <- tempdir()
  tmp_workflow_dir <- file.path(tmp_dir, "test_workflows_multistep")
  dir.create(tmp_workflow_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Write a multi-step workflow
  # Step 1: Pull column x from df  
  # Step 2: Calculate mean of that vector
  yaml_content <- "meta:
  ID: mean_calc
  Type: Test
  Priority: 1
steps:
  - name: dplyr::pull
    output: values
    params:
      .data: df
      var: x
  - name: mean
    output: result
    params:
      x: values
      na.rm: true
"
  
  yaml_file <- file.path(tmp_workflow_dir, "mean_calc.yaml")
  writeLines(yaml_content, yaml_file)
  
  # Load the workflow
  workflows <- MakeWorkflowList(strPath = tmp_workflow_dir)
  expect_true("mean_calc" %in% names(workflows))
  expect_equal(workflows$mean_calc$meta$ID, "mean_calc")
  
  # Execute the workflow using RunWorkflow
  df <- data.frame(x = 1:10, y = 11:20)
  lData <- list(df = df)
  lConfig <- NULL
  
  expect_no_error({
    suppressMessages({
      result <- RunWorkflow(workflows$mean_calc, lData, lConfig)
    })
  })
  
  # Verify the final result is the mean of x (which is 5.5)
  expect_equal(result, 5.5)
})

test_that("Workflow from YAML loads and executes with meta reference #26", {
  skip_if_not_installed("yaml")
  
  # Create a temporary directory with a workflow
  tmp_dir <- tempdir()
  tmp_workflow_dir <- file.path(tmp_dir, "test_workflows_meta")
  dir.create(tmp_workflow_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Write a simple workflow with meta configuration
  yaml_content <- "meta:
  ID: simple_count
  Type: Test
  Priority: 1
  notes: test workflow
steps:
  - name: nrow
    output: result
    params:
      x: df
"
  
  yaml_file <- file.path(tmp_workflow_dir, "simple_count.yaml")
  writeLines(yaml_content, yaml_file)
  
  # Load the workflow
  workflows <- MakeWorkflowList(strPath = tmp_workflow_dir)
  expect_true("simple_count" %in% names(workflows))
  expect_equal(workflows$simple_count$meta$notes, "test workflow")
  
  # Execute the workflow  
  df <- data.frame(x = 1:10, y = 11:20)
  lData <- list(df = df)
  lConfig <- NULL
  
  expect_no_error({
    suppressMessages({
      result <- RunWorkflow(workflows$simple_count, lData, lConfig)
    })
  })
  
  # nrow of 10-row df should be 10
  expect_equal(result, 10)
})
