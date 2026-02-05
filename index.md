# workr

Standalone workflow execution helpers extracted from gsm.core. The
package provides:

- [`RunStep()`](https://automatic-adventure-6lomjw6.pages.github.io/reference/RunStep.md)
  to execute a single workflow step
- [`RunWorkflow()`](https://automatic-adventure-6lomjw6.pages.github.io/reference/RunWorkflow.md)
  to execute a workflow specification
- [`RunWorkflows()`](https://automatic-adventure-6lomjw6.pages.github.io/reference/RunWorkflows.md)
  to run multiple workflows in sequence

## Usage

``` r
lWorkflows <- list(
  list(
    meta = list(Type = "demo", ID = "001"),
    steps = list(
      list(name = "sum_step", output = "result", params = list(lData = "lData", y = "value"))
    )
  )
)

sum_step <- function(lData, y) {
  lData$value + y
}

lData <- list(value = 2)
RunWorkflows(lWorkflows, lData)
```

Example workflow definitions are provided in
[inst/workflows/helloworld.yaml](https://automatic-adventure-6lomjw6.pages.github.io/inst/workflows/helloworld.yaml),
[inst/workflows/two_steps.yaml](https://automatic-adventure-6lomjw6.pages.github.io/inst/workflows/two_steps.yaml),
and
[inst/workflows/cars.yaml](https://automatic-adventure-6lomjw6.pages.github.io/inst/workflows/cars.yaml).

``` r
yaml_path <- system.file("workflows", "helloworld.yaml", package = "workr")
workflow <- yaml::read_yaml(yaml_path)
```

Replace the placeholder example with your workflow definitions.

## Cookbook

Run the example workflows using YAML definitions.

### 1) Hello world workflow

Workflow file:
[inst/workflows/helloworld.yaml](https://automatic-adventure-6lomjw6.pages.github.io/inst/workflows/helloworld.yaml)

``` yaml
meta:
  Type: demo
  ID: helloworld
steps:
  - name: sum_step
    output: result
    params:
      lData: lData
      "y": value
```

``` r
sum_step <- function(lData, y) lData$value + y
lData <- list(value = 2)

wf <- yaml::read_yaml(system.file("workflows", "helloworld.yaml", package = "workr"))
RunWorkflow(wf, lData)
```

### 2) Two-step workflow

Workflow file:
[inst/workflows/two_steps.yaml](https://automatic-adventure-6lomjw6.pages.github.io/inst/workflows/two_steps.yaml)

``` yaml
meta:
  Type: demo
  ID: two_steps
steps:
  - name: sum_step
    output: intermediate
    params:
      lData: lData
      "y": value
  - name: sum_step
    output: result
    params:
      lData: lData
      "y": value
```

``` r
sum_step <- function(lData, y) lData$value + y
lData <- list(value = 2)

wf <- yaml::read_yaml(system.file("workflows", "two_steps.yaml", package = "workr"))
RunWorkflow(wf, lData)
```

### 3) Cars regression workflow

Workflow file:
[inst/workflows/cars.yaml](https://automatic-adventure-6lomjw6.pages.github.io/inst/workflows/cars.yaml)

``` yaml
meta:
  Type: demo
  ID: cars
steps:
  - name: stats::as.formula
    output: model_formula
    params:
      object: "dist ~ speed"
  - name: stats::lm
    output: model
    params:
      formula: model_formula
      data: cars
```

``` r
lData <- list(cars = cars)

wf <- yaml::read_yaml(system.file("workflows", "cars.yaml", package = "workr"))
model <- RunWorkflow(wf, lData)
summary(model)
```
