# Run a multi-phase workflow project

**\[experimental\]**

`RunProject()` runs multiple workflow phase folders in sequence, sharing
one `lData` object across phases. Each subdirectory of `strPath` is
treated as a phase. Phases are executed in sorted order (or in the order
specified by `strPhases`). Within each phase, workflows are loaded via
[`MakeWorkflowList()`](https://gilead-public.github.io/workr/dev/reference/MakeWorkflowList.md)
and run via
[`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md).

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
  strResultNames = c("Type", "ID"),
  bContinueOnError = FALSE
)
```

## Arguments

- strPath:

  `character` Path to the project directory. Must contain one or more
  subdirectories, each holding workflow YAML files.

- lData:

  `list` Initial named list of data objects. Default `NULL`.

- lConfig:

  `list` Runtime configuration hooks. Top-level `LoadData` and
  `SaveData` hooks are passed through to
  [`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md)
  for each phase and run for each workflow in that phase. Use
  `lConfig$phases` for phase-specific workflow hooks and
  `lConfig$project` for hooks that run once for the whole project. Phase
  handoff settings such as `input.from_phases` belong in per-phase
  `_config.yaml` files, not in `lConfig$phases`.

- strPhases:

  `character` Optional vector of phase folder names to run. If `NULL`
  (the default), all sorted subdirectories of `strPath` are used.

- bRecursive:

  `logical` Passed to
  [`MakeWorkflowList()`](https://gilead-public.github.io/workr/dev/reference/MakeWorkflowList.md).
  Default `FALSE`.

- bReturnResult:

  `logical` Passed to
  [`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md).
  Default `TRUE`.

- bKeepInputData:

  `logical` Passed to
  [`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md).
  Default `FALSE`.

- strResultNames:

  `character` Vector of length two passed to
  [`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md).
  Default `c("Type", "ID")`.

- bContinueOnError:

  `logical` Passed to
  [`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md).
  If `TRUE`, failed workflows are recorded and later workflows/phases
  still run. Default `FALSE` retains the existing fail-fast behavior
  from
  [`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md).

## Value

A named list with one element per phase. Each element contains the
result returned by
[`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md)
for that phase. When `bContinueOnError = TRUE`, returns a summary with
`results`, `status`, and `failures`.

## Details

Phase folders and order:

- `strPath` must exist and be a directory; otherwise execution stops.

- By default phases are the immediate subdirectories of `strPath`,
  executed in alphabetical order.

- When `strPhases` is supplied, phases run in the exact order given
  (caller order is preserved, not re-sorted).

- A `strPhases` entry that does not exist on disk stops execution.

- A phase folder that contains no workflow YAMLs is skipped with a
  workflow log message; execution proceeds with the remaining phases.

Per-phase `_config.yaml` files may define `input` and `output` maps.
Unknown keys stop execution. Without `_config.yaml`, all prior phase
outputs are available to the next phase.

Think of `_config.yaml` and `lConfig$phases` as two phase-scoped
settings at different layers. `_config.yaml` is project orchestration
config: use `input.from_phases` or `input.from_results` to select
earlier phase data, `input.include_workflows` to pass workflow
definitions, and `input.extra` for static values. Use `output.wrap_as`
to store a phase result under one name or `output.transform` to apply a
function before later phases use the result.
`lConfig$phases[[phase_name]]` is workflow runtime config: it is merged
into the `lConfig` passed to
[`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md)
for that phase, so use it for phase-specific hooks such as `LoadData`
and `SaveData`.

Load/save hooks:

- Put `LoadData` or `SaveData` at the top level of `lConfig` to pass
  those hooks to
  [`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md)
  for each phase.
  [`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md)
  then applies them to each workflow in that phase.

- Put hooks under `lConfig$phases[[phase_name]]` to use them only for
  that phase. Phase hooks override top-level hooks with the same name.

- Put `LoadData` or `SaveData` under `lConfig$project` to run once
  before or after the whole project. Project `LoadData` must return an
  `lData` list; project `SaveData` receives the project result.

## Examples

``` r
if (FALSE) { # \dontrun{
results <- RunProject("inst/example_workflows")
} # }
```
