test_that("resolve_package resolves explicit refs via mocked gh api (#43)", {
  local_mocked_bindings(
    gh_api_client = function(args) {
      cmd <- paste(args, collapse = " ")
      if (
        grepl("/commits/v1.2.3", cmd, fixed = TRUE) &&
          grepl(".sha", cmd, fixed = TRUE)
      ) {
        return("abc123")
      }
      if (
        grepl("contents/DESCRIPTION?ref=abc123", cmd, fixed = TRUE) &&
          grepl(".content", cmd, fixed = TRUE)
      ) {
        desc <- "Package: gsm.core\nVersion: 1.9.0\n"
        return(base64enc::base64encode(charToRaw(desc)))
      }
      stop("Unexpected gh_api_client args: ", cmd)
    }
  )

  out <- resolve_package("Gilead-BioStats", "gsm.core", ref = "v1.2.3")
  expect_equal(out$org, "Gilead-BioStats")
  expect_equal(out$repo, "gsm.core")
  expect_equal(out$ref, "v1.2.3")
  expect_equal(out$sha, "abc123")
  expect_equal(out$version, "1.9.0")
})

test_that("resolve_package uses date-based fallback when ref is not provided (#43)", {
  local_mocked_bindings(
    gh_api_client = function(args) {
      cmd <- paste(args, collapse = " ")
      if (grepl("/releases --paginate --jq .\\[\\]\\.tag_name", cmd)) {
        return(c("v1.0.0", "v1.1.0"))
      }
      if (grepl("/releases --paginate --jq .\\[\\]\\.published_at", cmd)) {
        return(c("2024-01-15T00:00:00Z", "2024-06-15T00:00:00Z"))
      }
      if (
        grepl("/commits/v1.0.0", cmd, fixed = TRUE) &&
          grepl(".sha", cmd, fixed = TRUE)
      ) {
        return("sha-v1-0-0")
      }
      if (
        grepl("contents/DESCRIPTION?ref=sha-v1-0-0", cmd, fixed = TRUE) &&
          grepl(".content", cmd, fixed = TRUE)
      ) {
        desc <- "Package: gsm.core\nVersion: 1.0.0\n"
        return(base64enc::base64encode(charToRaw(desc)))
      }
      stop("Unexpected gh_api_client args: ", cmd)
    }
  )

  out <- resolve_package(
    org = "Gilead-BioStats",
    repo = "gsm.core",
    ref = NULL,
    date = as.Date("2024-05-01")
  )

  expect_equal(out$ref, "v1.0.0")
  expect_equal(out$sha, "sha-v1-0-0")
  expect_equal(out$version, "1.0.0")
})

test_that("resolve_package errors on malformed gh commit lookup response (#43)", {
  local_mocked_bindings(
    gh_api_client = function(args) {
      cmd <- paste(args, collapse = " ")
      if (
        grepl("/commits/dev", cmd, fixed = TRUE) &&
          grepl(".sha", cmd, fixed = TRUE)
      ) {
        return("Not Found")
      }
      stop("Unexpected gh_api_client args: ", cmd)
    }
  )

  expect_error(
    resolve_package("Gilead-BioStats", "gsm.core", ref = "dev"),
    "Could not resolve ref"
  )
})

test_that("resolve_ref_by_date falls back to default branch when latest release is missing (#43)", {
  local_mocked_bindings(
    gh_api_client = function(args) {
      cmd <- paste(args, collapse = " ")
      if (
        grepl("/releases/latest", cmd, fixed = TRUE) &&
          grepl(".tag_name", cmd, fixed = TRUE)
      ) {
        return("Not Found")
      }
      if (
        grepl(
          "repos/Gilead-BioStats/gsm.core --jq .default_branch",
          cmd,
          fixed = TRUE
        )
      ) {
        return("main")
      }
      stop("Unexpected gh_api_client args: ", cmd)
    }
  )

  out <- resolve_ref_by_date("Gilead-BioStats", "gsm.core", date = NULL)
  expect_equal(out, "main")
})

