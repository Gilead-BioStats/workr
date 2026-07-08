# Load and Save Hooks

## Overview

[`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
and
[`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md)
accept an optional `lConfig` object with two data hooks:

- `LoadData`, called before workflow spec validation and before the
  first step runs.
- `SaveData`, called after the workflow steps finish when
  `bReturnResult = TRUE`.

Hooks make workflow definitions portable. The workflow can describe what
to run, while `lConfig` describes where data should come from and where
results should go in a particular environment.

## Example workflow

The examples below use a small workflow that summarizes a measure from
an analysis data frame. The workflow does not know how the data is
loaded or saved.

``` r

summarise_measure <- function(adsl, measure) {
  data.frame(
    measure = measure,
    n = nrow(adsl),
    mean = mean(adsl[[measure]])
  )
}

lWorkflow <- list(
  meta = list(
    Type = "demo",
    ID = "height",
    Source = "analysis"
  ),
  steps = list(
    list(
      name = "summarise_measure",
      output = "summary",
      params = list(
        adsl = "adsl",
        measure = "HEIGHTBL"
      )
    )
  )
)

analysis_data <- list(
  analysis = list(
    adsl = data.frame(
      USUBJID = sprintf("SUBJ%03d", 1:4),
      HEIGHTBL = c(160, 172, 168, 181)
    )
  )
)
```

## Inline hooks

For a single project, the simplest configuration is to provide functions
directly in `lConfig`.

`LoadData` must accept `lWorkflow`, `lConfig`, and `lData`. It returns
the data list that
[`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
should use.

`SaveData` must accept `lWorkflow` and `lConfig`. It can read the
completed workflow, including `lWorkflow$lData` and `lWorkflow$lResult`.

``` r

saved_results <- new.env(parent = emptyenv())

lConfig <- list(
  data_store = analysis_data,
  result_store = saved_results,
  LoadData = function(lWorkflow, lConfig, lData) {
    source_name <- lWorkflow$meta$Source
    c(lData, lConfig$data_store[[source_name]])
  },
  SaveData = function(lWorkflow, lConfig) {
    result_name <- paste(lWorkflow$meta$Type, lWorkflow$meta$ID, sep = "_")
    assign(result_name, lWorkflow$lResult, envir = lConfig$result_store)
    invisible(NULL)
  }
)

result <- workr::RunWorkflow(
  lWorkflow = lWorkflow,
  lData = list(),
  lConfig = lConfig
)

result
#>    measure n   mean
#> 1 HEIGHTBL 4 170.25
saved_results$demo_height
#>    measure n   mean
#> 1 HEIGHTBL 4 170.25
```

## Registered providers

When the same loading or saving behavior is shared across workflows or
projects, register a named provider once and reference it from `lConfig`
by name.

``` r

workr::register_load_provider(
  "vignette.memory.load",
  function(lWorkflow, lConfig, lData) {
    source_name <- lWorkflow$meta$Source
    c(lData, lConfig$data_store[[source_name]])
  }
)

workr::register_save_provider(
  "vignette.memory.save",
  function(lWorkflow, lConfig) {
    result_name <- paste(lWorkflow$meta$Type, lWorkflow$meta$ID, sep = "_")
    assign(result_name, lWorkflow$lResult, envir = lConfig$result_store)
    invisible(NULL)
  }
)

registered_results <- new.env(parent = emptyenv())

lRegisteredConfig <- list(
  data_store = analysis_data,
  result_store = registered_results,
  LoadData = "vignette.memory.load",
  SaveData = "vignette.memory.save"
)

workr::RunWorkflow(
  lWorkflow = lWorkflow,
  lData = list(),
  lConfig = lRegisteredConfig
)
#>    measure n   mean
#> 1 HEIGHTBL 4 170.25

registered_results$demo_height
#>    measure n   mean
#> 1 HEIGHTBL 4 170.25
```

Provider functions are validated when they are registered. `LoadData`
providers must include named formals `lWorkflow`, `lConfig`, and
`lData`; `SaveData` providers must include named formals `lWorkflow` and
`lConfig`.

## Using hooks with multiple workflows

[`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md)
passes the same `lConfig` through to each workflow. This lets a project
use one loading and saving strategy while each workflow selects the data
it needs from `meta`.

