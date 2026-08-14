# Tests for pointblank-style spec support (#91)

make_df <- function() {
  data.frame(
    STUDYID = c("S1", "S1", "S1"),
    USUBJID = c("A", "B", "C"),
    stringsAsFactors = FALSE
  )
}

# --- Backward compatibility: legacy dialect ------------------------------

test_that("legacy specs still validate on column existence (#91)", {
  expect_error(
    CheckSpec(
      list(d = data.frame(a = 1)),
      list(d = list(required_cols = c("a", "b")))
    ),
    "Missing required columns"
  )

  expect_silent(
    CheckSpec(
      list(d = data.frame(a = 1, b = 2)),
      list(d = list(required_cols = c("a", "b")))
    )
  )
})

test_that("legacy specs deliberately do NOT enforce declared types (#91)", {
  # STUDYID is declared character but supplied as numeric. This must still pass:
  # enforcing types would newly break workflows that pass today.
  expect_silent(
    CheckSpec(
      list(d = data.frame(STUDYID = 1L)),
      list(d = list(STUDYID = list(type = "character")))
    )
  )
})

test_that("CheckSpec still errors on a missing domain (#91)", {
  expect_error(
    CheckSpec(list(), list(d = list(required_cols = "a"))),
    "Spec-declared input 'd' not found in lData"
  )
})

test_that("CheckSpec returns per-domain results (#91)", {
  res <- CheckSpec(
    list(d = data.frame(a = 1)),
    list(d = list(required_cols = "a"))
  )
  expect_named(res, "d")
  expect_equal(res$d$dialect, "legacy")
  expect_true(res$d$passed)
})

# --- Dialect detection ---------------------------------------------------

test_that("spec dialects are detected and bad shapes error (#91)", {
  expect_equal(.SpecDialect("f_spec.yaml", "d"), "pointblank_file")
  expect_equal(.SpecDialect(list(steps = list()), "d"), "pointblank_inline")
  expect_equal(.SpecDialect(list(a = list(type = "character")), "d"), "legacy")

  # An unnamed list is not a valid legacy spec and must not silently pass.
  expect_error(.SpecDialect(list(1, 2), "d"), "Unrecognized spec format")
})

# --- Translation layer ---------------------------------------------------

test_that("Python-form method and argument names are translated (#91)", {
  expect_equal(
    .PbTranslateStep(list(col_vals_le = list(columns = "a", value = 5)))$method,
    "col_vals_lte"
  )
  expect_equal(
    .PbTranslateStep(list(col_vals_ge = list(columns = "a", value = 5)))$method,
    "col_vals_gte"
  )

  # `pattern` errors loudly in R pointblank; it must become `regex`.
  step <- .PbTranslateStep(list(
    col_vals_regex = list(columns = "b", pattern = "x")
  ))
  expect_true("regex" %in% names(step$args))
  expect_false("pattern" %in% names(step$args))
})

test_that("bare-string steps are supported (#91)", {
  # R pointblank's own YAML reader fails on these with "argument is of length zero".
  step <- .PbTranslateStep("rows_distinct")
  expect_equal(step$method, "rows_distinct")
  expect_equal(step$args, list())
})

test_that("Python severity names map to action_levels arguments (#91)", {
  args <- .PbThresholdArgs(list(warning = 0.1, error = 0.2, critical = 0.3))
  expect_equal(args, list(warn_at = 0.1, stop_at = 0.2, notify_at = 0.3))

  # The *_fraction serialization spellings are also accepted.
  expect_equal(.PbThresholdArgs(list(warn_fraction = 0.5)), list(warn_at = 0.5))
})

test_that("step-level thresholds merge over global rather than replacing (#91)", {
  # Verified on pointblank 0.12.4: passing step-level actions REPLACES the global
  # action_levels, leaving unspecified levels NA. Merging keeps the global error.
  step <- .PbTranslateStep(
    list(
      col_vals_gt = list(
        columns = "a",
        value = 0,
        thresholds = list(warning = 0.01)
      )
    ),
    global_thresholds = list(warn_at = 0.1, stop_at = 0.5)
  )
  expect_equal(step$args$actions$warn_fraction, 0.01)
  expect_equal(step$args$actions$stop_fraction, 0.5)
  expect_null(step$args$thresholds)
})

# --- The safety-critical regression --------------------------------------

test_that("unrecognized top-level keys warn instead of vanishing (#91)", {
  skip_if_not_installed("pointblank")
  # R pointblank silently discards unknown top-level keys. A spec whose
  # thresholds were misspelled would otherwise report success with no severity
  # levels at all -- the worst failure mode for a validation pipeline.
  expect_warning(
    .PbInterrogate(
      make_df(),
      list(totally_bogus_key = 3, steps = list("rows_distinct")),
      "d"
    ),
    "unrecognized top-level spec key"
  )
})

