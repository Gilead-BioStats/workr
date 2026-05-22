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

## Value

A Shiny server function.
