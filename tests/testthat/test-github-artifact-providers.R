make_test_dir <- function(prefix) {
  path <- file.path(
    tempdir(),
    paste0(prefix, "-", Sys.getpid(), "-", as.integer(stats::runif(1, 1, 1e9)))
  )
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  path
}

write_test_artifact_bundle <- function(bundle_dir, entries) {
  dir.create(
    file.path(bundle_dir, "payload"),
    recursive = TRUE,
    showWarnings = FALSE
  )

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
  withr::local_envvar(
    c(
      GITHUB_RUN_ID = "",
      GITHUB_REPOSITORY = ""
    ),
    .local_envir = parent.frame()
  )
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
  expect_setequal(
    vapply(manifest$entries, `[[`, character(1), "key"),
    c("results", "qc")
  )
  expect_false(any(
    vapply(manifest$entries, `[[`, character(1), "key") == "secret"
  ))
  expect_true(file.exists(file.path(bundle_dir, manifest$entries[[1]]$file)))
  expect_equal(uploader_args$retention_days, 30)
})

test_that("github_artifact save provider clears stale bundle contents (#60)", {
  assign("identity_step", function(x) x, envir = .GlobalEnv)
  on.exit(rm("identity_step", envir = .GlobalEnv), add = TRUE)

  output_dir <- make_test_dir("save-provider-stale")
  on.exit(unlink(output_dir, recursive = TRUE, force = TRUE), add = TRUE)

  bundle_dir <- file.path(output_dir, "workr-artifact_save_stale")
  dir.create(
    file.path(bundle_dir, "payload"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  stale_path <- file.path(bundle_dir, "payload", "stale.rds")
  saveRDS("stale", stale_path)

  suppressMessages(RunWorkflow(
    lWorkflow = list(
      meta = list(Type = "demo", ID = "artifact_save_stale"),
      steps = list(
        list(
          name = "identity_step",
          output = "results",
          params = list(x = "val")
        )
      )
    ),
    lData = list(val = 7),
    lConfig = list(
      SaveData = "github_artifact",
      github_artifact = list(path = output_dir)
    )
  ))

  expect_false(file.exists(stale_path))
  expect_true(file.exists(file.path(bundle_dir, "manifest.yaml")))
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
      list(
        name = "identity_step",
        output = "res",
        params = list(x = "loaded_val")
      )
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
      list(
        name = "identity_step",
        output = "res",
        params = list(x = "loaded_val")
      )
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

test_that("github_artifact load provider reports required Actions scope on auth failures (#62)", {
  local_mocked_bindings(
    gh = function(...) {
      stop("HTTP 403 Forbidden: Resource not accessible by integration", call. = FALSE)
    },
    .package = "gh"
  )

  expect_error(
    suppressMessages(workr:::github_artifact_load_provider(
      lWorkflow = list(meta = list(Type = "demo", ID = "artifact_auth"), steps = list()),
      lConfig = list(
        github_artifact = list(
          repo = "Gilead-BioStats/workr",
          policy = "latest_success"
        )
      ),
      lData = list()
    )),
    regexp = "actions: read"
  )
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
          artifact_fetcher = function(...) {
            stop("artifact not found", call. = FALSE)
          }
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
  dir.create(
    file.path(bundle_dir, "payload"),
    recursive = TRUE,
    showWarnings = FALSE
  )

  present_path <- sprintf("payload/%03d-%s.rds", 1, "loaded_val")
  saveRDS(42, file.path(bundle_dir, present_path))
  yaml::write_yaml(
    list(
      provider = "github_artifact",
      entries = list(
        list(key = "loaded_val", file = present_path),
        list(
          key = "missing_val",
          file = sprintf("payload/%03d-%s.rds", 2, "missing_val")
        )
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

test_that("github_artifact load provider rejects payload paths outside bundle (#61)", {
  bundle_dir <- make_test_dir("load-path-traversal")
  on.exit(unlink(bundle_dir, recursive = TRUE, force = TRUE), add = TRUE)

  yaml::write_yaml(
    list(
      provider = "github_artifact",
      entries = list(
        list(key = "escaped", file = "../escaped.rds")
      )
    ),
    file.path(bundle_dir, "manifest.yaml")
  )

  expect_error(
    suppressMessages(workr:::github_artifact_load_provider(
      lWorkflow = list(meta = list(ID = "artifact_path_traversal")),
      lConfig = list(
        github_artifact = list(
          run_id = "33445",
          artifact_fetcher = function(...) bundle_dir
        )
      ),
      lData = list()
    )),
    regexp = "outside the artifact bundle"
  )
})

test_that("github_artifact load provider restores NULL payload values (#61)", {
  bundle_dir <- make_test_dir("load-null")
  on.exit(unlink(bundle_dir, recursive = TRUE, force = TRUE), add = TRUE)
  write_test_artifact_bundle(bundle_dir, list(null_val = NULL))

  restored <- suppressMessages(workr:::github_artifact_load_provider(
    lWorkflow = list(meta = list(ID = "artifact_null")),
    lConfig = list(
      github_artifact = list(
        run_id = "44556",
        artifact_fetcher = function(...) bundle_dir
      )
    ),
    lData = list(existing = 1)
  ))

  expect_equal(restored$existing, 1)
  expect_true("null_val" %in% names(restored))
  expect_null(restored$null_val)
})

test_that("gh_actions_download_artifact_bundle clears stale extracted contents (#61)", {
  download_dir <- make_test_dir("download-stale")
  on.exit(unlink(download_dir, recursive = TRUE, force = TRUE), add = TRUE)

  bundle_dir <- file.path(download_dir, "workr-artifact")
  dir.create(
    file.path(bundle_dir, "payload"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  stale_path <- file.path(bundle_dir, "payload", "stale.rds")
  saveRDS("stale", stale_path)

  local_mocked_bindings(
    gh = function(endpoint, ..., .destfile = NULL) {
      if (grepl("/actions/runs/.*/artifacts", endpoint)) {
        return(list(artifacts = list(list(name = "workr-artifact", id = 123))))
      }

      if (grepl("/actions/artifacts/.*/zip", endpoint)) {
        writeBin(charToRaw("zip"), .destfile)
        return(invisible(NULL))
      }

      stop("Unexpected endpoint: ", endpoint)
    },
    .package = "gh"
  )
  local_mocked_bindings(
    unzip = function(zipfile, exdir, ...) {
      yaml::write_yaml(
        list(provider = "github_artifact", entries = list()),
        file.path(exdir, "manifest.yaml")
      )
      invisible(character(0))
    },
    .package = "utils"
  )

  restored_dir <- workr:::gh_actions_download_artifact_bundle(
    repo = "Gilead-BioStats/workr",
    run_id = "24680",
    artifact_name = "workr-artifact",
    download_dir = download_dir
  )

  expect_equal(restored_dir, bundle_dir)
  expect_false(file.exists(stale_path))
  expect_true(file.exists(file.path(bundle_dir, "manifest.yaml")))
})
