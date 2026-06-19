# Run a multi-phase workflow project

**\[experimental\]**

`RunProject()` runs multiple workflow phase folders in sequence, sharing
one `lData` object across phases. Each subdirectory of `strPath` is
treated as a phase. Phases are executed in sorted order (or in the order
specified by `strPhases`). Within each phase, workflows are loaded via
[`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/dev/reference/MakeWorkflowList.md)
and run via
[`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md).

## Usage

``` r
RunProject(
  strPath,
  lData = NULL,
  lConfig = NULL,
  strPhases = NULL,
  bRecursive = FALSE,
  bReturnResult = TRUE,
  bKeepInputData = FALSE,
  strResultNames = c("Type", "ID")
)
```

## Arguments

- strPath:

  `character` Path to the project directory. Must contain one or more
  subdirectories, each holding workflow YAML files.

- lData:

  `list` Initial named list of data objects. Default `NULL`.

- lConfig:

  `list` Configuration hooks passed to
  [`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md).
  Default `NULL`.

- strPhases:

  `character` Optional vector of phase folder names to run. If `NULL`
  (the default), all sorted subdirectories of `strPath` are used.

- bRecursive:

  `logical` Passed to
  [`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/dev/reference/MakeWorkflowList.md).
  Default `FALSE`.

- bReturnResult:

  `logical` Passed to
  [`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md).
  Default `TRUE`.

- bKeepInputData:

  `logical` Passed to
  [`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md).
  Default `FALSE`.

- strResultNames:

  `character` Vector of length two passed to
  [`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md).
  Default `c("Type", "ID")`.

## Value

A named list with one element per phase. Each element contains the
result returned by
[`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md)
for that phase.

## Examples

``` r
if (FALSE) { # \dontrun{
results <- RunProject("inst/example_workflows")
} # }
```
