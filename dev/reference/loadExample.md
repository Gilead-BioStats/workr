# Load example data for workflow execution

**\[stable\]**

`loadExample()` is a convenience `LoadData` hook for
[`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
and
[`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md).
If an `initData.R` file exists in the same folder as the workflow YAML,
it sources that script and calls `initData()` to get starter `lData`.

The return value is merged with incoming `lData` so caller-provided
values override defaults from `initData()`.

## Usage

``` r
loadExample(lWorkflow, lConfig = NULL, lData = NULL)
```

## Arguments

- lWorkflow:

  `list` Workflow object. Must include `path` (set by
  [`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/dev/reference/MakeWorkflowList.md))
  to locate `initData.R`.

- lConfig:

  `list` Unused. Included to match the `LoadData` hook interface
  expected by
  [`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md).

- lData:

  `list` Existing input data.

## Value

`list` Data to use as workflow input.
