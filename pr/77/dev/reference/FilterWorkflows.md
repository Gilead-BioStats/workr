# Filter a workflow list by metadata fields

**\[stable\]**

Filter a named list of workflows by matching zero or more `meta` fields
against supplied values. Each `name = value` pair in `...` is applied
sequentially (AND logic): a workflow must satisfy every filter to be
retained.

## Usage

``` r
FilterWorkflows(lWorkflows, ...)
```

## Arguments

- lWorkflows:

  `list` A named list of workflows, as returned by
  [`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/dev/reference/MakeWorkflowList.md).

- ...:

  `name = value` pairs where each name is a `meta` field to filter on
  (e.g., `Category`, `Type`, `Active`) and the value determines which
  workflows are kept. Field lookup is case-insensitive. Workflows that
  lack the specified field entirely are removed. The class of each value
  controls matching behaviour:

  - `character`: keep workflows where any element of `meta[[field]]`
    matches any element of `value` (case-insensitive).

  - `logical`: keep workflows where `meta[[field]]` coerces to the given
    `TRUE`/`FALSE` value (coercion handles YAML string forms like
    `"true"`).

  - `numeric`: keep workflows where `meta[[field]]` equals any element
    of `value` (equality only; no comparison operators).

  - other types: an informative error is raised.

## Value

`list` A filtered named list of workflows.

## Examples

``` r
lWorkflows <- MakeWorkflowList(strPath = "example_workflows", strPackage = "workr")

# Filter by a character field
lWorkflowsAnalysis <- FilterWorkflows(lWorkflows, Type = "Analysis")
#> [INFO] Keeping 1 of 11 workflows where Type matches Analysis.
#> [INFO] Kept 1 of 11 workflows after applying 1 filter(s).

# Multiple filters (AND logic)
lWorkflowsAnalysisSite <- FilterWorkflows(lWorkflows, Type = "Analysis", GroupLevel = "site")
#> [INFO] Keeping 1 of 11 workflows where Type matches Analysis.
#> [INFO] Keeping 1 of 1 workflows where GroupLevel matches site.
#> [INFO] Kept 1 of 11 workflows after applying 2 filter(s).
```
