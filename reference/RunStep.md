# Run a single step in a workflow

Runs a single step of an assessment workflow and resolves step
parameters from `lMeta`, `lData`, and `lSpec`.

## Usage

``` r
RunStep(lStep, lData, lMeta, lSpec = NULL)
```

## Arguments

- lStep:

  `list` single workflow step.

- lData:

  `list` a named list of domain level data frames.

- lMeta:

  `list` a named list of meta data.

- lSpec:

  `list` a data specification containing required columns.

## Value

Results of the function call specified by `lStep$name`.

## Examples

``` r
sum_step <- function(lData, y) lData$value + y
lStep <- list(name = "sum_step", output = "result", params = list(lData = "lData", y = "value"))
lData <- list(value = 2)
RunStep(lStep = lStep, lData = lData, lMeta = list())
#> [INFO] Evaluating 2 parameter(s) for `sum_step`
#> [INFO] lData = lData:  Passing full lData object.
#> [INFO] y = value: Passing lData$value.
#> [INFO] Calling `sum_step`
#> Error in GetStrFunctionIfNamespaced(lStep$name): Function 'sum_step' not found.
```
