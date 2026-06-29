# lWFToFilter and lWFToFilterAll are defined in helper-MakeWorkflowList.R

test_that("FilterWorkflows.character filters single-value meta field (#72)", {
  {
    result <- FilterWorkflows(lWFToFilter, Category = "kri")
  } |>
    expect_message("Keeping 2 of 5 workflows where Category matches kri.") |>
    expect_message("Kept 2 of 5 workflows after applying 1 filter")
  expect_named(result, c("kri_only", "multi_category"))
})

test_that("FilterWorkflows.character filters list-valued meta field (#72)", {
  {
    result <- FilterWorkflows(lWFToFilter, Category = "site_risk_score")
  } |>
    expect_message(
      "Keeping 1 of 5 workflows where Category matches site_risk_score."
    ) |>
    expect_message("Kept 1 of 5 workflows after applying 1 filter")
  expect_named(result, "multi_category")
})

test_that("FilterWorkflows.character supports multiple allowed values (#72)", {
  {
    result <- FilterWorkflows(lWFToFilter, Category = c("kri", "country"))
  } |>
    expect_message(
      "Keeping 3 of 5 workflows where Category matches kri, country."
    ) |>
    expect_message("Kept 3 of 5 workflows after applying 1 filter")
  expect_named(result, c("country_only", "kri_only", "multi_category"))
})

test_that("FilterWorkflows.character is case-insensitive (#72)", {
  {
    result_lower <- FilterWorkflows(lWFToFilter, Category = "kri")
  } |>
    expect_message("Keeping 2 of 5 workflows where Category matches kri.") |>
    expect_message("Kept 2 of 5 workflows after applying 1 filter")
  {
    result_upper <- FilterWorkflows(lWFToFilter, Category = "KRI")
  } |>
    expect_message("Keeping 2 of 5 workflows where Category matches KRI.") |>
    expect_message("Kept 2 of 5 workflows after applying 1 filter")
  {
    result_mixed <- FilterWorkflows(lWFToFilter, category = "KrI")
  } |>
    expect_message("Keeping 2 of 5 workflows where category matches KrI.") |>
    expect_message("Kept 2 of 5 workflows after applying 1 filter")
  expect_named(result_upper, names(result_lower))
  expect_named(result_mixed, names(result_lower))
})

test_that("FilterWorkflows.character returns empty list for no match (#72)", {
  {
    result <- FilterWorkflows(lWFToFilter, Category = "nonexistent_category")
  } |>
    expect_message(
      "Keeping 0 of 5 workflows where Category matches nonexistent_category."
    ) |>
    expect_message("Kept 0 of 5 workflows after applying 1 filter")
  expect_length(result, 0)
})

test_that("FilterWorkflows.character excludes workflows missing the field (#72)", {
  # no_category has no Category field; null_category has Category: ~ (NULL).
  # By design, both are excluded.
  {
    result <- FilterWorkflows(lWFToFilter, Category = "kri")
  } |>
    expect_message("Keeping 2 of 5 workflows where Category matches kri.") |>
    expect_message("Kept 2 of 5 workflows after applying 1 filter")
  expect_false("no_category" %in% names(result))
  expect_false("null_category" %in% names(result))
})

test_that("FilterWorkflows.character excludes workflows with NULL field value (#72)", {
  # null_category has Category: ~ which parses to NULL — excluded by is.null() guard
  {
    result <- FilterWorkflows(lWFToFilter, Category = "kri")
  } |>
    expect_message("Keeping 2 of 5 workflows where Category matches kri.") |>
    expect_message("Kept 2 of 5 workflows after applying 1 filter")
  expect_false("null_category" %in% names(result))
})

test_that("FilterWorkflows.logical filters by TRUE (#72)", {
  {
    result <- FilterWorkflows(lWFToFilterAll, Active = TRUE)
  } |>
    expect_message("Keeping 5 of 6 workflows where Active matches TRUE.") |>
    expect_message("Kept 5 of 6 workflows after applying 1 filter")
  expect_named(
    result,
    c(
      "country_only",
      "kri_only",
      "multi_category",
      "no_category",
      "null_category"
    )
  )
})

