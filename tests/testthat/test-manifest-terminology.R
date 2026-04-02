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

test_that("pkgManifest documentation is clear #25", {
  # Roxygen docs should clearly state this creates a manifest
  help_file <- readLines(system.file("man/pkgManifest.Rd", package = "workr"))
  doc_text <- paste(help_file, collapse = " ")
  
  # Should mention manifest, not be ambiguous about snapshot
  expect_match(doc_text, "manifest", ignore.case = TRUE)
})

test_that("pkgSnapshot function name is deprecated/removed #25", {
  # After refactor, old name should not exist
  expect_false(exists("pkgSnapshot"))
})

test_that("pkgListFromManifest references correct function #25", {
  # Examples and documentation should reference pkgManifest, not pkgSnapshot
  help_file <- readLines(system.file("man/pkgListFromManifest.Rd", package = "workr"))
  doc_text <- paste(help_file, collapse = " ")
  
  # Should reference pkgManifest, not pkgSnapshot (ambiguous name)
  expect_match(doc_text, "pkgManifest", ignore.case = FALSE)
  expect_false(grepl("pkgSnapshot", doc_text))
})

test_that("workflow files use manifest terminology #25", {
  # Check that snapshot.yaml and related are updated/renamed
  workflow_dir <- system.file(".github/workflows", package = "workr", mustWork = FALSE)
  
  if (dir.exists(workflow_dir)) {
    workflow_files <- list.files(workflow_dir, full.names = TRUE)
    
    # Should have manifest.yaml or similar, not snapshot.yaml
    snapshot_yaml_files <- grep("snapshot\\.yaml$", workflow_files, value = TRUE)
    manifest_yaml_files <- grep("manifest\\.yaml$", workflow_files, value = TRUE)
    
    # After refactor: manifest.yaml exists, snapshot.yaml does not
    expect_length(manifest_yaml_files, 1)
    expect_length(snapshot_yaml_files, 0)
  }
})

test_that("README clearly distinguishes manifest from snapshot #25", {
  readme_file <- readLines(system.file("README.md", package = "workr"))
  readme_text <- paste(readme_file, collapse = "\n")
  
  # Should have clear explanation of manifest vs snapshot terminology
  expect_match(readme_text, "manifest", ignore.case = TRUE)
  expect_match(readme_text, "snapshot", ignore.case = TRUE)
  
  # Both should be present and clearly explained
  expect_match(readme_text, "package.*manifest|manifest.*package", ignore.case = TRUE)
  expect_match(readme_text, "execution.*snapshot|snapshot.*execution|snapshot.*output|output.*snapshot", ignore.case = TRUE)
})
