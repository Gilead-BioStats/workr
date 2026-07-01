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

### Workflow discovery and execution

- Added
  [`ListWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/ListWorkflows.md)
  and
  [`ListWorkflowNames()`](https://gilead-biostats.github.io/workr/dev/reference/ListWorkflowNames.md)
  helpers for discovering workflow YAML files from package or local
  workflow directories.
- Extended
  [`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/dev/reference/MakeWorkflowList.md)
  with exact-name matching, recursive discovery controls,
  active/inactive workflow filtering via `meta$Active`, required-field
  validation, workflow ID naming, and `meta$Priority` ordering.
- Added support for the singular `inst/workflow` package workflow
  directory while retaining compatibility with existing workflow-loading
  paths.
- Improved
  [`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
  and
  [`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md)
  configuration handling by passing `lConfig` through workflow execution
  and supporting load/save hooks.
- Fixed mixed Date/POSIXct timestamp parsing in
  [`RunQuery()`](https://gilead-biostats.github.io/workr/dev/reference/RunQuery.md)
  when schema enforcement is enabled.

### Load/save hooks and artifacts

- Added
  [`register_load_provider()`](https://gilead-biostats.github.io/workr/dev/reference/register_load_provider.md)
  and
  [`register_save_provider()`](https://gilead-biostats.github.io/workr/dev/reference/register_save_provider.md)
  for named, reusable workflow data hooks.
- Added built-in `github_artifact` load and save providers for
  persisting workflow data as manifest-described RDS payloads in GitHub
  Actions artifacts.
- Added artifact restore policies for explicit or latest-successful
  workflow runs, configurable missing-artifact handling, include/exclude
  key filters, custom upload/fetch hooks, and path traversal validation
  for downloaded bundles.
- Added a Load and Save Hooks vignette documenting inline hooks,
  registered providers, and multi-workflow usage.

### GitHub, manifests, and automation

- Migrated GitHub API helper calls to
  [`gh::gh()`](https://gh.r-lib.org/reference/gh.html) and hardened
  package/ref resolution, snapshot helpers, and manifest workflow
  installation behavior.
- Simplified GitHub artifact helper internals and added mocked test
  coverage for snapshot and artifact provider workflows.
- Updated GitHub Actions for R CMD check, manifest generation, pkgdown
  deployment, qcthat, test coverage, release automation, and
  workflow-template checks.

### Examples, docs, and tests

- Reorganized bundled example workflows and test fixtures under
  `workflow`/`_fixtures` directories, including active/inactive workflow
  examples and malformed workflow fixtures.
- Updated README, pkgdown configuration, generated documentation, and
  lifecycle assets for the expanded workflow and hook APIs.
- Added and expanded test coverage for workflow listing/loading, active
  workflow filtering, workflow execution, query schema parsing,
  load/save hook behavior, GitHub artifact providers, and snapshot
  helpers.

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