test_that("gh_list_contents parses directory entries from mocked gh api (#43)", {
  local_mocked_bindings(
    gh_api_client = function(args) {
      cmd <- paste(args, collapse = " ")
      if (!("--jq" %in% args)) {
        return("[]")
      }
      if (grepl(".[].name", cmd, fixed = TRUE)) {
        return(c("0_other", "foo.yaml"))
      }
      if (grepl(".[].type", cmd, fixed = TRUE)) {
        return(c("dir", "file"))
      }
      if (grepl(".[].path", cmd, fixed = TRUE)) {
        return(c("inst/workflow/0_other", "inst/workflow/foo.yaml"))
      }
      stop("Unexpected gh_api_client args: ", cmd)
    }
  )

  entries <- gh_list_contents(
    "Gilead-BioStats/gsm.core",
    "inst/workflow",
    "abc123"
  )
  expect_length(entries, 2)
  expect_equal(entries[[1]]$name, "0_other")
  expect_equal(entries[[1]]$type, "dir")
  expect_equal(entries[[2]]$name, "foo.yaml")
  expect_equal(entries[[2]]$type, "file")
})

test_that("pkgManifest writes manifest outputs with mocked GitHub resolution (#43)", {
  tmp <- tempfile("workr-pkg-manifest-")
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  resolve_calls <- list()

  local_mocked_bindings(
    resolve_package = function(org, repo, ref = NULL, date = NULL) {
      resolve_calls <<- append(
        resolve_calls,
        list(list(org = org, repo = repo, ref = ref, date = date))
      )
      list(
        org = org,
        repo = repo,
        version = "1.0.0",
        repository = paste0("https://github.com/", org, "/", repo),
        url = paste0(
          "https://github.com/",
          org,
          "/",
          repo,
          "/archive/sha-",
          repo,
          ".tar.gz"
        ),
        sha = paste0("sha-", repo),
        ref = ref
      )
    },
    pull_workflows = function(resolved, path) {
      dir.create(
        file.path(path, "workflows"),
        recursive = TRUE,
        showWarnings = FALSE
      )
      writeLines(
        "name: mocked-workflow",
        file.path(path, "workflows", "root.yaml")
      )
      invisible(NULL)
    }
  )

  out <- pkgManifest(
    path = tmp,
    packageList = c(
      "Gilead-BioStats/gsm.core@v1.2.3",
      "Gilead-BioStats/gsm.mapping"
    ),
    branch = "dev"
  )

  expect_true(file.exists(file.path(tmp, "manifest.csv")))
  expect_true(file.exists(file.path(tmp, "rproject.toml")))
  expect_true(file.exists(file.path(tmp, "workflows", "root.yaml")))
  expect_equal(nrow(out), 2)
  expect_equal(out$package, c("gsm.core", "gsm.mapping"))
  expect_equal(resolve_calls[[1]]$ref, "v1.2.3")
  expect_equal(resolve_calls[[2]]$ref, "dev")
})

test_that("pull_workflows skips packages with no workflow directory (#45)", {
  tmp <- tempfile("workr-pull-workflows-")
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  checked_dirs <- character()

  local_mocked_bindings(
    gh_list_contents = function(full_repo, dir_path, sha) {
      checked_dirs <<- c(checked_dirs, dir_path)
      NULL
    }
  )

  resolved <- list(list(
    org = "Gilead-BioStats",
    repo = "gsm.core",
    sha = "abc123"
  ))
  expect_message(
    pull_workflows(resolved, tmp),
    "No inst/workflow found"
  )
  expect_identical(checked_dirs, c("inst/workflow", "inst/workflows"))
  expect_true(dir.exists(file.path(tmp, "workflows")))
})

