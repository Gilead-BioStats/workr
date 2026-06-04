make_test_dir <- function(prefix) {
  path <- file.path(
    tempdir(),
    paste0(prefix, "-", Sys.getpid(), "-", as.integer(stats::runif(1, 1, 1e9)))
  )
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

write_test_artifact_bundle <- function(bundle_dir, entries) {
  dir.create(file.path(bundle_dir, "payload"), recursive = TRUE, showWarnings = FALSE)

  manifest_entries <- lapply(seq_along(entries), function(index) {
    key <- names(entries)[[index]]
    safe_key <- gsub("[^A-Za-z0-9._-]", "_", key)
    rel_path <- sprintf("payload/%03d-%s.rds", index, safe_key)
    saveRDS(entries[[index]], file.path(bundle_dir, rel_path))
    list(key = key, file = rel_path)
  })

  yaml::write_yaml(
    list(provider = "github_artifact", entries = manifest_entries),
    file.path(bundle_dir, "manifest.yaml")
  )
}

clear_github_artifact_env <- function() {
  withr::local_envvar(c(
    GITHUB_RUN_ID = "",
    GITHUB_REPOSITORY = ""
  ), .local_envir = parent.frame())
}

test_that("github_artifact save provider writes manifest and payload pair (#60)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  output_dir <- make_test_dir("save-provider")
  on.exit(unlink(output_dir, recursive = TRUE, force = TRUE), add = TRUE)

  uploader_args <- NULL
  lWorkflow <- list(
    meta = list(Type = "demo", ID = "artifact_save"),
    steps = list(
      list(name = "identity_step", output = "results", params = list(x = "val"))
    )
  )

  suppressMessages({
    RunWorkflow(
      lWorkflow = lWorkflow,
      lData = list(val = 7, qc = 11, secret = 99),
      lConfig = list(
        SaveData = "github_artifact",
        github_artifact = list(
          path = output_dir,
          include = c("results", "qc"),
          exclude = "secret",
          retention_days = 30,
          run_id = "12345",
          uploader = function(...) {
            uploader_args <<- list(...)
          }
        )
      )
    )
  })

  bundle_dir <- file.path(output_dir, "workr-artifact_save")
  manifest <- yaml::read_yaml(file.path(bundle_dir, "manifest.yaml"))

  expect_equal(manifest$artifact_name, "workr-artifact_save")
  expect_equal(manifest$run_id, "12345")
  expect_equal(manifest$retention_days, 30)
  expect_setequal(vapply(manifest$entries, `[[`, character(1), "key"), c("results", "qc"))
  expect_false(any(vapply(manifest$entries, `[[`, character(1), "key") == "secret"))
  expect_true(file.exists(file.path(bundle_dir, manifest$entries[[1]]$file)))
  expect_equal(uploader_args$retention_days, 30)
})

test_that("github_artifact load provider restores data for an explicit run-id (#61)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  bundle_dir <- make_test_dir("load-explicit")
  on.exit(unlink(bundle_dir, recursive = TRUE, force = TRUE), add = TRUE)
  write_test_artifact_bundle(bundle_dir, list(loaded_val = 42))

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "artifact_load_explicit"),
    steps = list(
      list(name = "identity_step", output = "res", params = list(x = "loaded_val"))
    )
  )

  result <- suppressMessages(RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(),
    lConfig = list(
      LoadData = "github_artifact",
      github_artifact = list(
        run_id = "67890",
        artifact_fetcher = function(...) bundle_dir
      )
    )
  ))

  expect_equal(result, 42)
})

test_that("github_artifact load provider resolves latest_success policy (#61)", {
  clear_github_artifact_env()

  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  bundle_dir <- make_test_dir("load-policy")
  on.exit(unlink(bundle_dir, recursive = TRUE, force = TRUE), add = TRUE)
  write_test_artifact_bundle(bundle_dir, list(loaded_val = 84))

  resolved_policy <- NULL
  lWorkflow <- list(
    meta = list(Type = "demo", ID = "artifact_load_policy"),
    steps = list(
      list(name = "identity_step", output = "res", params = list(x = "loaded_val"))
    )
  )

  result <- suppressMessages(RunWorkflow(
    lWorkflow = lWorkflow,
    lData = list(),
    lConfig = list(
      LoadData = "github_artifact",
      github_artifact = list(
        repo = "Gilead-BioStats/workr",
        policy = "latest_success",
        run_resolver = function(...) {
          resolved_policy <<- list(...)$policy
          "24680"
        },
        artifact_fetcher = function(...) bundle_dir
      )
    )
  ))

  expect_equal(result, 84)
  expect_equal(resolved_policy, "latest_success")
})

test_that("github_artifact load provider errors with run-id and policy on missing artifact (#61)", {
  clear_github_artifact_env()

  lWorkflow <- list(
    meta = list(Type = "demo", ID = "artifact_load_missing"),
    steps = list()
  )

  expect_error(
    suppressMessages(workr:::github_artifact_load_provider(
      lWorkflow = lWorkflow,
      lConfig = list(
        github_artifact = list(
          repo = "Gilead-BioStats/workr",
          policy = "latest_success",
          run_resolver = function(...) "13579",
          artifact_fetcher = function(...) stop("artifact not found", call. = FALSE)
        )
      ),
      lData = list()
    )),
    regexp = "run-id 13579.*policy: latest_success"
  )
})

test_that("github_artifact load provider warns and returns partial lData when payloads are missing (#61)", {
  bundle_dir <- make_test_dir("load-warn")
  on.exit(unlink(bundle_dir, recursive = TRUE, force = TRUE), add = TRUE)
  dir.create(file.path(bundle_dir, "payload"), recursive = TRUE, showWarnings = FALSE)

  present_path <- sprintf("payload/%03d-%s.rds", 1, "loaded_val")
  saveRDS(42, file.path(bundle_dir, present_path))
  yaml::write_yaml(
    list(
      provider = "github_artifact",
      entries = list(
        list(key = "loaded_val", file = present_path),
        list(key = "missing_val", file = sprintf("payload/%03d-%s.rds", 2, "missing_val"))
      )
    ),
    file.path(bundle_dir, "manifest.yaml")
  )

  restored <- NULL
  expect_message(
    restored <- workr:::github_artifact_load_provider(
      lWorkflow = list(meta = list(ID = "artifact_warn")),
      lConfig = list(
        github_artifact = list(
          run_id = "11223",
          on_missing = "warn",
          artifact_fetcher = function(...) bundle_dir
        )
      ),
      lData = list(existing = 1)
    ),
    regexp = "run-id 11223.*policy: explicit"
  )

  expect_equal(restored$existing, 1)
  expect_equal(restored$loaded_val, 42)
  expect_false("missing_val" %in% names(restored))
})