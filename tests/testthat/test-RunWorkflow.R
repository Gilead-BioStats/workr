## Expanded RunWorkflow and RunWorkflows tests — see (#26)

# --- RunWorkflow ---

test_that("RunWorkflow returns final step result by default (#26)", {
  assign("sum_step", function(lData, y) lData$value + y, envir = .GlobalEnv)
  on.exit(rm("sum_step", envir = .GlobalEnv), add = TRUE)

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "001"),
    steps = list(
      list(
        name = "sum_step",
        output = "result",
        params = list(lData = "lData", y = "value")
      )
    )
  )
  lData <- list(value = 2)

  suppressMessages({
    result <- RunWorkflow(lWorkflow, lData)
  })
  expect_equal(result, 4)
})

test_that("RunWorkflow returns full workflow object when bReturnResult = FALSE (#26)", {
  assign("sum_step", function(lData, y) lData$value + y, envir = .GlobalEnv)
  on.exit(rm("sum_step", envir = .GlobalEnv), add = TRUE)

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "002"),
    steps = list(
      list(
        name = "sum_step",
        output = "result",
        params = list(lData = "lData", y = "value")
      )
    )
  )
  lData <- list(value = 3)

  suppressMessages({
    result <- RunWorkflow(lWorkflow, lData, bReturnResult = FALSE)
  })

  expect_true(is.list(result))
  expect_true("lData" %in% names(result))
  expect_true("lResult" %in% names(result))
  expect_true("result" %in% names(result$lData))
  expect_equal(result$lResult, 6)
})

test_that("RunWorkflow bKeepInputData = FALSE removes input data from lData (#26)", {
  assign("sum_step", function(lData, y) lData$value + y, envir = .GlobalEnv)
  on.exit(rm("sum_step", envir = .GlobalEnv), add = TRUE)

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "003"),
    steps = list(
      list(
        name = "sum_step",
        output = "result",
        params = list(lData = "lData", y = "value")
      )
    )
  )
  lData <- list(value = 5, extra = "should_be_removed")

  suppressMessages({
    result <- RunWorkflow(
      lWorkflow,
      lData,
      bReturnResult = FALSE,
      bKeepInputData = FALSE
    )
  })

  expect_equal(names(result$lData), "result")
  expect_false("value" %in% names(result$lData))
  expect_false("extra" %in% names(result$lData))
})

test_that("RunWorkflow bKeepInputData = TRUE preserves input data in lData (#26)", {
  assign("sum_step", function(lData, y) lData$value + y, envir = .GlobalEnv)
  on.exit(rm("sum_step", envir = .GlobalEnv), add = TRUE)

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "004"),
    steps = list(
      list(
        name = "sum_step",
        output = "result",
        params = list(lData = "lData", y = "value")
      )
    )
  )
  lData <- list(value = 5, extra = "should_persist")

  suppressMessages({
    result <- RunWorkflow(
      lWorkflow,
      lData,
      bReturnResult = FALSE,
      bKeepInputData = TRUE
    )
  })

  expect_true("value" %in% names(result$lData))
  expect_true("extra" %in% names(result$lData))
  expect_true("result" %in% names(result$lData))
})

test_that("RunWorkflow multi-step preserves intermediate results in lData (#26)", {
  assign("add_one", function(x) x + 1, envir = .GlobalEnv)
  assign("add_two", function(x) x + 2, envir = .GlobalEnv)
  on.exit(
    {
      rm("add_one", envir = .GlobalEnv)
      rm("add_two", envir = .GlobalEnv)
    },
    add = TRUE
  )

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "multi"),
    steps = list(
      list(name = "add_one", output = "step1", params = list(x = "val")),
      list(name = "add_two", output = "step2", params = list(x = "step1"))
    )
  )
  lData <- list(val = 10)

  suppressMessages({
    result <- RunWorkflow(lWorkflow, lData, bReturnResult = FALSE)
  })

  expect_equal(result$lData$step1, 11)
  expect_equal(result$lData$step2, 13)
  expect_equal(result$lResult, 13)
})

test_that("RunWorkflow invokes lConfig$LoadData (#26)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  load_called <- FALSE
  lConfig <- list(
    LoadData = function(lWorkflow, lConfig, lData) {
      load_called <<- TRUE
      c(lData, list(loaded_val = 42))
    }
  )

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "config_test"),
    steps = list(
      list(
        name = "identity_step",
        output = "res",
        params = list(x = "loaded_val")
      )
    )
  )

  suppressMessages({
    result <- RunWorkflow(lWorkflow, lData = list(), lConfig = lConfig)
  })

  expect_true(load_called)
  expect_equal(result, 42)
})

test_that("RunWorkflow invokes lConfig$SaveData on bReturnResult = TRUE (#26)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  save_called <- FALSE
  lConfig <- list(
    LoadData = function(lWorkflow, lConfig, lData) lData,
    SaveData = function(lWorkflow, lConfig) {
      save_called <<- TRUE
    }
  )

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "save_test"),
    steps = list(
      list(name = "identity_step", output = "res", params = list(x = "val"))
    )
  )

  suppressMessages({
    RunWorkflow(
      lWorkflow,
      lData = list(val = 99),
      lConfig = lConfig,
      bReturnResult = TRUE
    )
  })

  expect_true(save_called)
})

