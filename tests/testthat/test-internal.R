# Tests for the internal helpers in R/internal.R.

# --- GetStrFunctionIfNamespaced ------------------------------------------

test_that("GetStrFunctionIfNamespaced rejects non-string input", {
  expect_error(
    GetStrFunctionIfNamespaced(1),
    "must be a single character string"
  )
  expect_error(
    GetStrFunctionIfNamespaced(c("a", "b")),
    "must be a single character string"
  )
})

test_that("GetStrFunctionIfNamespaced resolves namespaced names", {
  expect_identical(GetStrFunctionIfNamespaced("utils::head"), utils::head)
})

test_that("GetStrFunctionIfNamespaced rejects malformed namespaced names", {
  # "a::b::c" splits into three parts, "a::" into one.
  expect_error(
    GetStrFunctionIfNamespaced("utils::head::extra"),
    "Invalid namespaced function string"
  )
  expect_error(
    GetStrFunctionIfNamespaced("utils::"),
    "Invalid namespaced function string"
  )
})

test_that("GetStrFunctionIfNamespaced prefers a global binding", {
  fn <- function() "from_global"
  assign("workr_test_global_fn", fn, envir = .GlobalEnv)
  withr::defer(rm("workr_test_global_fn", envir = .GlobalEnv))

  expect_identical(GetStrFunctionIfNamespaced("workr_test_global_fn"), fn)
})

test_that("GetStrFunctionIfNamespaced finds a caller-local binding", {
  local_fn <- function() "from_caller"
  expect_identical(GetStrFunctionIfNamespaced("local_fn"), local_fn)
})

test_that("GetStrFunctionIfNamespaced falls back to the workr namespace", {
  # Call from an environment isolated from both the global env and the workr
  # namespace, so the earlier `exists()` branches cannot match.
  isolated <- new.env(parent = baseenv())
  isolated$GetStrFunctionIfNamespaced <- GetStrFunctionIfNamespaced

  expect_identical(
    evalq(GetStrFunctionIfNamespaced("stop_if"), isolated),
    stop_if
  )

  # The namespace search inherits through base and the attached search path,
  # so attached-package functions resolve unqualified as well.
  expect_identical(
    evalq(GetStrFunctionIfNamespaced("read.csv"), isolated),
    utils::read.csv
  )
})

test_that("GetStrFunctionIfNamespaced errors when the name is unresolvable", {
  expect_error(
    GetStrFunctionIfNamespaced("workr_no_such_function_anywhere"),
    "not found"
  )
})

# --- CheckSpec early exits ------------------------------------------------

test_that("CheckSpec is a no-op when either side is absent", {
  expect_identical(CheckSpec(NULL, list(d = list())), list())
  expect_identical(CheckSpec(list(d = data.frame(a = 1)), NULL), list())
})

test_that("CheckSpec is a no-op for an empty or non-list spec", {
  expect_identical(CheckSpec(list(d = data.frame(a = 1)), list()), list())
  expect_identical(CheckSpec(list(d = data.frame(a = 1)), "not-a-list"), list())
})

# --- stop_if --------------------------------------------------------------

test_that("stop_if only stops on TRUE and interpolates from the caller", {
  expect_true(stop_if(FALSE, "never seen"))
  expect_true(stop_if(NA, "never seen"))

  f <- function() {
    what <- "widget"
    stop_if(TRUE, "Bad {what}.")
  }
  expect_error(f(), "Bad widget.")
})

# --- %||% -----------------------------------------------------------------

test_that("%||% returns the left side unless it is NULL", {
  expect_identical(1 %||% 2, 1)
  expect_identical(NULL %||% 2, 2)
})

# --- LogMessage / appender ------------------------------------------------

test_that("LogMessage formats and routes through appender()", {
  expect_message(LogMessage("info", "hello"), "\\[INFO\\] hello")

  what <- "world"
  expect_message(LogMessage("warn", "hello {what}"), "\\[WARN\\] hello world")
})

test_that("LogMessage accepts cli_detail", {
  expect_message(
    LogMessage("info", "hello", cli_detail = "extra"),
    "\\[INFO\\] hello"
  )
})

# --- .SpecDialect ---------------------------------------------------------

test_that(".SpecDialect classifies each supported shape (#91)", {
  expect_identical(.SpecDialect("spec.yaml", "d"), "pointblank_file")
  expect_identical(.SpecDialect(list(steps = list()), "d"), "pointblank_inline")
  expect_identical(.SpecDialect(list(required_cols = "a"), "d"), "legacy")
  expect_identical(.SpecDialect(list(), "d"), "legacy")
})

test_that(".SpecDialect errors rather than degrading to legacy (#91)", {
  # An unnamed, non-empty list matches no dialect: erroring here prevents a
  # malformed pointblank spec from silently becoming "no validation".
  expect_error(.SpecDialect(list(1, 2), "d"), "Unrecognized spec format")
  expect_error(.SpecDialect(1L, "d"), "Unrecognized spec format")
  expect_error(.SpecDialect(c("a", "b"), "d"), "Unrecognized spec format")
})

# --- .ResolveSpecPath -----------------------------------------------------

test_that(".ResolveSpecPath resolves relative to the workflow file (#91)", {
  dir <- withr::local_tempdir()
  spec_path <- file.path(dir, "DM_spec.yaml")
  writeLines("steps: []", spec_path)

  expect_identical(
    normalizePath(
      .ResolveSpecPath("DM_spec.yaml", "DM", file.path(dir, "DM.yaml")),
      winslash = "/"
    ),
    normalizePath(spec_path, winslash = "/")
  )
  # An existing path is used as-is, ignoring strPath.
  expect_identical(
    .ResolveSpecPath(spec_path, "DM", "elsewhere/DM.yaml"),
    spec_path
  )
})

