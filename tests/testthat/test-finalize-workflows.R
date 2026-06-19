# Tests for issue (#34): Finalize inst/example_workflows and demo Shiny app
# Verify 03_KRI uses local mock data (not gsm.core::lSource), 03_AEKRI removed,
# and README links to the hosted app.

repo_root <- file.path(testthat::test_path(), "..", "..")
skip_if_not_repo <- function() {
  testthat::skip_if_not(
    dir.exists(file.path(repo_root, ".git")),
    "Not running from source repo (e.g., R CMD check)"
  )
}

kri_init <- file.path(
  repo_root,
  "inst",
  "example_workflows",
  "03_KRI",
  "initData.R"
)

test_that("03_AEKRI directory does not exist (#34)", {
  skip_if_not_repo()
  expect_false(dir.exists(file.path(
    repo_root,
    "inst",
    "example_workflows",
    "03_AEKRI"
  )))
})

test_that("03_KRI initData.R does not reference gsm.core::lSource (#34)", {
  skip_if_not_repo()
  lines <- readLines(kri_init)
  expect_false(
    any(grepl("gsm\\.core::lSource", lines)),
    info = "initData.R still references gsm.core::lSource"
  )
})

test_that("03_KRI initData.R does not reference PD domain (#34)", {
  skip_if_not_repo()
  lines <- readLines(kri_init)
  expect_false(
    any(grepl("Raw_PD|rawplus_pd|pd\\s*<-", lines, ignore.case = TRUE)),
    info = "initData.R still references PD domain"
  )
})

test_that("03_KRI initData.R does not reference clindata package (#34)", {
  skip_if_not_repo()
  lines <- readLines(kri_init)
  expect_false(
    any(grepl("clindata::", lines)),
    info = "initData.R still references clindata package"
  )
})

test_that("03_KRI initData.R returns Raw_SUBJ and Raw_AE (#34)", {
  skip_if_not_repo()
  lines <- readLines(kri_init)
  combined <- paste(lines, collapse = "\n")
  expect_true(
    grepl("Raw_SUBJ", combined),
    info = "Missing Raw_SUBJ in return list"
  )
  expect_true(grepl("Raw_AE", combined), info = "Missing Raw_AE in return list")
})

test_that("03_KRI RunWorkflows completes without error using initData (#34)", {
  skip_if_not_repo()
  skip_if_not_installed("gsm.core")

  kri_path <- file.path(repo_root, "inst", "example_workflows", "03_KRI")
  lWorkflows <- suppressMessages(MakeWorkflowList(strPath = kri_path))
  lConfig <- list(LoadData = loadExample)

  expect_no_error(
    suppressMessages(RunWorkflows(lWorkflows = lWorkflows, lConfig = lConfig))
  )
})

test_that("README contains link to hosted shinyapps.io demo (#34)", {
  skip_if_not_repo()
  lines <- readLines(file.path(repo_root, "README.md"))
  expect_true(
    any(grepl("shinyapps\\.io", lines)),
    info = "README does not contain shinyapps.io link"
  )
})