``` r

lWeightWorkflow <- lWorkflow
lWeightWorkflow$meta$ID <- "weight"
lWeightWorkflow$steps[[1]]$params$measure <- "WEIGHTBL"

analysis_data$analysis$adsl$WEIGHTBL <- c(60, 72, 68, 81)

multi_results <- new.env(parent = emptyenv())
lRegisteredConfig$result_store <- multi_results
lRegisteredConfig$data_store <- analysis_data

workr::RunWorkflows(
  lWorkflows = list(lWorkflow, lWeightWorkflow),
  lData = list(),
  lConfig = lRegisteredConfig
)
#> $demo_height
#>    measure n   mean
#> 1 HEIGHTBL 4 170.25
#> 
#> $demo_weight
#>    measure n  mean
#> 1 WEIGHTBL 4 70.25

multi_results$demo_height
#>    measure n   mean
#> 1 HEIGHTBL 4 170.25
multi_results$demo_weight
#>    measure n  mean
#> 1 WEIGHTBL 4 70.25
```

`lConfig` can be either a list or an environment. This is useful when an
existing application already stores configuration in an environment,
such as a Shiny app or project runtime.

``` r

env_results <- new.env(parent = emptyenv())
lEnvironmentConfig <- list2env(
  list(
    data_store = analysis_data,
    result_store = env_results,
    LoadData = "vignette.memory.load",
    SaveData = "vignette.memory.save"
  ),
  parent = emptyenv()
)

workr::RunWorkflow(
  lWorkflow = lWorkflow,
  lData = list(),
  lConfig = lEnvironmentConfig
)
#>    measure n   mean
#> 1 HEIGHTBL 4 170.25

env_results$demo_height
#>    measure n   mean
#> 1 HEIGHTBL 4 170.25
```

## Loading simulated data

`workr` also includes a built-in registered `LoadData` provider named
`"gsm.datasim"`. The provider uses the optional `gsm.datasim` package to
generate input data, adds legacy `df*` aliases for generated `Raw_*`
objects, and merges those generated objects with any caller-supplied
`lData`.

Install or update the optional dependency from the `dev` branch before
running the example locally:

``` r

pak::pak("Gilead-BioStats/gsm.datasim@dev")
```

The example is evaluated only when `gsm.datasim` is installed.