test_that("FilterWorkflows.logical filters by FALSE (#72)", {
  {
    result <- FilterWorkflows(lWFToFilterAll, Active = FALSE)
  } |>
    expect_message("Keeping 1 of 6 workflows where Active matches FALSE.") |>
    expect_message("Kept 1 of 6 workflows after applying 1 filter")
  expect_named(result, "inactive_kri")
})

test_that("FilterWorkflows.logical field lookup is case-insensitive (#72)", {
  {
    result_lower <- FilterWorkflows(lWFToFilterAll, active = TRUE)
  } |>
    expect_message("Keeping 5 of 6 workflows where active matches TRUE.") |>
    expect_message("Kept 5 of 6 workflows after applying 1 filter")
  {
    result_upper <- FilterWorkflows(lWFToFilterAll, Active = TRUE)
  } |>
    expect_message("Keeping 5 of 6 workflows where Active matches TRUE.") |>
    expect_message("Kept 5 of 6 workflows after applying 1 filter")
  expect_named(result_upper, names(result_lower))
})

test_that("FilterWorkflows.default errors on unsupported value type (#72)", {
  {
    FilterWorkflows(lWFToFilter, Category = list("kri"))
  } |>
    expect_error("Unsupported filter value type")
})

test_that("FilterWorkflows.numeric filters by single value (#72)", {
  {
    result <- FilterWorkflows(lWFToFilter, Version = 2)
  } |>
    expect_message("Keeping 2 of 5 workflows where Version matches 2.") |>
    expect_message("Kept 2 of 5 workflows after applying 1 filter")
  expect_named(result, c("country_only", "kri_only"))
})

test_that("FilterWorkflows.numeric filters by multiple values (#72)", {
  {
    result <- FilterWorkflows(lWFToFilter, Version = c(1, 2))
  } |>
    expect_message("Keeping 3 of 5 workflows where Version matches 1, 2.") |>
    expect_message("Kept 3 of 5 workflows after applying 1 filter")
  expect_named(result, c("country_only", "kri_only", "multi_category"))
})

test_that("FilterWorkflows errors on unnamed ... argument (#72)", {
  {
    FilterWorkflows(lWFToFilter, "kri")
  } |>
    expect_error("All filters in `\\.\\.\\.` must be named")
})

test_that("FilterWorkflows.logical excludes workflows with non-coercible Active value (#72)", {
  # Build a minimal workflow list with Active: yes (non-coercible to logical)
  lWf <- list(
    wf1 = list(
      meta = list(Type = "metric", ID = "wf1", Active = "yes"),
      steps = list()
    ),
    wf2 = list(
      meta = list(Type = "metric", ID = "wf2", Active = TRUE),
      steps = list()
    )
  )
  {
    result <- FilterWorkflows(lWf, Active = FALSE)
  } |>
    expect_message("Keeping 0 of 2") |>
    expect_message("Kept 0 of 2")
  # wf1 has non-coercible "yes" — excluded rather than kept as FALSE match
  expect_length(result, 0)
})

test_that("FilterWorkflows.integer dispatches to numeric method (#72)", {
  {
    result <- FilterWorkflows(lWFToFilter, Version = 2L)
  } |>
    expect_message("Keeping 2 of 5 workflows where Version matches 2.") |>
    expect_message("Kept 2 of 5 workflows after applying 1 filter")
  expect_named(result, c("country_only", "kri_only"))
})

test_that(".keep_workflows warns and uses first key when meta has duplicate case-variant keys (#72)", {
  # Duplicate keys aren't possible in YAML, so construct the list directly
  lWf <- list(
    wf1 = list(
      meta = list(
        Type = "metric",
        ID = "wf1",
        Category = "kri",
        category = "other"
      ),
      steps = list()
    )
  )
  {
    result <- FilterWorkflows(lWf, Category = "kri")
  } |>
    expect_message("Multiple meta keys match field") |>
    expect_message("Keeping 1 of 1") |>
    expect_message("Kept 1 of 1")
  expect_named(result, "wf1")
})
