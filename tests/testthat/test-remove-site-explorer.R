# Tests for issue #19: Remove Legacy /site Explorer From workr
# These verify that all explorer/site artifacts have been removed.
# Skipped during R CMD check (repo root files not in tarball).

repo_root <- file.path(testthat::test_path(), "..", "..")
skip_if_not_repo <- function() {
  testthat::skip_if_not(
    dir.exists(file.path(repo_root, ".git")),
    "Not running from source repo (e.g., R CMD check)"
  )
}

test_that("site/ directory does not exist #19", {
  skip_if_not_repo()
  expect_false(dir.exists(file.path(repo_root, "site")))
})

test_that("site-build.yaml workflow does not exist #19", {
  skip_if_not_repo()
  expect_false(file.exists(file.path(repo_root, ".github", "workflows", "site-build.yaml")))
})

test_that("site-deploy.yaml workflow does not exist #19", {
  skip_if_not_repo()
  expect_false(file.exists(file.path(repo_root, ".github", "workflows", "site-deploy.yaml")))
})

test_that("pkgdown-all.yaml has no Node/explorer steps #19", {
  skip_if_not_repo()
  wf <- file.path(repo_root, ".github", "workflows", "pkgdown-all.yaml")
  lines <- readLines(wf)
  expect_false(any(grepl("setup-node", lines)), info = "setup-node reference found")
  expect_false(any(grepl("npm ci", lines)), info = "npm ci reference found")
  expect_false(any(grepl("explorer-build", lines)), info = "explorer-build reference found")
})

test_that("_pkgdown.yml has no explorer navbar entry #19", {
  skip_if_not_repo()
  lines <- readLines(file.path(repo_root, "_pkgdown.yml"))
  expect_false(any(grepl("explorer", lines, ignore.case = TRUE)))
})

test_that(".gitignore has no site/node_modules/ entry #19", {
  skip_if_not_repo()
  lines <- readLines(file.path(repo_root, ".gitignore"))
  expect_false(any(grepl("site/node_modules", lines, fixed = TRUE)))
})
