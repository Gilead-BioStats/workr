# Demo app server

**\[stable\]** Creates the server logic for the demo Shiny app,
including workflow execution and displayed results.

## Usage

``` r
DemoApp_Server(lWorkflows, lData, lConfig = NULL)
```

## Arguments

- lWorkflows:

  `list` Named list of workflows.

- lData:

  `list` Initial data list.

- lConfig:

  `list` Optional configuration hooks passed to workflow runners.
  `LoadData` may be a function or registered provider name matching the
  [`RunWorkflow`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
  hook contract.

## Value

A Shiny server function.
