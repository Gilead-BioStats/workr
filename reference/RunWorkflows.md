# Run multiple workflows

Runs multiple workflows in sequence and returns a named list of results.

## Usage

``` r
RunWorkflows(lWorkflows, lData = NULL, lConfig = NULL, bKeepInputData = FALSE, bReturnResult = TRUE, strResultNames = c("Type", "ID"))
```

## Arguments

- lWorkflows:

  `list` workflows to run.

- lData:

  `list` domain-level data.

- lConfig:

  `list` configuration object with `LoadData` and `SaveData` functions.

- bKeepInputData:

  `boolean` keep input data when returning full workflow.

- bReturnResult:

  `boolean` return only last step result.

- strResultNames:

  `character` vector of length two specifying meta fields for result
  names.

## Value

A named list of results from `RunWorkflow`.

## Examples

``` r
sum_step <- function(lData, y) lData$value + y
lWorkflows <- list(
  list(
    meta = list(Type = "demo", ID = "001"),
    steps = list(
      list(name = "sum_step", output = "result", params = list(lData = "lData", y = "value"))
    )
  )
)
lData <- list(value = 2)
RunWorkflows(lWorkflows, lData)
#> [INFO] Running 1 Workflows
#> [INFO] Initializing `demo_001` Workflow
#> [INFO] No spec found in workflow. Proceeding without checking data.
#> [INFO] Workflow Step 1 of 1: `sum_step`
#> [INFO] Evaluating 2 parameter(s) for `sum_step`
#> [INFO] lData = lData:  Passing full lData object.
#> [INFO] y = value: Passing lData$value.
#> [INFO] Calling `sum_step`
#> Error in GetStrFunctionIfNamespaced(lStep$name): Function 'sum_step' not found.
```
