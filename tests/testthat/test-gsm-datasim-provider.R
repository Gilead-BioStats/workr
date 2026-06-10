make_gsm_datasim_workflow <- function(id = "gsm_provider") {
  list(
    meta = list(Type = "demo", ID = id),
    steps = list(
      list(
        name = "identity_step",
        output = "res",
        params = list(x = "loaded_val")
      )
    )
  )
}

test_that("gsm.datasim provider adapts standard single-snapshot data and aliases (#59)", {
  had_identity_step <- exists("identity_step", envir = .GlobalEnv, inherits = FALSE)
  old_identity_step <- if (had_identity_step) {
    get("identity_step", envir = .GlobalEnv, inherits = FALSE)
  }
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit({
    if (had_identity_step) {
      assign("identity_step", old_identity_step, envir = .GlobalEnv)
    } else {
      rm("identity_step", envir = .GlobalEnv)
    }
  }, add = TRUE)

  standard_args <- NULL
  generate_args <- NULL

  local_mocked_bindings(
    gsm_datasim_api = function() {
      list(
        create_standard_study_config = function(...) {
          standard_args <<- list(...)
          list(built = TRUE)
        },
        generate_study_data = function(...) {
          generate_args <<- list(...)
          list(
            "2024-01-31" = list(
              Raw_SUBJ = data.frame(subjid = "S001", stringsAsFactors = FALSE),
              Raw_AE = data.frame(subjid = "S001", stringsAsFactors = FALSE),
              loaded_val = 7
            )
          )
        },
        quick_longitudinal_study = function(...) {
          stop("unexpected longitudinal call")
        },
        set_temporal_config = function(config, ...) {
          config$temporal <- list(...)
          config
        },
        create_study_config = NULL,
        add_dataset_config = NULL
      )
    },
    .package = "workr"
  )

  lWorkflow <- make_gsm_datasim_workflow("single_snapshot")

  suppressMessages({
    result <- RunWorkflow(
      lWorkflow = lWorkflow,
      lData = list(caller_value = 11),
      lConfig = list(
        LoadData = "gsm.datasim",
        gsm.datasim = list(
          profile = "standard",
          study_type = "standard",
          participants = 25,
          sites = 4,
          snapshot_count = 1,
          subject_visits = FALSE
        )
      )
    )
  })

  expect_equal(result, 7)
  expect_equal(standard_args$study_id, "single_snapshot")
  expect_equal(standard_args$participant_count, 25)
  expect_equal(standard_args$site_count, 4)
  expect_identical(standard_args$study, TRUE)
  expect_identical(standard_args$subjects, TRUE)
  expect_identical(standard_args$subject_visits, FALSE)
  expect_equal(generate_args$config$temporal$snapshot_count, 1)

  loaded <- workr:::gsm_datasim_load_provider(
    lWorkflow = lWorkflow,
    lConfig = list(
      LoadData = "gsm.datasim",
      gsm.datasim = list(profile = "standard", study_type = "standard")
    ),
    lData = list(caller_value = 11)
  )

  expect_true(all(c("Raw_SUBJ", "Raw_AE", "dfSUBJ", "dfAE") %in% names(loaded)))
  expect_equal(loaded$caller_value, 11)
})

test_that("gsm.datasim provider tolerates standard config API drift (#59)", {
  standard_args <- NULL

  local_mocked_bindings(
    gsm_datasim_api = function() {
      list(
        create_standard_study_config = function(
          study_id,
          participant_count,
          site_count,
          analytics_package = NULL,
          analytics_workflows = NULL,
          study = TRUE,
          subjects = TRUE,
          sites_data = TRUE,
          adverse_events = TRUE,
          protocol_deviations = TRUE,
          lab_data = TRUE,
          subject_visits = TRUE,
          visit_schedule = TRUE,
          enrollment = TRUE,
          data_changes = TRUE,
          data_entry = TRUE,
          queries = TRUE,
          pharmacokinetics = TRUE,
          study_drug_completion = TRUE,
          study_completion = TRUE,
          inclusion_exclusion = TRUE,
          exclusions = TRUE,
          country = TRUE,
          outlier_intensity = 1
        ) {
          standard_args <<- as.list(environment())
          list(built = TRUE)
        },
        generate_study_data = function(...) {
          list(loaded_val = 7)
        },
        quick_longitudinal_study = function(...) {
          stop("unexpected longitudinal call")
        },
        set_temporal_config = NULL,
        create_study_config = NULL,
        add_dataset_config = NULL
      )
    },
    .package = "workr"
  )

  loaded <- workr:::gsm_datasim_load_provider(
    lWorkflow = make_gsm_datasim_workflow("api_drift"),
    lConfig = list(
      LoadData = "gsm.datasim",
      gsm.datasim = list(
        death = TRUE,
        randomization = TRUE,
        overall_response = TRUE
      )
    ),
    lData = list()
  )

  expect_equal(loaded$loaded_val, 7)
  expect_false("death" %in% names(standard_args))
  expect_false("randomization" %in% names(standard_args))
  expect_false("overall_response" %in% names(standard_args))
})

