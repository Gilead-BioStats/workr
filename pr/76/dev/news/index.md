# Changelog

## workr (development version)

- Fortified validation ergonomics for project-scale runs:
  [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  and
  [`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md)
  now support opt-in `bContinueOnError` summaries, spec checks fail
  before step execution when declared inputs are absent from `lData`,
  and
  [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  supports project-scoped and phase-scoped load/save hooks while
  preserving existing top-level workflow hooks.

- Added a
  [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  regression matrix
  ([\#67](https://github.com/Gilead-BioStats/workr/issues/67)): a
  no-config flat carry-forward backward-compatibility test and a
  four-phase configured project scenario exercising `from_phases`,
  `from_results`, `include_workflows`, `extra`, output `transform`, and
  `wrap_as`. Documented the manifest/build to
  [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  runtime handoff and the per-phase `_config.yaml` contract in the
  README.
  [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  remains `experimental` while the new config surface settles.

- Added per-phase `_config.yaml` support to
  [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  ([\#64](https://github.com/Gilead-BioStats/workr/issues/64),
  [\#65](https://github.com/Gilead-BioStats/workr/issues/65),
  [\#66](https://github.com/Gilead-BioStats/workr/issues/66)): phase
  folders may declare `input` (`from_phases`, `from_results`,
  `include_workflows`, `extra`) and `output` (`wrap_as`, `transform`)
  maps, validated with strict unknown-key errors. `_config.yaml` /
  `_config.yml` files are excluded from workflow discovery. Phases
  without a config file keep the existing flat carry-forward behavior.

- Breaking change for internal callers: `stop_if()` now interpolates its
  message with
  [`glue::glue()`](https://glue.tidyverse.org/reference/glue.html) in
  the caller’s environment. Messages such as
  `"directory does not exist: {strPath}"` previously printed the braces
  literally; they now interpolate as intended. Any `stop_if()` message
  that needs a literal `{` or `}` must escape it as `{{` / `}}`.

- Stabilized the
  [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  baseline contract
  ([\#63](https://github.com/Gilead-BioStats/workr/issues/63)):
  `strPath` is now validated to exist *and* be a directory (distinct
  error messages), the phase-discovery and ordering semantics
  (alphabetical by default, caller order preserved when `strPhases` is
  supplied) are documented, and empty phase folders log a warning-level
  message (via `LogMessage()`, not an R
  [`warning()`](https://rdrr.io/r/base/warning.html)) and are skipped
  rather than erroring. Added unit-test coverage for default ordering,
  `strPhases` ordering, non-directory `strPath`, and the empty-phase
  skip path.

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