test_that("pull_workflows warns when only inst/workflows exists (#45)", {
  tmp <- tempfile("workr-pull-workflows-")
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  gh_calls <- character()
  file_calls <- character()

  local_mocked_bindings(
    gh_list_contents = function(full_repo, dir_path, sha) {
      gh_calls <<- c(gh_calls, dir_path)
      if (identical(dir_path, "inst/workflow")) {
        return(NULL)
      }
      list(list(
        type = "file",
        name = "root.yaml",
        path = "inst/workflows/root.yaml"
      ))
    },
    pull_workflow_file = function(
      full_repo,
      sha,
      api_path,
      local_path,
      source_repo = full_repo,
      seen_files = NULL
    ) {
      file_calls <<- c(
        file_calls,
        paste(full_repo, sha, api_path, local_path, sep = "|")
      )
      invisible(NULL)
    },
    .package = "workr"
  )

  resolved <- list(list(
    org = "Gilead-BioStats",
    repo = "grail",
    sha = "abc123"
  ))
  expect_warning(
    workr:::pull_workflows(resolved, tmp),
    "Found 'inst/workflows' instead"
  )

  expect_identical(gh_calls, c("inst/workflow", "inst/workflows"))
  expect_length(file_calls, 0)
})

test_that("pull_workflows dispatches file and directory entries (#43)", {
  tmp <- tempfile("workr-pull-workflows-")
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  dir_calls <- character()
  file_calls <- character()

  local_mocked_bindings(
    gh_list_contents = function(full_repo, dir_path, sha) {
      list(
        list(type = "dir", name = "0_other", path = "inst/workflow/0_other"),
        list(
          type = "file",
          name = "root.yaml",
          path = "inst/workflow/root.yaml"
        )
      )
    },
    pull_workflow_dir = function(
      full_repo,
      sha,
      api_path,
      local_dir,
      source_repo = full_repo,
      seen_files = NULL
    ) {
      dir_calls <<- c(
        dir_calls,
        paste(full_repo, sha, api_path, local_dir, sep = "|")
      )
      invisible(NULL)
    },
    pull_workflow_file = function(
      full_repo,
      sha,
      api_path,
      local_path,
      source_repo = full_repo,
      seen_files = NULL
    ) {
      file_calls <<- c(
        file_calls,
        paste(full_repo, sha, api_path, local_path, sep = "|")
      )
      invisible(NULL)
    }
  )

  resolved <- list(list(
    org = "Gilead-BioStats",
    repo = "gsm.core",
    sha = "abc123"
  ))
  pull_workflows(resolved, tmp)

  expect_length(dir_calls, 1)
  expect_length(file_calls, 1)
  dir_parts <- strsplit(dir_calls[[1]], "|", fixed = TRUE)[[1]]
  file_parts <- strsplit(file_calls[[1]], "|", fixed = TRUE)[[1]]
  expect_equal(dir_parts[1], "Gilead-BioStats/gsm.core")
  expect_equal(dir_parts[2], "abc123")
  expect_equal(dir_parts[3], "inst/workflow/0_other")
  expect_equal(basename(dir_parts[4]), "0_other")
  expect_equal(file_parts[1], "Gilead-BioStats/gsm.core")
  expect_equal(file_parts[2], "abc123")
  expect_equal(file_parts[3], "inst/workflow/root.yaml")
  expect_equal(basename(file_parts[4]), "root.yaml")
})

test_that("pull_workflow_file skips write when content lookup is Not Found (#43)", {
  tmp <- tempfile("workr-pull-workflow-file-")
  on.exit(unlink(tmp, force = TRUE), add = TRUE)

  local_mocked_bindings(
    gh_api_client = function(args) {
      "Not Found"
    }
  )

  pull_workflow_file(
    full_repo = "Gilead-BioStats/gsm.core",
    sha = "abc123",
    api_path = "inst/workflow/root.yaml",
    local_path = tmp
  )

  expect_false(file.exists(tmp))
})

