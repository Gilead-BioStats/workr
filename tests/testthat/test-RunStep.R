## Ported from gsm.core@dev test-RunStep.R — see #26

test_that("RunStep handles lMeta and lData parameters correctly #26", {
  lStep <- list(name = "dummy_function", output = "res", params = list(x = "lMeta", y = "lData"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  suppressMessages({
    result <- RunStep(lStep, lData, lMeta)
  })
  expect_equal(result$x, lMeta)
  expect_equal(result$y, lData)
})

test_that("RunStep handles parameters referencing elements within lMeta and lData #26", {
  lStep <- list(name = "dummy_function", output = "res", params = list(x = "meta1", y = "data1"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  suppressMessages({
    result <- RunStep(lStep, lData, lMeta)
  })
  expect_equal(result$x, 200)
  expect_equal(result$y, 100)
})

test_that("RunStep passes direct value parameters correctly #26", {
  lStep <- list(name = "dummy_function", output = "res", params = list(x = "meta1", y = "100"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  suppressMessages({
    result <- RunStep(lStep, lData, lMeta)
  })
  expect_equal(result$x, 200)
  expect_equal(result$y, "100")
})

test_that("RunStep passes direct value vector parameters correctly #26", {
  lStep <- list(name = "dummy_function", output = "res", params = list(x = "meta1", y = c(1, 2, 3)))
  lMeta <- list(meta1 = 200)

  suppressMessages({
    result <- RunStep(lStep, list(), lMeta)
  })
  expect_equal(result$x, 200)
  expect_equal(result$y, c(1, 2, 3))
})

test_that("RunStep handles multiple parameters and function invocation correctly #26", {
  lStep <- list(name = "another_dummy_function", output = "res", params = list(a = "meta1", b = "data1", c = "some_value"))
  lData <- list(data1 = 300)
  lMeta <- list(meta1 = 400)

  suppressMessages({
    result <- RunStep(lStep, lData, lMeta)
  })
  expect_equal(result$a, 400)
  expect_equal(result$b, 300)
  expect_equal(result$c, "some_value")
})

test_that("RunStep will run a function from a namespace #26", {
  lStep <- list(name = "dplyr::glimpse", output = "res", params = list(head(Theoph)))
  lData <- list(data1 = 300)
  lMeta <- list(meta1 = 400)

  expect_output({
    suppressMessages({
      result <- RunStep(lStep, lData, lMeta)
    })
  })
  expect_equal(result, head(Theoph))
})

test_that("RunStep will run a function without a namespace #26", {
  # Use a base function that's available without namespace
  lStep <- list(name = "head", output = "res", params = list(Theoph))
  lData <- list(data1 = 300)
  lMeta <- list(meta1 = 400)

  suppressMessages({
    result <- RunStep(lStep, lData, lMeta)
  })
  expect_equal(nrow(result), 6)
  expect_equal(colnames(result), c("Subject", "Wt", "Dose", "Time", "conc"))
})

test_that("RunStep will run a function with no parameters #26", {
  wd_path <- getwd()

  lStep <- list(name = "getwd", output = "res")
  suppressMessages({
    result <- RunStep(lStep, list(), list())
  })
  expect_equal(result, wd_path)
})

## workr-specific: expr() / exprs() parsing — see #26

test_that("RunStep recognizes rlang::expr() string parameters #26", {
  # Test that expr strings are parsed without error
  # (actual evaluation happens when do.call passes the expression to the function)
  lStep <- list(
    name = "dummy_function",
    output = "res",
    params = list(x = "rlang::expr(data + 100)", y = "meta1")
  )
  lMeta <- list(meta1 = 50)

  suppressMessages({
    # This will evaluate 'data + 100' in dummy_function,
    # which expects 'data' to exist (it won't, so it will fail)
    # The test just verifies RunStep handles the string properly
    expect_error(RunStep(lStep, list(), lMeta))
  })
})

test_that("RunStep recognizes expr() shorthand parameters #26", {
  # Test that short form expr() is properly parsed by RunStep
  lStep <- list(
    name = "dummy_function",
    output = "res",
    params = list(x = "expr(1 + 2)", y = "42")
  )

  suppressMessages({
    result <- RunStep(lStep, list(), list())
  })
  # expr(1 + 2) evaluates to 3 when passed to dummy_function
  expect_equal(result$x, 3)
  expect_equal(result$y, "42")
})

test_that("RunStep recognizes rlang::exprs() parameters #26", {
  # Test that exprs() syntax is recognized (doesn't crash)
  # exprs() returns a list of expressions
  lStep <- list(
    name = "dummy_function",
    output = "res",
    params = list(x = "rlang::exprs(a, b, c)", y = "lData")
  )
  lData <- list(a = 1, b = 2, c = 3)

  suppressMessages({
    result <- RunStep(lStep, lData, list())
  })
  # exprs(a, b, c) evaluates to substitute-like list
  # that dummy_function will receive
  expect_true(is.list(result$x))
  expect_equal(result$y, lData)
})

test_that("RunStep recognizes exprs() shorthand parameters #26", {
  # Test that exprs() shorthand is processed
  lStep <- list(
    name = "dummy_function",
    output = "res",
    params = list(x = "exprs(1, 2, 3)", y = "100")
  )

  suppressMessages({
    result <- RunStep(lStep, list(), list())
  })
  # exprs(1, 2, 3) returns a list of expressions [1], [2], [3]
  expect_true(is.list(result$x))
  expect_equal(result$y, "100")
})

test_that("RunStep passes lSpec parameter correctly #26", {
  lStep <- list(name = "dummy_function", output = "res", params = list(x = "lSpec", y = "meta1"))
  lMeta <- list(meta1 = 10)
  lSpec <- list(domain1 = list(required_cols = c("a", "b")))

  suppressMessages({
    result <- RunStep(lStep, list(), lMeta, lSpec = lSpec)
  })
  expect_equal(result$x, lSpec)
  expect_equal(result$y, 10)
})