test_that("Python-only governance keys are accepted without warning (#91)", {
  skip_if_not_installed("pointblank")
  expect_no_warning(
    .PbInterrogate(
      make_df(),
      list(
        df_library = "polars",
        owner = "Data Eng",
        steps = list("rows_distinct")
      ),
      "d"
    )
  )
})

test_that("undocumented vector column refs still expand to multiple steps (#91)", {
  skip_if_not_installed("pointblank")
  # `columns: [a, b]` expanding to two steps is undocumented behavior worth a
  # canary test.
  agent <- .PbInterrogate(
    make_df(),
    list(
      steps = list(list(col_exists = list(columns = c("STUDYID", "USUBJID"))))
    ),
    "d"
  )
  expect_equal(nrow(agent$validation_set), 2)
})

# --- Failure contract ----------------------------------------------------

test_that("error-level breaches abort the workflow (#91)", {
  skip_if_not_installed("pointblank")
  spec <- list(
    thresholds = list(error = 0.01),
    steps = list(list(col_vals_not_null = list(columns = "STUDYID")))
  )
  df <- make_df()
  df$STUDYID[1] <- NA

  expect_error(
    suppressMessages(CheckSpec(list(d = df), list(d = spec))),
    "Spec validation failed for 'd' at level 'error'"
  )
})

test_that("warning-level breaches log and continue (#91)", {
  skip_if_not_installed("pointblank")
  spec <- list(
    thresholds = list(warning = 0.01),
    steps = list(list(col_vals_not_null = list(columns = "STUDYID")))
  )
  df <- make_df()
  df$STUDYID[1] <- NA

  res <- suppressMessages(CheckSpec(list(d = df), list(d = spec)))
  expect_equal(res$d$level, "warning")
  expect_false(res$d$passed)
})

test_that("a passing pointblank spec returns a pass result (#91)", {
  skip_if_not_installed("pointblank")
  res <- suppressMessages(CheckSpec(
    list(d = make_df()),
    list(
      d = list(
        steps = list(
          list(col_exists = list(columns = c("STUDYID", "USUBJID"))),
          "rows_distinct"
        )
      )
    )
  ))
  expect_true(res$d$passed)
  expect_equal(res$d$level, "pass")
  expect_equal(res$d$dialect, "pointblank")
})

test_that("an unset threshold level never aborts (#91)", {
  skip_if_not_installed("pointblank")
  # `notify` is NA when unset; NA must not be treated as a breach.
  df <- make_df()
  df$STUDYID[1] <- NA
  res <- suppressMessages(CheckSpec(
    list(d = df),
    list(
      d = list(
        steps = list(list(col_vals_not_null = list(columns = "STUDYID")))
      )
    )
  ))
  expect_equal(res$d$level, "pass")
})

# --- Spec files ----------------------------------------------------------

test_that("spec file paths resolve relative to the workflow file (#91)", {
  skip_if_not_installed("pointblank")
  workflow_path <- system.file(
    "example_workflows/04_Example_RAW_TO_SDTM/DM.yaml",
    package = "workr"
  )
  skip_if(workflow_path == "")

  res <- suppressMessages(CheckSpec(
    list(dm_raw = make_df()),
    list(dm_raw = "DM_dm_raw_spec.yaml"),
    strPath = workflow_path
  ))
  expect_true(res$dm_raw$passed)
})

test_that("`tbl_name` is not partial-matched as `tbl` (#91)", {
  skip_if_not_installed("pointblank")
  # `spec$tbl` partial-matches `tbl_name`, which would wrongly trigger the
  # "ignoring tbl" path for every spec that names its table.
  expect_no_message(
    .PbInterrogate(
      make_df(),
      list(tbl_name = "d", steps = list("rows_distinct")),
      "d"
    )
  )
})

test_that("a missing spec file errors clearly (#91)", {
  expect_error(
    CheckSpec(list(d = make_df()), list(d = "does_not_exist_spec.yaml")),
    "Spec file for domain 'd' not found"
  )
})

# --- Extracted helpers ---------------------------------------------------