test_that("RunWorkflow validates spec when present (#26)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "spec_test"),
    spec = list(
      my_domain = list(required_cols = c("a", "b"))
    ),
    steps = list(
      list(
        name = "identity_step",
        output = "res",
        params = list(x = "my_domain")
      )
    )
  )

  # lData has the domain but missing a required column
  lData <- list(my_domain = data.frame(a = 1))

  suppressMessages(RunWorkflow(lWorkflow, lData)) |>
    expect_error("Missing required columns")
})

test_that("RunWorkflow runs without spec (#26)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "no_spec"),
    steps = list(
      list(name = "identity_step", output = "res", params = list(x = "val"))
    )
  )

  suppressMessages({
    result <- RunWorkflow(lWorkflow, list(val = "hello"))
  })
  expect_equal(result, "hello")
})

test_that("RunWorkflow runs with YAML files (#26)", {
  skip_if_not_installed("yaml")
  assign("sum_step", function(lData, y) lData$value + y, envir = .GlobalEnv)
  on.exit(rm("sum_step", envir = .GlobalEnv), add = TRUE)

  lData <- list(value = 2, cars = cars)

  hw <- yaml::read_yaml(testthat::test_path(
    "_fixtures",
    "workflow",
    "normal",
    "00_Example",
    "helloworld.yaml"
  ))
  ts <- yaml::read_yaml(testthat::test_path(
    "_fixtures",
    "workflow",
    "normal",
    "00_Example",
    "two_steps.yaml"
  ))
  carswf <- yaml::read_yaml(testthat::test_path(
    "_fixtures",
    "workflow",
    "normal",
    "00_Example",
    "cars.yaml"
  ))

  suppressMessages({
    expect_equal(RunWorkflow(hw, lData), 4)
    expect_equal(RunWorkflow(ts, lData), 4)

    model <- RunWorkflow(carswf, lData)
  })
  expect_s3_class(model, "lm")
  expect_equal(
    unname(coef(model)),
    c(-17.579095, 3.932409),
    tolerance = 1e-6
  )
})

# --- RunWorkflows ---

test_that("RunWorkflows returns named list (#26)", {
  assign("sum_step", function(lData, y) lData$value + y, envir = .GlobalEnv)
  on.exit(rm("sum_step", envir = .GlobalEnv), add = TRUE)

  lWorkflows <- list(
    list(
      meta = list(Type = "demo", ID = "001"),
      steps = list(
        list(
          name = "sum_step",
          output = "result",
          params = list(lData = "lData", y = "value")
        )
      )
    )
  )
  lData <- list(value = 2)

  suppressMessages({
    results <- RunWorkflows(lWorkflows, lData)
  })
  expect_named(results, "demo_001")
  expect_equal(results[["demo_001"]], 4)
})

test_that("RunWorkflows passes prior workflow results as data to later workflows (#26)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  assign("add_ten", function(res) res + 10, envir = .GlobalEnv)
  on.exit(
    {
      rm("identity_step", envir = .GlobalEnv)
      rm("add_ten", envir = .GlobalEnv)
    },
    add = TRUE
  )

  lWorkflows <- list(
    list(
      meta = list(Type = "demo", ID = "first"),
      steps = list(
        list(name = "identity_step", output = "res", params = list(x = "val"))
      )
    ),
    list(
      meta = list(Type = "demo", ID = "second"),
      steps = list(
        list(
          name = "add_ten",
          output = "final",
          params = list(res = "demo_first")
        )
      )
    )
  )
  lData <- list(val = 5)

  suppressMessages({
    results <- RunWorkflows(lWorkflows, lData, bReturnResult = TRUE)
  })

  # First workflow returns the identity result: 5
  expect_equal(results[["demo_first"]], 5)
  # Second workflow receives "demo_first" (= 5) from first workflow, adds 10
  expect_equal(results[["demo_second"]], 15)
})

test_that("RunWorkflows custom strResultNames (#26)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  lWorkflows <- list(
    list(
      meta = list(Type = "kri", ID = "ae", Version = "1.0"),
      steps = list(
        list(name = "identity_step", output = "res", params = list(x = "val"))
      )
    )
  )
  lData <- list(val = 42)

  suppressMessages({
    results <- RunWorkflows(
      lWorkflows,
      lData,
      strResultNames = c("Type", "ID", "Version")
    )
  })

  expect_named(results, "kri_ae_1.0")
})

test_that("RunWorkflows passes lConfig through to RunWorkflow (#26)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  load_count <- 0
  lConfig <- list(
    LoadData = function(lWorkflow, lConfig, lData) {
      load_count <<- load_count + 1
      lData
    }
  )

  lWorkflows <- list(
    list(
      meta = list(Type = "demo", ID = "a"),
      steps = list(
        list(name = "identity_step", output = "res", params = list(x = "val"))
      )
    ),
    list(
      meta = list(Type = "demo", ID = "b"),
      steps = list(
        list(name = "identity_step", output = "res", params = list(x = "val"))
      )
    )
  )
  lData <- list(val = 1)

  suppressMessages({
    RunWorkflows(lWorkflows, lData, lConfig = lConfig)
  })

  expect_equal(load_count, 2)
})

test_that("RunWorkflows handles empty workflow list (#26)", {
  suppressMessages({
    results <- RunWorkflows(list(), list(val = 1))
  })
  expect_equal(length(results), 0)
})
