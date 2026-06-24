# Changelog

## workr (development version)

- Added `bContinueOnError` to
  [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  and
  [`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md),
  so long runs can keep going after workflow failures and return
  `results`, `status`, and `failures`. The default keeps the existing
  fail-fast behavior.

- [`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
  now checks declared spec inputs before running steps.

- [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  now supports project-level and phase-level load/save hooks
  ([\#67](https://github.com/Gilead-BioStats/workr/issues/67)).

- Added per-phase `_config.yaml` / `_config.yml` files for
  [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  ([\#64](https://github.com/Gilead-BioStats/workr/issues/64),
  [\#65](https://github.com/Gilead-BioStats/workr/issues/65),
  [\#66](https://github.com/Gilead-BioStats/workr/issues/66)). A phase
  can choose which earlier outputs it receives and can wrap or transform
  its own output. Projects without config files keep the existing flat
  carry-forward behavior.

- Internal breaking change: `stop_if()` now interpolates glue-style
  values in the caller’s environment. This fixes messages like
  `"directory does not exist: {strPath}"` so they show the actual path;
  callers that need literal braces should escape them as `{{` / `}}`.

- Made
  [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  behavior more predictable and easier to diagnose
  ([\#63](https://github.com/Gilead-BioStats/workr/issues/63)):
  `strPath` now reports distinct errors when the path is missing or is
  not a directory, phase ordering is documented, and empty phase folders
  are skipped with a workflow log message instead of stopping the run.
  Added unit-test coverage for the updated ordering, validation, and
  empty-phase behavior.

## workr 1.0.0

### Initial Release

{workr} provides a minimal framework for describing and executing
step-by-step R data pipelines using YAML-defined workflows.

#### Core Features

- [`RunStep()`](https://gilead-biostats.github.io/workr/dev/reference/RunStep.md)
  — execute a single workflow step
- [`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
  — execute a full workflow specification (YAML)
- [`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md)
  — run multiple workflows in sequence
- [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  — orchestrate multi-phase workflow pipelines (experimental)
- [`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/dev/reference/MakeWorkflowList.md)
  — read a folder of YAML workflows into a list
- [`RunQuery()`](https://gilead-biostats.github.io/workr/dev/reference/RunQuery.md)
  — execute database queries via DBI/duckdb
- [`loadExample()`](https://gilead-biostats.github.io/workr/dev/reference/loadExample.md)
  — load bundled example workflows for learning and testing

#### Shiny Demo App

- [`DemoApp_init()`](https://gilead-biostats.github.io/workr/dev/reference/DemoApp_init.md)
  — launch an interactive Shiny app for exploring and running workflows
- Hosted version available at
  [jwildfire.shinyapps.io/workr-demoapp](https://jwildfire.shinyapps.io/workr-demoapp/)

#### Package Manifests

- [`pkgManifest()`](https://gilead-biostats.github.io/workr/dev/reference/pkgManifest.md)
  — resolve GitHub packages to pinned versions with manifest.csv and
  rproject.toml
- Snapshot branches (`ss-*`) for reproducible package environments
- GitHub Actions for nightly manifest updates

#### GitHub Actions

- `manifest.yaml` — reusable workflow for generating manifest artifacts
- `nightly-manifest.yaml` — scheduled manifest updates
- `R-CMD-check.yaml` — R CMD check CI
- `R-CMD-check-dev.yaml` — development R CMD check CI
- `pkgdown-with-examples.yaml` — pkgdown site deployment
- `pkgdown-cleanup.yaml` — pkgdown cleanup

#### Documentation

- pkgdown site at
  [gilead-biostats.github.io/workr](https://gilead-biostats.github.io/workr)
- Vignettes covering overview, Pharmaverse integration, ADaM/SDTM
  examples, and visualization