test_that(".ResolveSpecPath resolves relative to the workflow file (#91)", {
  workflow_path <- system.file(
    "example_workflows/04_Example_RAW_TO_SDTM/DM.yaml",
    package = "workr"
  )
  skip_if(workflow_path == "")

  path <- .ResolveSpecPath("DM_dm_raw_spec.yaml", "dm_raw", workflow_path)
  expect_true(file.exists(path))

  # An already-valid path is used as-is rather than being re-rooted.
  expect_equal(.ResolveSpecPath(path, "dm_raw", workflow_path), path)

  expect_error(
    .ResolveSpecPath("nope_spec.yaml", "dm_raw", workflow_path),
    "Spec file for domain 'dm_raw' not found"
  )
})

test_that(".LoadSpec converges file and inline specs on one representation (#91)", {
  inline <- list(steps = list("rows_distinct"))
  expect_identical(.LoadSpec(inline, "pointblank_inline", "d"), inline)

  workflow_path <- system.file(
    "example_workflows/04_Example_RAW_TO_SDTM/DM.yaml",
    package = "workr"
  )
  skip_if(workflow_path == "")
  loaded <- .LoadSpec(
    "DM_dm_raw_spec.yaml",
    "pointblank_file",
    "dm_raw",
    workflow_path
  )
  expect_true(is.list(loaded))
  expect_true("steps" %in% names(loaded))
})

test_that(".EnforceSpecResult applies the failure contract (#91)", {
  base <- list(
    domain = "d",
    n_steps = 2,
    n_failed_steps = 1,
    failed_steps = "col_exists"
  )

  expect_error(
    .EnforceSpecResult(utils::modifyList(base, list(level = "error"))),
    "Spec validation failed for 'd' at level 'error'"
  )
  expect_error(
    .EnforceSpecResult(utils::modifyList(base, list(level = "critical"))),
    "at level 'critical'"
  )
  expect_message(
    .EnforceSpecResult(utils::modifyList(base, list(level = "warning"))),
    "Spec validation warning for 'd'"
  )
  expect_silent(
    .EnforceSpecResult(utils::modifyList(base, list(level = "pass")))
  )
})

test_that(".CheckSpecDomain dispatches on dialect (#91)", {
  skip_if_not_installed("pointblank")

  legacy <- .CheckSpecDomain(make_df(), list(required_cols = "STUDYID"), "d")
  expect_equal(legacy$dialect, "legacy")

  pb <- suppressMessages(
    .CheckSpecDomain(make_df(), list(steps = list("rows_distinct")), "d")
  )
  expect_equal(pb$dialect, "pointblank")
})

test_that("CheckSpec preserves domain order and names in its results (#91)", {
  res <- CheckSpec(
    list(b = data.frame(x = 1), a = data.frame(y = 2)),
    list(b = list(required_cols = "x"), a = list(required_cols = "y"))
  )
  expect_equal(names(res), c("b", "a"))
})

test_that("`*_spec.yaml` files are not discovered as workflows (#91)", {
  files <- ListWorkflows(strPath = "example_workflows", strPackage = "workr")
  expect_false(any(grepl("_spec\\.ya?ml$", basename(files))))
})

# --- Translation-layer edge cases (#91) ----------------------------------

test_that(".PbThresholdArgs handles empty and absent thresholds (#91)", {
  expect_identical(.PbThresholdArgs(NULL), list())
  expect_identical(.PbThresholdArgs(list()), list())
})

test_that(".PbThresholdArgs requires a named mapping (#91)", {
  # `thresholds: [0.1, 0.2]` is meaningless: severity is carried by the key.
  expect_error(
    .PbThresholdArgs(list(0.1, 0.2)),
    "`thresholds` must be a named mapping"
  )
})

test_that(".PbThresholdArgs warns on unknown levels and drops them (#91)", {
  expect_warning(
    args <- .PbThresholdArgs(list(warning = 0.1, oops = 0.5)),
    "Ignoring unrecognized threshold level\\(s\\): oops"
  )
  expect_identical(args, list(warn_at = 0.1))
})

test_that(".PbThresholdArgs accepts the YAML *_fraction spellings (#91)", {
  expect_identical(
    .PbThresholdArgs(list(warn_fraction = 0.1, stop_fraction = 0.2)),
    list(warn_at = 0.1, stop_at = 0.2)
  )
})

test_that(".PbActionLevels returns NULL for no arguments (#91)", {
  expect_null(.PbActionLevels(list()))
})

test_that(".PbTranslateStep coerces non-list step arguments (#91)", {
  # `col_exists: STUDYID` parses as a bare character, not a list.
  step <- .PbTranslateStep(list(col_exists = "STUDYID"))
  expect_identical(step$method, "col_exists")
  expect_identical(step$args, list("STUDYID"))
})

