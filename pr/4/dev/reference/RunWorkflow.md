# Run a workflow via its specification

Runs a single workflow definition by invoking `RunStep` for each step
and capturing results.

## Usage

``` r
RunWorkflow(lWorkflow, lData = NULL, lConfig = NULL, bReturnResult = TRUE, bKeepInputData = TRUE)
```

## Arguments

- lWorkflow:

  `list` metadata defining how the workflow should be run.

- lData:

  `list` domain-level data.

- lConfig:

  `list` configuration object with `LoadData` and `SaveData` functions.

- bReturnResult:

  `boolean` return only last step result.

- bKeepInputData:

  `boolean` keep input data when returning full workflow.

## Value

Results from the final step or the full workflow object.

## Examples

``` r
sum_step <- function(lData, y) lData$value + y
lWorkflow <- list(
  meta = list(Type = "demo", ID = "001"),
  steps = list(
    list(name = "sum_step", output = "result", params = list(lData = "lData", y = "value"))
  )
)
lData <- list(value = 2)
RunWorkflow(lWorkflow, lData)
#> [INFO] Initializing `demo_001` Workflow
#> [INFO] No spec found in workflow. Proceeding without checking data.
#> [INFO] Workflow Step 1 of 1: `sum_step`
#> [INFO] Evaluating 2 parameter(s) for `sum_step`
#> [INFO] lData = lData:  Passing full lData object.
#> [INFO] y = value: Passing lData$value.
#> [INFO] Calling `sum_step`
#> Error in GetStrFunctionIfNamespaced(lStep$name): Function 'sum_step' not found.
```