test_that("gsm.datasim provider uses latest longitudinal snapshot by default (#59)", {
  quick_args <- NULL

  local_mocked_bindings(
    gsm_datasim_api = function() {
      list(
        create_standard_study_config = function(...) {
          stop("unexpected standard config call")
        },
        generate_study_data = function(...) {
          stop("unexpected generate_study_data call")
        },
        quick_longitudinal_study = function(...) {
          quick_args <<- list(...)
          list(
            raw_data = list(
              "2024-01-31" = list(
                Raw_SUBJ = data.frame(subjid = "S001", stringsAsFactors = FALSE)
              ),
              "2024-02-29" = list(
                Raw_SUBJ = data.frame(
                  subjid = "S002",
                  stringsAsFactors = FALSE
                ),
                loaded_val = 42
              )
            )
          )
        },
        set_temporal_config = NULL,
        create_study_config = NULL,
        add_dataset_config = NULL
      )
    },
    .package = "workr"
  )

  loaded <- workr:::gsm_datasim_load_provider(
    lWorkflow = make_gsm_datasim_workflow("longitudinal_case"),
    lConfig = list(
      LoadData = "gsm.datasim",
      gsm.datasim = list(
        study_type = "endpoints",
        months_duration = 2,
        participants = 10,
        sites = 3
      )
    ),
    lData = list()
  )

  expect_equal(quick_args$study_name, "longitudinal_case")
  expect_equal(quick_args$study_type, "endpoints")
  expect_equal(loaded$loaded_val, 42)
  expect_equal(loaded$Raw_SUBJ$subjid[[1]], "S002")
  expect_equal(loaded$dfSUBJ$subjid[[1]], "S002")
})

test_that("gsm.datasim provider validates profile and study_type early (#59)", {
  local_mocked_bindings(
    gsm_datasim_api = function() stop("api should not be called"),
    .package = "workr"
  )

  expect_error(
    workr:::gsm_datasim_load_provider(
      lWorkflow = make_gsm_datasim_workflow(),
      lConfig = list(
        LoadData = "gsm.datasim",
        gsm.datasim = list(profile = "unknown")
      ),
      lData = list()
    ),
    regexp = "Unsupported `lConfig\\$gsm\\.datasim\\$profile` value"
  )

  expect_error(
    workr:::gsm_datasim_load_provider(
      lWorkflow = make_gsm_datasim_workflow(),
      lConfig = list(
        LoadData = "gsm.datasim",
        gsm.datasim = list(study_type = "mystery")
      ),
      lData = list()
    ),
    regexp = "Unsupported `lConfig\\$gsm\\.datasim\\$study_type` value"
  )

  expect_error(
    workr:::gsm_datasim_load_provider(
      lWorkflow = make_gsm_datasim_workflow(),
      lConfig = list(
        LoadData = "gsm.datasim",
        gsm.datasim = list(profile = NA_character_)
      ),
      lData = list()
    ),
    regexp = "`lConfig\\$gsm\\.datasim\\$profile` must be a non-empty single string"
  )
})

test_that("gsm.datasim provider handles edge-case scalar config values (#59)", {
  expect_null(workr:::normalize_gsm_datasim_scalar(NA_character_))
  expect_null(workr:::normalize_gsm_datasim_scalar(""))

  expect_false(workr:::gsm_datasim_is_longitudinal(list(snapshot_count = "abc")))
  expect_false(workr:::gsm_datasim_is_longitudinal(list(months_duration = NA_integer_)))
  expect_true(workr:::gsm_datasim_is_longitudinal(list(snapshot_count = "2")))

  snapshots <- list(
    one = list(Raw_SUBJ = data.frame(subjid = "S001", stringsAsFactors = FALSE)),
    two = list(Raw_SUBJ = data.frame(subjid = "S002", stringsAsFactors = FALSE))
  )

  expect_equal(
    workr:::gsm_datasim_snapshot_data(snapshots, snapshot = 2)$Raw_SUBJ$subjid,
    "S002"
  )
  expect_error(
    workr:::gsm_datasim_snapshot_data(snapshots, snapshot = 1.9),
    regexp = "must be a whole number between 1 and 2"
  )
})

test_that("gsm.datasim provider requires custom config for custom profile (#59)", {
  local_mocked_bindings(
    gsm_datasim_api = function() stop("api should not be called"),
    .package = "workr"
  )

  expect_error(
    workr:::gsm_datasim_load_provider(
      lWorkflow = make_gsm_datasim_workflow(),
      lConfig = list(
        LoadData = "gsm.datasim",
        gsm.datasim = list(profile = "custom", study_type = "standard")
      ),
      lData = list()
    ),
    regexp = "`lConfig\\$gsm\\.datasim\\$config` must be a study configuration list"
  )
})

test_that("built-in providers are registered together (#59, #60, #61)", {
  expect_silent(workr:::workr_register_builtin_providers())
  expect_true(is.function(workr:::resolve_config_hook(
    list(LoadData = "gsm.datasim"),
    "LoadData"
  )))
  expect_true(is.function(workr:::resolve_config_hook(
    list(LoadData = "github_artifact"),
    "LoadData"
  )))
  expect_true(is.function(workr:::resolve_config_hook(
    list(SaveData = "github_artifact"),
    "SaveData"
  )))
})
