# Using the gsm.datasim Load Provider

## Install the optional dependency

The built-in `"gsm.datasim"` provider uses the development version of
the optional
[gsm.datasim](https://github.com/Gilead-BioStats/gsm.datasim) package.

``` r

pak::pak("Gilead-BioStats/gsm.datasim@dev")
```

## Define a workflow

This workflow summarizes enrolled subjects by simulated site after
[`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
loads data with the configured provider.

``` r

library(workr)

example_workflow <- list(
  meta = list(Type = "example", ID = "single_snapshot"),
  steps = list(
    list(
      name = "workr::RunQuery",
      output = "enrolled_subjects_by_site",
      params = list(
        df = "Raw_SUBJ",
        strQuery = paste(
          "SELECT",
          "  invid AS site_id,",
          "  COUNT(*) AS enrolled_subjects,",
          "  AVG(timeonstudy) AS mean_time_on_study",
          "FROM df",
          "WHERE enrollyn = 'Y'",
          "GROUP BY invid",
          "ORDER BY enrolled_subjects DESC",
          sep = "\n"
        )
      )
    )
  )
)
```

## Run a single-snapshot simulation

Set `lConfig$LoadData` to `"gsm.datasim"` and pass provider settings
through `lConfig$gsm.datasim`.

``` r

single_snapshot <- workr::RunWorkflow(
  lWorkflow = example_workflow,
  lData = list(caller_value = 11),
  lConfig = list(
    LoadData = "gsm.datasim",
    gsm.datasim = list(
      profile = "standard",
      study_type = "standard",
      participants = 25,
      sites = 4,
      snapshot_count = 1
    )
  ),
  bReturnResult = FALSE
)

sort(names(single_snapshot$lData))
head(single_snapshot$lData$Raw_SUBJ)
head(single_snapshot$lData$enrolled_subjects_by_site)
identical(single_snapshot$lData$Raw_SUBJ, single_snapshot$lData$dfSUBJ)
```

## Run a longitudinal simulation

For longitudinal settings, the provider returns the latest snapshot by
default. Use `snapshot` to select a different 1-based snapshot index.

``` r

longitudinal_workflow <- example_workflow
longitudinal_workflow$meta$ID <- "longitudinal_case"

latest_snapshot <- workr::RunWorkflow(
  lWorkflow = longitudinal_workflow,
  lConfig = list(
    LoadData = "gsm.datasim",
    gsm.datasim = list(
      study_type = "endpoints",
      months_duration = 2,
      participants = 10,
      sites = 3
    )
  ),
  bReturnResult = FALSE
)

sort(names(latest_snapshot$lData))
head(latest_snapshot$lData$Raw_SUBJ)
```

The same runnable example is available at
`inst/examples/gsm-datasim-provider.R`.
