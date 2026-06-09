# Launch the workr demo Shiny app

**\[stable\]**

Initializes and runs an interactive Shiny application that demonstrates
core workr functionality. The app shows workflow YAML (editable) on the
left and the resulting data on the right.

## Usage

``` r
DemoApp_init(
  lWorkflows = NULL,
  lData = list(value = 2, cars = datasets::cars),
  lConfig = NULL
)
```

## Arguments

- lWorkflows:

  `list` A named list of workflows as returned by
  [`MakeWorkflowList`](https://gilead-biostats.github.io/workr/dev/reference/MakeWorkflowList.md).
  Defaults to all example workflows shipped with workr.

- lData:

  `list` Initial named list of data objects available to workflows.
  Defaults to `list(value = 2, cars = datasets::cars)`.

- lConfig:

  `list` Optional configuration hooks passed to workflow runners.
  Defaults to using
  [`loadExample()`](https://gilead-biostats.github.io/workr/dev/reference/loadExample.md)
  for `LoadData`.

## Value

A `shiny.appobj` (called for its side effect of launching the app).

## Examples

``` r
if (FALSE) { # \dontrun{
DemoApp_init()
} # }
```
