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

test_that("RunWorkflow invokes environment-backed lConfig$LoadData (#58)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  load_called <- FALSE
  lConfig <- new.env(parent = emptyenv())
  lConfig$LoadData <- function(lWorkflow, lConfig, lData) {
    load_called <<- TRUE
    c(lData, list(loaded_val = 42))
  }

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "config_env_test"),
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

test_that("RunWorkflow accepts lConfig without data hooks (#58)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "optional_hooks"),
    steps = list(
      list(name = "identity_step", output = "res", params = list(x = "val"))
    )
  )

  suppressMessages({
    result <- RunWorkflow(lWorkflow, lData = list(val = 11), lConfig = list(foo = "bar"))
  })

  expect_equal(result, 11)
})

test_that("RunWorkflow allows LoadData-only and SaveData-only configs (#17)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "hook_subset"),
    steps = list(
      list(name = "identity_step", output = "res", params = list(x = "val"))
    )
  )

  save_called <- FALSE
  suppressMessages({
    result <- RunWorkflow(
      lWorkflow,
      lData = list(val = 1),
      lConfig = list(SaveData = function(lWorkflow, lConfig) save_called <<- TRUE)
    )
  })
  expect_equal(result, 1)
  expect_true(save_called)

  suppressMessages({
    result <- RunWorkflow(
      lWorkflow,
      lData = list(),
      lConfig = list(LoadData = function(lWorkflow, lConfig, lData) list(val = 2))
    )
  })
  expect_equal(result, 2)
})

test_that("RunWorkflow resolves registered load providers (#58)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  register_load_provider(
    "test.load.provider",
    function(lWorkflow, lConfig, lData) {
      c(lData, list(loaded_val = 42))
    }
  )

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "registered_load"),
    steps = list(
      list(
        name = "identity_step",
        output = "res",
        params = list(x = "loaded_val")
      )
    )
  )

  suppressMessages({
    result <- RunWorkflow(
      lWorkflow,
      lData = list(),
      lConfig = list(LoadData = "test.load.provider")
    )
  })

  expect_equal(result, 42)
})

test_that("RunWorkflow resolves registered save providers (#58)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  save_called <- FALSE
  register_save_provider(
    "test.save.provider",
    function(lWorkflow, lConfig) {
      save_called <<- TRUE
    }
  )

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "registered_save"),
    steps = list(
      list(name = "identity_step", output = "res", params = list(x = "val"))
    )
  )

  suppressMessages({
    RunWorkflow(
      lWorkflow,
      lData = list(val = 99),
      lConfig = list(SaveData = "test.save.provider")
    )
  })

  expect_true(save_called)
})

test_that("RunWorkflow errors on unknown registered load provider (#58)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  register_load_provider(
    "known.load.provider",
    function(lWorkflow, lConfig, lData) lData
  )

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "unknown_provider"),
    steps = list(
      list(name = "identity_step", output = "res", params = list(x = "val"))
    )
  )

  expect_error(
    suppressMessages({
      RunWorkflow(
        lWorkflow,
        lData = list(val = 1),
        lConfig = list(LoadData = "missing.load.provider")
      )
    }),
    regexp = "Unknown load provider \"missing\\.load\\.provider\"\\.[[:space:]]+Registered providers:"
  )
})

test_that("RunWorkflow errors on invalid LoadData formals (#58)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "bad_load_formals"),
    steps = list(
      list(name = "identity_step", output = "res", params = list(x = "val"))
    )
  )

  expect_error(
    suppressMessages({
      RunWorkflow(
        lWorkflow,
        lData = list(val = 1),
        lConfig = list(
          LoadData = function(study, seed) {
            list(val = study + seed)
          }
        )
      )
    }),
    regexp = "`lConfig\\$LoadData` must accept formals \\(lWorkflow, lConfig, lData\\)"
  )
})

test_that("RunWorkflow errors on invalid SaveData formals (#58)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "bad_save_formals"),
    steps = list(
      list(name = "identity_step", output = "res", params = list(x = "val"))
    )
  )

  expect_error(
    suppressMessages({
      RunWorkflow(
        lWorkflow,
        lData = list(val = 1),
        lConfig = list(
          SaveData = function(study, seed) {
            invisible(NULL)
          }
        )
      )
    }),
    regexp = "`lConfig\\$SaveData` must accept formals \\(lWorkflow, lConfig\\)"
  )
})

test_that("register_load_provider validates provider signatures (#58)", {
  expect_error(
    register_load_provider(
      "bad.load.provider",
      function(study, seed) list()
    ),
    regexp = "Registered load provider \"bad\\.load\\.provider\" must accept formals \\(lWorkflow, lConfig, lData\\)"
  )
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

test_that("RunWorkflow fails when spec-declared input is absent (#9)", {
  lWorkflow <- list(
    meta = list(Type = "demo", ID = "missing_spec_input"),
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

  suppressMessages(RunWorkflow(lWorkflow, lData = list())) |>
    expect_error("Spec-declared input 'my_domain' not found in lData")
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

test_that("RunWorkflows continue-on-error records failures and runs later workflows (#11)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  assign("fail_step", function(x) stop("boom"), envir = .GlobalEnv)
  on.exit(
    {
      rm("identity_step", envir = .GlobalEnv)
      rm("fail_step", envir = .GlobalEnv)
    },
    add = TRUE
  )

  lWorkflows <- list(
    list(
      meta = list(Type = "demo", ID = "ok"),
      steps = list(
        list(name = "identity_step", output = "res", params = list(x = "val"))
      )
    ),
    list(
      meta = list(Type = "demo", ID = "bad"),
      steps = list(
        list(name = "fail_step", output = "res", params = list(x = "val"))
      )
    ),
    list(
      meta = list(Type = "demo", ID = "after"),
      steps = list(
        list(name = "identity_step", output = "res", params = list(x = "val"))
      )
    )
  )

  suppressMessages({
    result <- RunWorkflows(lWorkflows, list(val = 1), bContinueOnError = TRUE)
  })

  expect_s3_class(result, "workr_run_summary")
  expect_named(result$results, c("demo_ok", "demo_after"))
  expect_equal(result$status$status, c("success", "error", "success"))
  expect_equal(result$failures$workflow, "demo_bad")
  expect_match(result$failures$message, "boom")
})
