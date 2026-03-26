test_that("RunStep resolves parameters", {
  assign("sum_step", function(lData, y) lData$value + y, envir = .GlobalEnv)
  on.exit(rm("sum_step", envir = .GlobalEnv), add = TRUE)
  lStep <- list(name = "sum_step", output = "result", params = list(lData = "lData", y = "value"))
  lData <- list(value = 2)
  result <- RunStep(lStep = lStep, lData = lData, lMeta = list())
  expect_equal(result, 4)
})

test_that("RunWorkflow returns final result", {
  assign("sum_step", function(lData, y) lData$value + y, envir = .GlobalEnv)
  on.exit(rm("sum_step", envir = .GlobalEnv), add = TRUE)
  lWorkflow <- list(
    meta = list(Type = "demo", ID = "001"),
    steps = list(
      list(name = "sum_step", output = "result", params = list(lData = "lData", y = "value"))
    )
  )
  lData <- list(value = 2)
  result <- RunWorkflow(lWorkflow, lData)
  expect_equal(result, 4)
})

test_that("RunWorkflows returns named list", {
  assign("sum_step", function(lData, y) lData$value + y, envir = .GlobalEnv)
  on.exit(rm("sum_step", envir = .GlobalEnv), add = TRUE)
  lWorkflows <- list(
    list(
      meta = list(Type = "demo", ID = "001"),
      steps = list(
        list(name = "sum_step", output = "result", params = list(lData = "lData", y = "value"))
      )
    )
  )
  lData <- list(value = 2)
  results <- RunWorkflows(lWorkflows, lData)
  expect_named(results, "demo_001")
  expect_equal(results[["demo_001"]], 4)
})

test_that("Example workflows run as expected", {
  skip_if_not_installed("yaml")
  assign("sum_step", function(lData, y) lData$value + y, envir = .GlobalEnv)
  on.exit(rm("sum_step", envir = .GlobalEnv), add = TRUE)

  lData <- list(value = 2, cars = cars)

  hw <- yaml::read_yaml(testthat::test_path("workflows", "00_Example", "helloworld.yaml"))
  ts <- yaml::read_yaml(testthat::test_path("workflows", "00_Example", "two_steps.yaml"))
  carswf <- yaml::read_yaml(testthat::test_path("workflows", "00_Example", "cars.yaml"))

  expect_equal(RunWorkflow(hw, lData), 4)
  expect_equal(RunWorkflow(ts, lData), 4)

  model <- RunWorkflow(carswf, lData)
  expect_s3_class(model, "lm")
  expect_equal(
    unname(coef(model)),
    c(-17.579095, 3.932409),
    tolerance = 1e-6
  )
})
