# workr

Standalone workflow execution helpers extracted from gsm.core. The package provides:

- `RunStep()` to execute a single workflow step
- `RunWorkflow()` to execute a workflow specification
- `RunWorkflows()` to run multiple workflows in sequence

## Usage

```r
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

Example workflow definitions are provided in [inst/workflows/helloworld.yaml](inst/workflows/helloworld.yaml), [inst/workflows/two_steps.yaml](inst/workflows/two_steps.yaml), and [inst/workflows/cars.yaml](inst/workflows/cars.yaml).

```r
yaml_path <- system.file("workflows", "helloworld.yaml", package = "workr")
workflow <- yaml::read_yaml(yaml_path)
```

Replace the placeholder example with your workflow definitions.
