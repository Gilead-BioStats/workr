# Changelog

## workr (development version)

- Workflows can now validate their input data before running any steps,
  via an optional `spec` section in the workflow YAML
  ([\#91](https://github.com/Gilead-Public/workr/issues/91)).

## workr 1.1.0

### Highlights

- Improved project orchestration with phase-level configuration files,
  project/phase load-save hooks, optional continue-on-error behavior,
  and clearer diagnostics for missing paths, empty phases, and workflow
  failures.

- Added workflow discovery helpers and made workflow loading more
  predictable, including active/inactive filtering, priority ordering,
  exact-name matching, and support for the singular `inst/workflow`
  directory.

- Added reusable load/save hook registration plus built-in GitHub
  Actions artifact providers for saving and restoring workflow data
  between runs.

- Hardened GitHub, manifest, snapshot, and CI automation, including
  expanded mocked coverage for GitHub-backed workflows.

- Updated examples, documentation, pkgdown configuration, and tests for
  the new workflow loading, hook, artifact, and project orchestration
  behavior.

- Fixed schema-enforced timestamp parsing in
  [`RunQuery()`](https://gilead-public.github.io/workr/dev/reference/RunQuery.md)
  when inputs mix Date and POSIXct-like values.

## workr 1.0.0

### Initial Release

{workr} provides a minimal framework for describing and executing
step-by-step R data pipelines using YAML-defined workflows.

#### Core Features

- [`RunStep()`](https://gilead-public.github.io/workr/dev/reference/RunStep.md)
  — execute a single workflow step
- [`RunWorkflow()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflow.md)
  — execute a full workflow specification (YAML)
- [`RunWorkflows()`](https://gilead-public.github.io/workr/dev/reference/RunWorkflows.md)
  — run multiple workflows in sequence
- [`RunProject()`](https://gilead-public.github.io/workr/dev/reference/RunProject.md)
  — orchestrate multi-phase workflow pipelines (experimental)
- [`MakeWorkflowList()`](https://gilead-public.github.io/workr/dev/reference/MakeWorkflowList.md)
  — read a folder of YAML workflows into a list
- [`RunQuery()`](https://gilead-public.github.io/workr/dev/reference/RunQuery.md)
  — execute database queries via DBI/duckdb
- [`loadExample()`](https://gilead-public.github.io/workr/dev/reference/loadExample.md)
  — load bundled example workflows for learning and testing

#### Shiny Demo App

- [`DemoApp_init()`](https://gilead-public.github.io/workr/dev/reference/DemoApp_init.md)
  — launch an interactive Shiny app for exploring and running workflows
- Hosted version available at
  [jwildfire.shinyapps.io/workr-demoapp](https://jwildfire.shinyapps.io/workr-demoapp/)

#### Package Manifests

- [`pkgManifest()`](https://gilead-public.github.io/workr/dev/reference/pkgManifest.md)
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
