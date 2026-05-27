## Adapted from gsm.core@dev test-util-MakeWorkflowList.R — see (#26)

test_that("MakeWorkflowList output is a named list with expected structure (#26)", {
  wf_list <- MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal", "00_Example")
  )

  expect_true(is.list(wf_list))
  expect_true(length(wf_list) > 0)
  expect_true(all(purrr::map_lgl(
    wf_list,
    ~ all(c("meta", "steps", "path") %in% names(.))
  )))
})

test_that("MakeWorkflowList returns metadata as expected (#26)", {
  wf_list <- MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal", "00_Example")
  )

  expect_true(all(purrr::map_lgl(wf_list, ~ "Type" %in% names(.x$meta))))
  expect_true(all(purrr::map_lgl(wf_list, ~ "ID" %in% names(.x$meta))))
})

test_that("MakeWorkflowList errors on invalid strPath (#26)", {
  MakeWorkflowList(strPath = "nonexistent_path_xyz", strPackage = NULL) |>
    expect_error("strPath")
})

test_that("MakeWorkflowList errors on invalid strPackage (#26)", {
  MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal", "00_Example"),
    strPackage = "fake-pkg-that-does-not-exist"
  ) |>
    expect_error("")
})

test_that("MakeWorkflowList filters by strNames (#26)", {
  wf_list <- MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal", "00_Example"),
    strNames = "cars"
  )

  expect_true("cars" %in% names(wf_list))
  expect_equal(length(wf_list), 1)
})

test_that("MakeWorkflowList bExact filters exactly (#26)", {
  # "car" partial match should find "cars" with bExact = FALSE
  wf_partial <- MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal", "00_Example"),
    strNames = "car",
    bExact = FALSE
  )
  expect_true(length(wf_partial) >= 1)

  # "car" exact match should NOT find "cars.yaml"
  expect_message(
    {
      wf_exact <- MakeWorkflowList(
        strPath = test_path("_fixtures", "workflow", "normal", "00_Example"),
        strNames = "car",
        bExact = TRUE
      )
    },
    "No workflows found"
  )
  expect_equal(length(wf_exact), 0)
})

test_that("MakeWorkflowList names list elements by meta$ID (#26)", {
  wf_list <- MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal", "00_Example")
  )

  # Verify list is named
  expect_true(!is.null(names(wf_list)))

  # Verify names match meta$ID values
  ids <- purrr::map_chr(wf_list, ~ .x$meta$ID)
  names_match <- all(names(wf_list) %in% ids) && all(ids %in% names(wf_list))
  expect_true(names_match)
})

test_that("MakeWorkflowList sorts by Priority (#26)", {
  # Create temp directory with two workflows at different priorities
  td <- tempfile("wf_priority_")
  dir.create(td, recursive = TRUE)
  on.exit(unlink(td, recursive = TRUE), add = TRUE)

  yaml::write_yaml(
    list(
      meta = list(Type = "test", ID = "low_priority", Priority = 10),
      steps = list(list(
        name = "identity",
        output = "res",
        params = list(x = "lData")
      ))
    ),
    file.path(td, "low_priority.yaml")
  )
  yaml::write_yaml(
    list(
      meta = list(Type = "test", ID = "high_priority", Priority = 1),
      steps = list(list(
        name = "identity",
        output = "res",
        params = list(x = "lData")
      ))
    ),
    file.path(td, "high_priority.yaml")
  )

  wf_list <- MakeWorkflowList(strPath = td)

  expect_equal(names(wf_list), c("high_priority", "low_priority"))
})

test_that("MakeWorkflowList sets default Priority to 0 (#26)", {
  wf_list <- MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal", "00_Example")
  )

  priorities <- purrr::map_dbl(wf_list, ~ .x$meta$Priority)
  expect_true(all(priorities == 0))
})

test_that("MakeWorkflowList loads from package (#26)", {
  wf_list <- MakeWorkflowList(
    strPath = "workflow",
    strPackage = "workr"
  )

  expect_true(is.list(wf_list))
  expect_true(length(wf_list) > 0)
})

test_that("MakeWorkflowList default strNames excludes inactive workflows #53", {
  wf_list <- MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active")
  )

  expect_true("active_metric" %in% names(wf_list))
  expect_true("no_active_field" %in% names(wf_list))
  expect_false("inactive_metric" %in% names(wf_list))
})

test_that("MakeWorkflowList with strNames = NULL includes all workflows #53", {
  wf_list <- MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active"),
    strNames = NULL
  )

  expect_true("active_metric" %in% names(wf_list))
  expect_true("no_active_field" %in% names(wf_list))
  expect_true("inactive_metric" %in% names(wf_list))
})

test_that("MakeWorkflowList with explicit strNames includes inactive workflows #53", {
  all_names <- c("active_metric", "inactive_metric", "no_active_field")
  wf_list <- MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal", "01_Active"),
    strNames = all_names,
    bExact = TRUE
  )

  expect_true("inactive_metric" %in% names(wf_list))
  expect_equal(length(wf_list), 3)
})

test_that("MakeWorkflowList warns when ID does not match filename (#26)", {
  MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "conditions", "mismatched_id")
  ) |>
    expect_message("ID.*attribute does not match")
})

test_that("MakeWorkflowList emits fatal message when meta is missing (#26)", {
  MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "conditions", "no_meta")
  ) |>
    expect_message("must contain `meta` attributes") |>
    expect_message("must contain `Type` attribute in `meta` section") |>
    expect_message("must contain `ID` attribute in `meta` section") |>
    expect_error("argument is of length zero")
})

test_that("MakeWorkflowList emits fatal message when steps is missing (#26)", {
  MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "conditions", "no_steps")
  ) |>
    expect_message("must contain.*steps.*attributes")
})

test_that("MakeWorkflowList emits fatal message when meta$Type is missing (#26)", {
  MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "conditions", "no_type")
  ) |>
    expect_message("must contain.*Type.*attribute")
})

test_that("MakeWorkflowList emits fatal message when meta$ID is missing (#26)", {
  MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "conditions", "no_id")
  ) |>
    expect_message("must contain `ID` attribute in `meta` section") |>
    expect_error("argument is of length zero")
})

test_that("MakeWorkflowList bRecursive finds nested workflows (#26)", {
  wf_recursive <- MakeWorkflowList(
    strPath = test_path("_fixtures", "workflow", "normal"),
    bRecursive = TRUE
  )
  expect_message(
    {
      wf_flat <- MakeWorkflowList(
        strPath = test_path("_fixtures", "workflow", "normal"),
        bRecursive = FALSE
      )
    },
    "No workflows found"
  )

  # Recursive should find workflows in 00_Example subdirectory
  expect_true(length(wf_recursive) >= length(wf_flat))
})