test_that(".ResolveSpecPath errors on a missing spec file (#91)", {
  expect_error(
    .ResolveSpecPath("nope.yaml", "DM", NULL),
    "Spec file for domain 'DM' not found: nope.yaml"
  )
})

# --- .LoadSpec ------------------------------------------------------------

test_that(".LoadSpec reads files and passes inline specs through (#91)", {
  dir <- withr::local_tempdir()
  spec_path <- file.path(dir, "DM_spec.yaml")
  writeLines(c("tbl_name: dm", "steps:", "  - rows_distinct"), spec_path)

  expect_identical(
    .LoadSpec(spec_path, "pointblank_file", "DM"),
    list(tbl_name = "dm", steps = "rows_distinct")
  )

  inline <- list(steps = list("rows_distinct"))
  expect_identical(.LoadSpec(inline, "pointblank_inline", "DM"), inline)
})

# --- .EnforceSpecResult ---------------------------------------------------

make_result <- function(level) {
  list(
    domain = "DM",
    dialect = "pointblank",
    level = level,
    passed = level == "pass",
    n_steps = 3L,
    n_failed_steps = 1L,
    failed_steps = "col_vals_not_null"
  )
}

test_that(".EnforceSpecResult aborts on error and critical (#91)", {
  expect_error(
    .EnforceSpecResult(make_result("error")),
    "Spec validation failed for 'DM' at level 'error': 1 of 3 step\\(s\\) failed"
  )
  expect_error(
    .EnforceSpecResult(make_result("critical")),
    "at level 'critical'"
  )
})

test_that(".EnforceSpecResult logs but continues on warning (#91)", {
  expect_message(
    .EnforceSpecResult(make_result("warning")),
    "Spec validation warning for 'DM': 1 of 3 step\\(s\\) failed."
  )
})

test_that(".EnforceSpecResult is silent on pass and returns the result (#91)", {
  result <- make_result("pass")
  expect_silent(out <- .EnforceSpecResult(result))
  expect_identical(out, result)
})

# --- .CheckSpecLegacy -----------------------------------------------------

test_that(".CheckSpecLegacy accepts each historical required-columns key (#91)", {
  data <- data.frame(a = 1, b = 2)

  for (key in c("required_cols", "required", "columns")) {
    spec <- stats::setNames(list(c("a", "b")), key)
    expect_identical(.CheckSpecLegacy(data, spec, "d")$n_steps, 2L)
  }
})

test_that(".CheckSpecLegacy tolerates a spec with no required columns (#91)", {
  result <- .CheckSpecLegacy(
    data.frame(a = 1),
    list(a = list(type = "numeric")),
    "d"
  )

  expect_true(result$passed)
  expect_identical(result$n_steps, 0L)
  expect_identical(result$dialect, "legacy")
})

# --- `_all` wildcard ------------------------------------------------------

test_that(".SpecWildcardRequired detects only an explicit required wildcard", {
  expect_true(.SpecWildcardRequired(list(`_all` = list(required = TRUE))))

  expect_false(.SpecWildcardRequired(list(`_all` = list(required = FALSE))))
  expect_false(.SpecWildcardRequired(list(`_all` = list())))
  expect_false(.SpecWildcardRequired(list(required_cols = "a")))
  expect_false(.SpecWildcardRequired("a-path.yaml"))
})

test_that("`_all` passes for any non-empty table regardless of shape", {
  # The wildcard names no columns, so it deliberately claims nothing about
  # them -- including nullability. Two unrelated tables both satisfy it.
  spec <- list(`_all` = list(required = TRUE))

  expect_true(.CheckSpecLegacy(data.frame(a = 1, b = "x"), spec, "d")$passed)
  expect_true(
    .CheckSpecLegacy(data.frame(z = c(NA, 2)), spec, "d")$passed
  )
})

test_that("`_all` rejects an empty table", {
  spec <- list(`_all` = list(required = TRUE))

  expect_error(
    .CheckSpecLegacy(data.frame(a = integer(0)), spec, "d"),
    "Required input 'd' is empty."
  )
  expect_error(
    .CheckSpecLegacy(data.frame(), spec, "d"),
    "Required input 'd' is empty."
  )
})

test_that("`_all` is counted as a validation step", {
  # n_steps distinguishes a wildcard that ran from a spec that checked nothing.
  spec <- list(`_all` = list(required = TRUE))
  expect_identical(.CheckSpecLegacy(data.frame(a = 1), spec, "d")$n_steps, 1L)

  expect_identical(
    .CheckSpecLegacy(data.frame(a = 1), list(a = list(type = "numeric")), "d")$n_steps,
    0L
  )
})

test_that("`_all` combines with an explicit required column list", {
  spec <- list(`_all` = list(required = TRUE), required_cols = c("a", "b"))

  expect_identical(
    .CheckSpecLegacy(data.frame(a = 1, b = 2), spec, "d")$n_steps,
    3L
  )
  expect_error(
    .CheckSpecLegacy(data.frame(a = 1), spec, "d"),
    "Missing required columns"
  )
})

test_that("`_all` reaches CheckSpec through the legacy dispatch path", {
  expect_error(
    CheckSpec(
      list(d = data.frame(a = integer(0))),
      list(d = list(`_all` = list(required = TRUE)))
    ),
    "Required input 'd' is empty."
  )
  expect_silent(
    CheckSpec(
      list(d = data.frame(a = 1)),
      list(d = list(`_all` = list(required = TRUE)))
    )
  )
})
