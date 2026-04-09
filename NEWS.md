# workr 1.0.0

## Initial Release

{workr} provides a minimal framework for describing and executing step-by-step R data pipelines using YAML-defined workflows.

### Core Features

* `RunStep()` — execute a single workflow step
* `RunWorkflow()` — execute a full workflow specification (YAML)
* `RunWorkflows()` — run multiple workflows in sequence
* `RunProject()` — orchestrate multi-phase workflow pipelines (experimental)
* `MakeWorkflowList()` — read a folder of YAML workflows into a list
* `RunQuery()` — execute database queries via DBI/duckdb
* `loadExample()` — load bundled example workflows for learning and testing

### Shiny Demo App

* `DemoApp_init()` — launch an interactive Shiny app for exploring and running workflows
* Hosted version available at [jwildfire.shinyapps.io/workr-demoapp](https://jwildfire.shinyapps.io/workr-demoapp/)

### Package Manifests

* `pkgManifest()` — resolve GitHub packages to pinned versions with manifest.csv and rproject.toml
* Snapshot branches (`ss-*`) for reproducible package environments
* GitHub Actions for nightly manifest updates

### GitHub Actions

* `manifest.yaml` — reusable workflow for generating manifest artifacts
* `nightly-manifest.yaml` — scheduled manifest updates
* `R-CMD-check.yaml` — R CMD check CI
* `R-CMD-check-dev.yaml` — development R CMD check CI
* `pkgdown-with-examples.yaml` — pkgdown site deployment
* `pkgdown-cleanup.yaml` — pkgdown cleanup

### Documentation

* pkgdown site at [gilead-biostats.github.io/workr](https://gilead-biostats.github.io/workr)
* Vignettes covering overview, Pharmaverse integration, ADaM/SDTM examples, and visualization
