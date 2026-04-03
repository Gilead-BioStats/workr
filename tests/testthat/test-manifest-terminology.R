test_that("pkgManifest function exists #25", {
  expect_true(exists("pkgManifest"))
  expect_true(is.function(pkgManifest))
})

test_that("pkgManifest has correct parameters #25", {
  # Parameters should indicate this operates on package manifest, not execution snapshot
  sig <- formals(pkgManifest)
  expect_true("path" %in% names(sig))
  expect_true("packageList" %in% names(sig))
  expect_true("date" %in% names(sig))
  expect_true("branch" %in% names(sig))
})

test_that("pkgSnapshot function name is deprecated/removed #25", {
  # After refactor, old name should not exist
  expect_false(exists("pkgSnapshot"))
})

test_that("pkgListFromManifest references correct function #25", {
  # Read from source (works both interactively and in R CMD check)
  rd_path <- testthat::test_path("../../man/pkgListFromManifest.Rd")
  skip_if(!file.exists(rd_path), "Man file not found (skipping doc check)")

  doc_text <- paste(readLines(rd_path), collapse = " ")

  # Should reference pkgManifest, not pkgSnapshot (ambiguous name)
  expect_match(doc_text, "pkgManifest", ignore.case = FALSE)
  expect_false(grepl("pkgSnapshot", doc_text))
})
