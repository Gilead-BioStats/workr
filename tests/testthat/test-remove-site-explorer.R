# Tests for issue #19: Remove Legacy /site Explorer From workr
# These verify that all explorer/site artifacts have been removed.

test_that("site/ directory does not exist #19", {
  site_dir <- file.path(testthat::test_path(), "..", "..", "site")
  expect_false(dir.exists(site_dir))
})

test_that("site-build.yaml workflow does not exist #19", {
  wf <- file.path(testthat::test_path(), "..", "..", ".github", "workflows", "site-build.yaml")
  expect_false(file.exists(wf))
})

test_that("site-deploy.yaml workflow does not exist #19", {
  wf <- file.path(testthat::test_path(), "..", "..", ".github", "workflows", "site-deploy.yaml")
  expect_false(file.exists(wf))
})

test_that("pkgdown-with-examples.yaml has no Node/explorer steps #19", {
  wf <- file.path(testthat::test_path(), "..", "..", ".github", "workflows", "pkgdown-with-examples.yaml")
  lines <- readLines(wf)
  expect_false(any(grepl("setup-node", lines)), info = "setup-node reference found")
  expect_false(any(grepl("npm ci", lines)), info = "npm ci reference found")
  expect_false(any(grepl("explorer-build", lines)), info = "explorer-build reference found")
})

test_that("_pkgdown.yml has no explorer navbar entry #19", {
  yml <- file.path(testthat::test_path(), "..", "..", "_pkgdown.yml")
  lines <- readLines(yml)
  expect_false(any(grepl("explorer", lines, ignore.case = TRUE)))
})

test_that(".gitignore has no site/node_modules/ entry #19", {
  gi <- file.path(testthat::test_path(), "..", "..", ".gitignore")
  lines <- readLines(gi)
  expect_false(any(grepl("site/node_modules", lines, fixed = TRUE)))
})