test_that("pull_workflow_file writes decoded file when content is available (#43)", {
  tmp <- tempfile("workr-pull-workflow-file-")
  on.exit(unlink(tmp, force = TRUE), add = TRUE)

  local_mocked_bindings(
    gh_api_client = function(args) {
      base64enc::base64encode(charToRaw("name: workflow\n"))
    }
  )

  pull_workflow_file(
    full_repo = "Gilead-BioStats/gsm.core",
    sha = "abc123",
    api_path = "inst/workflow/root.yaml",
    local_path = tmp
  )

  expect_true(file.exists(tmp))
  expect_identical(readLines(tmp)[1], "name: workflow")
})

test_that("pull_workflows does not register missing files as collisions (#46)", {
  tmp <- tempfile("workr-pull-workflows-missing-content-")
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  local_mocked_bindings(
    gh_list_contents = function(full_repo, dir_path, sha) {
      if (!identical(dir_path, "inst/workflow")) {
        return(NULL)
      }
      list(list(
        type = "file",
        name = "root.yaml",
        path = "inst/workflow/root.yaml"
      ))
    },
    gh_api_client = function(args) {
      cmd <- paste(args, collapse = " ")
      if (
        grepl(
          "repos/Gilead-BioStats/pkg.one/contents/inst/workflow/root.yaml\\?ref=sha1",
          cmd
        )
      ) {
        return("Not Found")
      }
      if (
        grepl(
          "repos/Gilead-BioStats/pkg.two/contents/inst/workflow/root.yaml\\?ref=sha2",
          cmd
        )
      ) {
        return(base64enc::base64encode(charToRaw("name: pkg.two\n")))
      }
      stop("Unexpected gh_api_client args: ", cmd)
    },
    .package = "workr"
  )

  resolved <- list(
    list(org = "Gilead-BioStats", repo = "pkg.one", sha = "sha1"),
    list(org = "Gilead-BioStats", repo = "pkg.two", sha = "sha2")
  )

  workr:::pull_workflows(resolved, tmp)

  expect_identical(
    readLines(file.path(tmp, "workflow", "root.yaml"))[1],
    "name: pkg.two"
  )
})

test_that("pull_workflows warns on destination collisions by default (#46)", {
  tmp <- tempfile("workr-pull-workflows-collision-")
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  local_mocked_bindings(
    gh_list_contents = function(full_repo, dir_path, sha) {
      if (!identical(dir_path, "inst/workflow")) {
        return(NULL)
      }
      list(list(
        type = "file",
        name = "root.yaml",
        path = "inst/workflow/root.yaml"
      ))
    },
    gh_api_client = function(args) {
      cmd <- paste(args, collapse = " ")
      if (
        grepl(
          "repos/Gilead-BioStats/pkg.one/contents/inst/workflow/root.yaml\\?ref=sha1",
          cmd
        )
      ) {
        return(base64enc::base64encode(charToRaw("name: pkg.one\n")))
      }
      if (
        grepl(
          "repos/Gilead-BioStats/pkg.two/contents/inst/workflow/root.yaml\\?ref=sha2",
          cmd
        )
      ) {
        return(base64enc::base64encode(charToRaw("name: pkg.two\n")))
      }
      stop("Unexpected gh_api_client args: ", cmd)
    },
    .package = "workr"
  )

  resolved <- list(
    list(org = "Gilead-BioStats", repo = "pkg.one", sha = "sha1"),
    list(org = "Gilead-BioStats", repo = "pkg.two", sha = "sha2")
  )

  expect_warning(
    workr:::pull_workflows(resolved, tmp),
    "Workflow destination collision.*pkg\\.one.*pkg\\.two"
  )
  expect_identical(
    readLines(file.path(tmp, "workflow", "root.yaml"))[1],
    "name: pkg.two"
  )
})