test_that(".PbTranslateStep rejects malformed steps (#91)", {
  msg <- "Each entry of `steps` must be a validation method name or a single-key mapping"
  expect_error(.PbTranslateStep(list("col_exists")), msg)
  expect_error(.PbTranslateStep(42), msg)
})

test_that(".PbTranslateStep rejects multi-key steps rather than dropping them (#91)", {
  expect_error(
    .PbTranslateStep(list(col_exists = "A", rows_distinct = NULL)),
    "single-key mapping; got 2 keys"
  )
})

test_that(".PbTranslateStep warns on methods outside the portable subset (#91)", {
  # Valid in R pointblank, but not guaranteed to exist in Python pointblank.
  expect_warning(
    step <- .PbTranslateStep(list(col_vals_expr = "~ TRUE")),
    "outside the cross-language portable subset"
  )
  expect_identical(step$method, "col_vals_expr")
})

test_that(".PbInterrogate logs that a spec-supplied `tbl` is ignored (#91)", {
  skip_if_not_installed("pointblank")

  # `tbl:` is an R formula in R and a lambda in Python -- the one field that
  # provably cannot round-trip -- so workflow-supplied data always wins.
  expect_message(
    .PbInterrogate(
      make_df(),
      list(tbl = "~ some_other_data", steps = list("rows_distinct")),
      "d"
    ),
    "Ignoring `tbl` in spec"
  )
})

test_that(".PbInterrogate errors on an unknown validation method (#91)", {
  skip_if_not_installed("pointblank")

  expect_error(
    suppressWarnings(
      .PbInterrogate(make_df(), list(steps = list("col_vals_nonsense")), "d")
    ),
    "Unknown pointblank validation method: 'col_vals_nonsense'"
  )
})

test_that(".PbSummarize reports the critical level on a notify breach (#91)", {
  skip_if_not_installed("pointblank")

  agent <- suppressMessages(
    .PbInterrogate(
      make_df(),
      list(
        thresholds = list(critical = 1),
        steps = list(list(rows_distinct = list(columns = "STUDYID")))
      ),
      "d"
    )
  )
  result <- .PbSummarize(agent, "d")

  expect_identical(result$level, "critical")
  expect_false(result$passed)
})

# --- 03_KRI converted specs (#91) ----------------------------------------

kri_path <- function(file) {
  system.file("example_workflows/03_KRI", file, package = "workr")
}

test_that("03_KRI specs pass against the example data (#91)", {
  skip_if_not_installed("pointblank")
  local_quiet_log("info")

  source(kri_path("initData.R"), local = TRUE)
  lData <- initData()

  expect_silent(
    CheckSpec(
      lData,
      list(Raw_SUBJ = "SUBJ_Raw_SUBJ_spec.yaml"),
      strPath = kri_path("SUBJ.yaml")
    )
  )
  expect_silent(
    CheckSpec(
      lData,
      list(Raw_AE = "AE_Raw_AE_spec.yaml"),
      strPath = kri_path("AE.yaml")
    )
  )
})

test_that("03_KRI specs actually enforce declared types (#91)", {
  skip_if_not_installed("pointblank")
  local_quiet_log("info")

  # The legacy format declared types but never checked them. This is the
  # behavior change the conversion buys, so assert it rather than trust it.
  source(kri_path("initData.R"), local = TRUE)
  lData <- initData()
  lData$Raw_SUBJ$timeonstudy <- as.character(lData$Raw_SUBJ$timeonstudy)

  expect_error(
    CheckSpec(
      lData,
      list(Raw_SUBJ = "SUBJ_Raw_SUBJ_spec.yaml"),
      strPath = kri_path("SUBJ.yaml")
    ),
    "col_is_integer"
  )
})

test_that("03_KRI specs catch a dropped column (#91)", {
  skip_if_not_installed("pointblank")
  local_quiet_log("info")

  source(kri_path("initData.R"), local = TRUE)
  lData <- initData()
  lData$Raw_AE$aetoxgr <- NULL

  expect_error(
    CheckSpec(
      lData,
      list(Raw_AE = "AE_Raw_AE_spec.yaml"),
      strPath = kri_path("AE.yaml")
    ),
    "col_exists"
  )
})

test_that("spec failure messages are not buried by iteration context (#91)", {
  skip_if_not_installed("pointblank")
  local_quiet_log("info")

  # `purrr::map()` prefixed aborts with "In index: N", pushing the actual
  # diagnosis out of view. The domain name already identifies the failure.
  err <- tryCatch(
    CheckSpec(
      list(d = data.frame(x = "a", stringsAsFactors = FALSE)),
      list(
        d = list(
          thresholds = list(error = 0.01),
          steps = list(list(col_is_numeric = list(columns = "x")))
        )
      )
    ),
    error = function(e) conditionMessage(e)
  )

  expect_match(err, "^Spec validation failed for 'd'")
  expect_no_match(err, "In index")
})

