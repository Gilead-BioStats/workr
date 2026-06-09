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

## Details

Phase-discovery and ordering contract:

- `strPath` must exist and be a directory; otherwise execution stops.

- By default phases are the immediate subdirectories of `strPath`,
  executed in alphabetical order.

- When `strPhases` is supplied, phases run in the exact order given
  (caller order is preserved, not re-sorted).

- A `strPhases` entry that does not exist on disk is a fatal error.

- A phase folder that contains no workflow YAMLs emits a warning and is
  skipped; execution proceeds with the remaining phases.

Per-phase `_config.yaml` files may define `input` and `output` maps. The
`input` map accepts `from_phases`, `from_results`, `include_workflows`,
and `extra`. The `output` map accepts `wrap_as` and `transform`. Unknown
keys are fatal errors. Without `_config.yaml`, phases retain the default
carry-forward behavior: all prior phase outputs are available to the
next phase.

`input.from_phases` is a character vector of prior phase folder names to
merge into `lData`; by default all prior phases are included.
`input.from_results` is a named map of `target_name: source_phase` that
adds a prior phase result under a target key. `input.include_workflows`
may be `true` to add the current phase workflow list as
`lData$lWorkflows`, or `{from_phase: <name>}` to add a prior phase
workflow list. `input.extra` is a static named map merged last, so it
takes precedence over prior phase data. String values in `extra` are
passed literally.

`output.wrap_as` wraps the phase result under one named key before
downstream input assembly. `output.transform` may name a function
resolved from the calling environment; the function receives the phase
result and its return value replaces that result. Transform errors fail
the phase and identify the transform reference.

## Examples

``` r
if (FALSE) { # \dontrun{
results <- RunProject("inst/workflow")
} # }
```
