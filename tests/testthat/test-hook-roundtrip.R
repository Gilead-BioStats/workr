make_hook_roundtrip_workflow <- function(id = "hook_roundtrip") {
  list(
    meta = list(Type = "demo", ID = id),
    steps = list(
      list(
        name = "identity_step",
        output = "result",
        params = list(x = "loaded_val")
      )
    )
  )
}

make_hook_roundtrip_dir <- function(prefix) {
  path <- file.path(
    tempdir(),
    paste0(prefix, "-", Sys.getpid(), "-", as.integer(stats::runif(1, 1, 1e9)))
  )
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

test_that("hook providers round-trip data across runs (#62)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  bundle_dir <- NULL
  saved_state <- NULL
  output_dir <- make_hook_roundtrip_dir("hook-roundtrip")
  on.exit(unlink(output_dir, recursive = TRUE, force = TRUE), add = TRUE)

  local_mocked_bindings(
    gsm_datasim_api = function() {
      list(
        create_standard_study_config = function(...) list(...),
        generate_study_data = function(...) {
          list(
            "2024-01-31" = list(
              Raw_SUBJ = data.frame(subjid = "S001", stringsAsFactors = FALSE),
              loaded_val = 7
            )
          )
        },
        quick_longitudinal_study = function(...) {
          stop("unexpected longitudinal call")
        },
        set_temporal_config = function(config, ...) config,
        create_study_config = NULL,
        add_dataset_config = NULL
      )
    },
    .package = "workr"
  )

  workflow <- make_hook_roundtrip_workflow()

  suppressMessages({
    first_result <- RunWorkflow(
      lWorkflow = workflow,
      lData = list(),
      lConfig = list(
        LoadData = "gsm.datasim",
        SaveData = "github_artifact",
        gsm.datasim = list(
          profile = "standard",
          study_type = "standard",
          snapshot_count = 1
        ),
        github_artifact = list(
          path = output_dir,
          artifact_name = "workr-hook-roundtrip",
          run_id = "run-001",
          include = c("loaded_val", "Raw_SUBJ", "dfSUBJ", "result"),
          uploader = function(...) {
            args <- list(...)
            bundle_dir <<- args$bundle_dir
            saved_state <<- args$lWorkflow$lData[c(
              "loaded_val",
              "Raw_SUBJ",
              "dfSUBJ",
              "result"
            )]
          }
        )
      )
    )
  })

  expect_equal(first_result, 7)
  expect_true(dir.exists(bundle_dir))

  restored <- suppressMessages(RunWorkflow(
    lWorkflow = workflow,
    lData = list(existing = 1),
    lConfig = list(
      LoadData = "github_artifact",
      github_artifact = list(
        repo = "Gilead-Public/workr",
        artifact_name = "workr-hook-roundtrip",
        policy = "latest_success",
        run_resolver = function(...) "run-001",
        artifact_fetcher = function(...) bundle_dir
      )
    ),
    bReturnResult = FALSE
  ))

  expect_equal(restored$lData$existing, 1)
  expect_equal(restored$lData$loaded_val, saved_state$loaded_val)
  expect_equal(restored$lData$result, saved_state$result)
  expect_equal(restored$lData$Raw_SUBJ, saved_state$Raw_SUBJ)
  expect_equal(restored$lData$dfSUBJ, saved_state$dfSUBJ)
})
