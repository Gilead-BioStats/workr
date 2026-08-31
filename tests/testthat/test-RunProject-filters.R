# Filtering a project by workflow metadata: one catalog, several schedules.
# The filtering itself belongs to FilterWorkflows() and is tested there; what
# these cover is that RunProject()/RunStudy() reach it, and that a filter
# behaves as a strict subset rather than a preference.

write_cadence_workflow <- function(project_path, phase, id, cadence) {
  phase_path <- file.path(project_path, phase)
  dir.create(phase_path, recursive = TRUE, showWarnings = FALSE)

  yaml::write_yaml(
    list(
      meta = list(Type = "phase", ID = id, Cadence = cadence),
      steps = list(list(name = "base::identity", output = "out", params = list(x = id)))
    ),
    file.path(phase_path, paste0(id, ".yaml"))
  )
}

test_that("lFilters restricts a phase to matching workflows", {
  project_path <- withr::local_tempdir()
  write_cadence_workflow(project_path, "1_phase", "weekly_only", "cadence1")
  write_cadence_workflow(project_path, "1_phase", "both", c("cadence1", "cadence2"))

  results <- RunProject(
    strPath = project_path,
    lFilters = list(Cadence = "cadence2"),
    bContinueOnError = TRUE
  )

  expect_named(results$results[["1_phase"]]$results, "phase_both")
})

test_that("a workflow matches when the filtered value is one of several", {
  project_path <- withr::local_tempdir()
  write_cadence_workflow(project_path, "1_phase", "both", c("cadence1", "cadence2"))

  # The YAML carries a vector; matching is any-of, so each cadence sees it.
  for (cadence in c("cadence1", "cadence2")) {
    results <- RunProject(
      strPath = project_path,
      lFilters = list(Cadence = cadence),
      bContinueOnError = TRUE
    )
    expect_named(results$results[["1_phase"]]$results, "phase_both")
  }
})

test_that("a workflow without the filtered field is excluded", {
  project_path <- withr::local_tempdir()
  write_project_workflow(project_path, "1_phase", "unlabelled")

  results <- RunProject(
    strPath = project_path,
    lFilters = list(Cadence = "cadence2"),
    bContinueOnError = TRUE
  )

  expect_length(results$results[["1_phase"]]$results, 0)
})

test_that("no filters runs everything", {
  project_path <- withr::local_tempdir()
  write_cadence_workflow(project_path, "1_phase", "one", "cadence1")
  write_project_workflow(project_path, "1_phase", "two")

  results <- RunProject(strPath = project_path, bContinueOnError = TRUE)

  expect_length(results$results[["1_phase"]]$results, 2)
})

test_that("study_filters merges caller overrides over declared defaults", {
  # YAML hands multi-valued fields over as lists; FilterWorkflows dispatches on
  # class, so they have to arrive as atomic vectors.
  expect_equal(
    study_filters(list(Cadence = list("cadence1", "cadence2"))),
    list(Cadence = c("cadence1", "cadence2"))
  )
  expect_equal(
    study_filters(list(Cadence = "cadence1"), list(Cadence = "cadence2")),
    list(Cadence = "cadence2")
  )
  expect_equal(
    study_filters(list(Cadence = "cadence1"), list(Type = "Analysis")),
    list(Cadence = "cadence1", Type = "Analysis")
  )
  expect_null(study_filters(NULL, NULL))
  # An empty value would filter on nothing and quietly keep everything.
  expect_null(study_filters(list(Cadence = character())))
})

test_that("study_filters_label renders multi-valued filters", {
  expect_equal(
    study_filters_label(list(Cadence = c("cadence1", "cadence2"), Type = "Analysis")),
    "Cadence=cadence1|cadence2, Type=Analysis"
  )
})
