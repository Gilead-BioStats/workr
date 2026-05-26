# Package index

## Workflow Execution

Core functions for running workflows and individual steps.

- [`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md)
  **\[stable\]** : Convenience function to run multiple workflows
- [`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
  **\[stable\]** : Run a workflow via it's YAML specification.
- [`RunStep()`](https://gilead-biostats.github.io/workr/dev/reference/RunStep.md)
  **\[stable\]** : Run a single step in a workflow.
- [`RunQuery()`](https://gilead-biostats.github.io/workr/dev/reference/RunQuery.md)
  **\[stable\]** : Run a SQL query on a data frame or DuckDB table

## Project Management

Utilities for managing workflow projects and loading examples.

- [`RunProject()`](https://gilead-biostats.github.io/workr/dev/reference/RunProject.md)
  **\[experimental\]** : Run a multi-phase workflow project
- [`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/dev/reference/MakeWorkflowList.md)
  **\[stable\]** : Load workflows from a package/directory.
- [`GetActiveWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/GetActiveWorkflows.md)
  **\[experimental\]** : Get names of active workflows from a
  package/directory.
- [`loadExample()`](https://gilead-biostats.github.io/workr/dev/reference/loadExample.md)
  **\[stable\]** : Load example data for workflow execution

## Demo App

Interactive Shiny application for exploring workflows.

- [`DemoApp_init()`](https://gilead-biostats.github.io/workr/dev/reference/DemoApp_init.md)
  **\[stable\]** : Launch the workr demo Shiny app
- [`DemoApp_UI()`](https://gilead-biostats.github.io/workr/dev/reference/DemoApp_UI.md)
  **\[stable\]** : Demo app UI
- [`DemoApp_Server()`](https://gilead-biostats.github.io/workr/dev/reference/DemoApp_Server.md)
  **\[stable\]** : Demo app server

## Internal / Helpers

- [`gh_get_sha()`](https://gilead-biostats.github.io/workr/dev/reference/gh_get_sha.md)
  : Get the commit SHA for a given ref
- [`gh_get_version()`](https://gilead-biostats.github.io/workr/dev/reference/gh_get_version.md)
  : Get the package version from DESCRIPTION file at a given SHA
- [`parse_github_ref()`](https://gilead-biostats.github.io/workr/dev/reference/parse_github_ref.md)
  : Parse a GitHub ref string into org, repo, and optional ref
- [`pkgListFromManifest()`](https://gilead-biostats.github.io/workr/dev/reference/pkgListFromManifest.md)
  : Generate a package list from a manifest.csv file
- [`pkgManifest()`](https://gilead-biostats.github.io/workr/dev/reference/pkgManifest.md)
  : Create a Package Manifest
- [`pull_workflows()`](https://gilead-biostats.github.io/workr/dev/reference/pull_workflows.md)
  : Pull workflow files from inst/workflow for each package
- [`resolve_package()`](https://gilead-biostats.github.io/workr/dev/reference/resolve_package.md)
  : Resolve a package to its full metadata using the GitHub API via gh
  CLI
- [`resolve_ref_by_date()`](https://gilead-biostats.github.io/workr/dev/reference/resolve_ref_by_date.md)
  : Resolve a ref by date — find the latest release/tag on or before the
  given date
- [`resolve_tag_by_date()`](https://gilead-biostats.github.io/workr/dev/reference/resolve_tag_by_date.md)
  : Resolve a tag by date when no releases exist
- [`write_rproject_toml()`](https://gilead-biostats.github.io/workr/dev/reference/write_rproject_toml.md)
  : Write an rproject.toml file compatible with rv
  (https://github.com/A2-ai/rv)