test_that("all 03_KRI workflows use the pointblank dialect (#91)", {
  skip_if_not_installed("pointblank")
  skip_if_not_installed("arrow")

  # Guards against a legacy block creeping back in during future edits.
  for (file in c("SUBJ.yaml", "AE.yaml", "kri0001.yaml")) {
    spec <- yaml::read_yaml(kri_path(file))$spec

    for (domain in names(spec)) {
      expect_identical(
        .SpecDialect(spec[[domain]], domain),
        "pointblank_file",
        info = paste(file, domain)
      )
    }
  }
})

# --- Workflows 05-07 converted specs (#91) -------------------------------

read_advs <- function() {
  path <- system.file(
    "demo_gsmpharmaverse/data/ADAM/ADAM_ADVS.parquet",
    package = "workr"
  )
  skip_if(path == "", "ADAM_ADVS.parquet not installed")
  arrow::read_parquet(path)
}

wf_spec <- function(dir, file) {
  path <- system.file(
    file.path("example_workflows", dir, file),
    package = "workr"
  )
  # Workflow files carry `!expr` tags in their `steps:`; we only read `spec:`,
  # so the "requires eval.expr=TRUE" warning is irrelevant noise here.
  list(spec = suppressWarnings(yaml::read_yaml(path))$spec, path = path)
}

test_that("workflow 05-07 specs pass against their example data (#91)", {
  skip_if_not_installed("pointblank")
  skip_if_not_installed("arrow")
  local_quiet_log("info")

  sdtm <- function(name) {
    p <- system.file(
      file.path("demo_gsmpharmaverse/data/SDTM", name),
      package = "workr"
    )
    skip_if(p == "", paste(name, "not installed"))
    arrow::read_parquet(p)
  }

  advs <- read_advs()
  cases <- list(
    list(
      "05_Example_SDTM_TO_ADAM",
      "ADVS.yaml",
      list(SDTM_DM = sdtm("SDTM_DM.parquet"), SDTM_VS = sdtm("SDTM_VS.parquet"))
    ),
    list("06_Example_ADAM_TO_TFL", "WorkProduct1.yaml", list(ADVS = advs)),
    list(
      "07_Example_ADAM_TO_ARS",
      "table_mean_arterial_pressure.yaml",
      list(ADVS = advs)
    )
  )

  for (case in cases) {
    wf <- wf_spec(case[[1]], case[[2]])
    expect_no_error(CheckSpec(case[[3]], wf$spec, strPath = wf$path))
  }
})

test_that("workflow 07 spec catches type, missing, and null violations (#91)", {
  skip_if_not_installed("pointblank")
  skip_if_not_installed("arrow")
  local_quiet_log("info")

  # The legacy `_all: {required: true}` wildcard was inert -- it validated
  # nothing at all. These assertions are what the conversion buys.
  advs <- read_advs()
  wf <- wf_spec("07_Example_ADAM_TO_ARS", "table_mean_arterial_pressure.yaml")

  broken <- advs
  broken$AVAL <- as.character(broken$AVAL)
  expect_error(
    CheckSpec(list(ADVS = broken), wf$spec, strPath = wf$path),
    "col_is_numeric"
  )

  dropped <- advs
  dropped$PARAMCD <- NULL
  expect_error(
    CheckSpec(list(ADVS = dropped), wf$spec, strPath = wf$path),
    "col_exists"
  )

  nulled <- advs
  nulled$PARAMCD[1:5] <- NA_character_
  expect_error(
    CheckSpec(list(ADVS = nulled), wf$spec, strPath = wf$path),
    "col_vals_not_null"
  )
})

test_that("example workflow specs are all in a recognized dialect (#91)", {
  # Every domain spec must classify as a pointblank spec or as the `_all`
  # wildcard. Anything else means a spec shape has drifted into a form that
  # silently validates nothing.
  files <- ListWorkflows(strPath = "example_workflows", strPackage = "workr")

  for (file in files) {
    spec <- suppressWarnings(yaml::read_yaml(file))$spec
    if (is.null(spec)) {
      next
    }

    for (domain in names(spec)) {
      dialect <- .SpecDialect(spec[[domain]], domain)
      expect_true(
        dialect %in%
          c("pointblank_file", "pointblank_inline") ||
          .SpecWildcardRequired(spec[[domain]]),
        info = paste(basename(file), domain)
      )
    }
  }
})
