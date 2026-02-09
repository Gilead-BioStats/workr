# Run a workflow via it's YAML specification.

**\[stable\]**

Attempts to run a single assessment (`lWorkflow`) using shared data
(`lData`) and metadata (`lMapping`). Calls `RunStep` for each item in
`lWorkflow$workflow` and saves the results to `lWorkflow`.

## Usage

``` r
RunWorkflow(
  lWorkflow,
  lData = NULL,
  lConfig = NULL,
  bReturnResult = TRUE,
  bKeepInputData = TRUE
)
```

## Arguments

- lWorkflow:

  `list` A named list of metadata defining how the workflow should be
  run.

- lData:

  `list` A named list of domain-level data frames.

- lConfig:

  `list` A configuration object with two methods:

  - `LoadData`: A function that loads data specified in
    `lWorkflow$spec`.

  - `SaveData`: A function that saves data returned by the last step in
    `lWorkflow$steps`.

- bReturnResult:

  `boolean` should *only* the result from the last step (`lResults`) be
  returned? If false, the full workflow (including `lResults`) is
  returned. Default is `TRUE`.

- bKeepInputData:

  `boolean` should the input data be included in `lData` after the
  workflow is run? Only relevant when bReturnResult is FALSE. Default is
  `TRUE`.

## Value

Object containing the results of the workflow's last step (if
`bLastResult` is `TRUE`) or the full workflow object (if
`bReturnResults` is `TRUE`) or the full workflow object (if
`bReturnResults` is `FALSE`).

## Examples

``` r
if (FALSE) { # \dontrun{
# Load a simple workflow from YAML
wf <- yaml::read_yaml(
  system.file("workflows", "cars.yaml", package = "workr")
)
lData <- list(cars = cars)

# Run the workflow
result <- RunWorkflow(wf, lData)
summary(result)
} # }
```