test_that("pull_workflows warns on nested destination collisions in directories (#46)", {
  tmp <- tempfile("workr-pull-workflows-collision-nested-")
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  local_mocked_bindings(
    gh_list_contents = function(full_repo, dir_path, sha) {
      if (identical(dir_path, "inst/workflow")) {
        return(list(list(
          type = "dir",
          name = "shared",
          path = "inst/workflow/shared"
        )))
      }
      if (identical(dir_path, "inst/workflow/shared")) {
        return(list(list(
          type = "file",
          name = "nested.yaml",
          path = "inst/workflow/shared/nested.yaml"
        )))
      }
      NULL
    },
    gh_api_client = function(args) {
      cmd <- paste(args, collapse = " ")
      if (
        grepl(
          "repos/Gilead-BioStats/pkg.one/contents/inst/workflow/shared/nested.yaml\\?ref=sha1",
          cmd
        )
      ) {
        return(base64enc::base64encode(charToRaw("name: pkg.one.nested\n")))
      }
      if (
        grepl(
          "repos/Gilead-BioStats/pkg.two/contents/inst/workflow/shared/nested.yaml\\?ref=sha2",
          cmd
        )
      ) {
        return(base64enc::base64encode(charToRaw("name: pkg.two.nested\n")))
      }
      stop("Unexpected gh_api_client args: ", cmd)
    },
    .package = "workr"
  )

  resolved <- list(
    list(org = "Gilead-BioStats", repo = "pkg.one", sha = "sha1"),
    list(org = "Gilead-BioStats", repo = "pkg.two", sha = "sha2")
  )

  expect_warning(
    workr:::pull_workflows(resolved, tmp),
    "Workflow destination collision.*pkg\\.one.*pkg\\.two"
  )
  expect_identical(
    readLines(file.path(tmp, "workflow", "shared", "nested.yaml"))[1],
    "name: pkg.two.nested"
  )
})

test_that("pull_workflows warns and skips file-vs-directory structural collisions (#46)", {
  tmp <- tempfile("workr-pull-workflows-structural-")
  dir.create(tmp, recursive = TRUE)
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)

  requested_api_paths <- character()

  local_mocked_bindings(
    gh_list_contents = function(full_repo, dir_path, sha) {
      if (
        identical(full_repo, "Gilead-BioStats/pkg.one") &&
          identical(dir_path, "inst/workflow")
      ) {
        return(list(list(
          type = "file",
          name = "foo",
          path = "inst/workflow/foo"
        )))
      }
      if (
        identical(full_repo, "Gilead-BioStats/pkg.two") &&
          identical(dir_path, "inst/workflow")
      ) {
        return(list(list(
          type = "dir",
          name = "foo",
          path = "inst/workflow/foo"
        )))
      }
      if (
        identical(full_repo, "Gilead-BioStats/pkg.two") &&
          identical(dir_path, "inst/workflow/foo")
      ) {
        return(list(list(
          type = "file",
          name = "bar.yaml",
          path = "inst/workflow/foo/bar.yaml"
        )))
      }
      NULL
    },
    gh_api_client = function(args) {
      path_arg <- grep("^repos/.*/contents/", args, value = TRUE)
      requested_api_paths <<- c(requested_api_paths, path_arg)
      base64enc::base64encode(charToRaw("name: pkg.one.file\n"))
    },
    .package = "workr"
  )

  resolved <- list(
    list(org = "Gilead-BioStats", repo = "pkg.one", sha = "sha1"),
    list(org = "Gilead-BioStats", repo = "pkg.two", sha = "sha2")
  )

  expect_warning(
    workr:::pull_workflows(resolved, tmp),
    "Cannot create workflow directory"
  )
  expect_true(file.exists(file.path(tmp, "workflow", "foo")))
  expect_false(file.exists(file.path(tmp, "workflow", "foo", "bar.yaml")))
  expect_equal(
    length(grep(
      "pkg.two/contents/inst/workflow/foo/bar.yaml",
      requested_api_paths
    )),
    0
  )
})