``` r

summarise_enrollment <- function(Raw_SUBJ) {
  aggregate(
    Raw_SUBJ$subjid,
    by = list(site_id = Raw_SUBJ$invid),
    FUN = length
  ) |>
    setNames(c("site_id", "enrolled_subjects"))
}

lDatasimWorkflow <- list(
  meta = list(Type = "demo", ID = "datasim_enrollment"),
  steps = list(
    list(
      name = "summarise_enrollment",
      output = "enrollment_summary",
      params = list(Raw_SUBJ = "Raw_SUBJ")
    )
  )
)

datasim_results <- new.env(parent = emptyenv())

workr::RunWorkflow(
  lWorkflow = lDatasimWorkflow,
  lData = list(),
  lConfig = list(
    LoadData = "gsm.datasim",
    SaveData = function(lWorkflow, lConfig) {
      assign("enrollment_summary", lWorkflow$lResult, envir = lConfig$result_store)
      assign("loaded_names", sort(names(lWorkflow$lData)), envir = lConfig$result_store)
      invisible(NULL)
    },
    result_store = datasim_results,
    gsm.datasim = list(
      profile = "standard",
      study_type = "standard",
      participants = 25,
      sites = 4,
      snapshot_count = 1
    )
  )
)
#> INFO [2026-07-08 20:46:59]  -- Adding snapshot 1...
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_SITE...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_SITE added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_SUBJ...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_SUBJ added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_ENROLL...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_ENROLL added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_VISIT...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_VISIT added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_STUDCOMP...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_STUDCOMP added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_AE...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_AE added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_IE...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_IE added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_LB...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_LB added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_OverallResponse...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_OverallResponse added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_PD...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_PD added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_Randomization...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_Randomization added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_SDRGCOMP...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_SDRGCOMP added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_DATACHG...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_DATACHG added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_DATAENT...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_DATAENT added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_Death...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_Death added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_PK...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_PK added successfully
#> INFO [2026-07-08 20:46:59]  ---- Adding dataset Raw_QUERY...
#> INFO [2026-07-08 20:46:59]  ---- Dataset Raw_QUERY added successfully
#> INFO [2026-07-08 20:46:59]  -- Snapshot 1 added successfully
#>   site_id enrolled_subjects
#> 1  0X1980                 6
#> 2  0X2614                 7
#> 3  0X3371                 7
#> 4  0X9089                 5

head(datasim_results$enrollment_summary)
#>   site_id enrolled_subjects
#> 1  0X1980                 6
#> 2  0X2614                 7
#> 3  0X3371                 7
#> 4  0X9089                 5
head(datasim_results$loaded_names)
#> [1] "dfAE"      "dfDATACHG" "dfDATAENT" "dfDeath"   "dfENROLL"  "dfIE"
```

Use `lConfig$gsm.datasim` to tune the simulated study. Common fields
include `participants`, `sites`, `snapshot_count`, `months_duration`,
`snapshot`, `profile`, and `study_type`.

For longitudinal settings, the provider returns the latest snapshot by
default, or the snapshot selected by `lConfig$gsm.datasim$snapshot`.

``` r

lConfig <- list(
  LoadData = "gsm.datasim",
  gsm.datasim = list(
    study_type = "endpoints",
    months_duration = 2,
    participants = 10,
    sites = 3,
    snapshot = "latest"
  )
)
```

## GitHub Actions artifact operations

The built-in `"github_artifact"` providers support the operational cycle
used in CI:

1.  Load inputs, for example with `LoadData = "gsm.datasim"`.
2.  Run the workflow steps.
3.  Save selected `lData` entries with `SaveData = "github_artifact"`.
4.  Restore the saved artifact in a later run with
    `LoadData = "github_artifact"`.

The save provider writes a local bundle containing `manifest.yaml` and
one `.rds` payload file per selected `lData` entry. If the bundle should
be available to later GitHub Actions jobs, upload the bundle directory
after
[`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
completes, for example with `actions/upload-artifact`.

``` r

lConfig <- list(
  LoadData = "gsm.datasim",
  SaveData = "github_artifact",
  gsm.datasim = list(
    profile = "standard",
    study_type = "standard",
    snapshot_count = 1
  ),
  github_artifact = list(
    artifact_name = "workr-study-state",
    include = c("Raw_SUBJ", "dfSUBJ", "result")
  )
)
```

A later run can restore that bundle by naming the repository and either
an explicit `run_id` or a restore policy:

``` r

lConfig <- list(
  LoadData = "github_artifact",
  github_artifact = list(
    repo = "owner/repo",
    artifact_name = "workr-study-state",
    policy = "latest_success"
  )
)
```

Restoring artifacts uses the GitHub Actions API to list workflow runs,
list artifacts for the selected run, and download the artifact bundle.
In GitHub Actions, expose a token to R as `GH_TOKEN` or `GITHUB_PAT` and
grant at least:

``` yaml
permissions:
  contents: read
  actions: read
```

For fine-grained personal access tokens, grant repository access plus
**Actions: Read**.

Common restore failures usually point to one of three setup issues: the
token is missing or lacks `actions: read`, `artifact_name` or `repo`
points at the wrong artifact, or the uploaded artifact did not contain
the full bundle directory with `manifest.yaml` at its root.
