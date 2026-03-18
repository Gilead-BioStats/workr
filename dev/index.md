# workr

A **very** simple R data pipeline framework.

## What is {workr}?

{workr} provides a minimal mental model for describing and executing
data workflows:

- **Workflows** are YAML files with `meta` (workflow metadata) and
  `steps` (ordered list of function calls)
- **Steps** are functions that accept data and parameters, producing
  output that gets added to the shared data list
- **Meta** is workflow-level configuration accessible to all steps

The package provides three core functions:

- [`RunStep()`](https://gilead-biostats.github.io/workr/dev/reference/RunStep.md) -
  execute a single workflow step
- [`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md) -
  execute a workflow specification (YAML)
- [`RunWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflows.md) -
  run multiple workflows in sequence

## Why {workr}?

{workr} was built to solve a specific problem: **reusable, customizable
data pipelines for complex clinical trial monitoring**.

The core functions in {workr} were originally developed as part of the
[{gsm} framework](https://gilead-biostats.github.io/gsm.core/index.html)
for risk-based quality montoring (RBQM). The {gsm} team developed a
[stable, reusable model for generating
metrics](https://gilead-biostats.github.io/gsm.core/articles/DataAnalysis.html)
to monitor clinical trials.

Our challenge was figuring out how to run those metrics across a large
portfolio; Take 30 studies with monthly snapshots, each needing 15
metrics computed in 5 steps and you get 27,000 computations per year. To
make things more complex, each study has slightly different
requirements, so maintaining individual scripts quickly becomes a
massive pain.

{workr}’s solution: Define workflows once, customize via `meta`
parameters, and compose them into larger pipelines.

The original `gsm::RunWorkflow` functions were developed in a few hours,
and were seen as a stopgap until we picked a “real” pipeline, but the
approach has proven to be suprisingly stable and flexible. So much so
that, we’ve created {workr} and started using them outside of our {gsm}
pipelines.

## Quick Start

Define a workflow in YAML:

``` yaml
# hello_cars.yaml
meta:
  ID: hello_cars
  col: speed
steps:
  - name: dplyr::pull 
    output: speed
    params:
      df: df
      col: col
  - name: mean
    output: result
    params:
      lData: speed
```

Run it from R:

``` r
wf <- yaml::read_yaml("hello_cars.yaml")
lData <- list(df = cars)

result <- workr::RunWorkflow(
  lWorkflow = wf,
  lData = lData
)

# result = 15.4 (mean of cars$speed)
```

## How it works

Each step in a workflow:

1.  Calls a function (specified by `step$name`)
2.  Passes parameters from `params` (resolving references to `lData`,
    `meta`, or literal values)
3.  Saves the result to `lData` using the `output` name
4.  Makes it available for the next step

By chaining steps (and even whole workflows) together, you can build
complex pipelines from simple, reusable components.

## Snapshots & Workflow Explorer

{workr} includes tooling for creating reproducible snapshots of
GitHub-hosted R package ecosystems and a browser-based workflow
explorer.

### Package Snapshots

`pkgSnapshot()` resolves a list of GitHub packages to specific versions
and generates:

- `manifest.csv` — pinned package versions with SHAs
- `rproject.toml` — [rv](https://github.com/A2-ai/rv)-compatible
  dependency file
- `workflows/` — merged workflow YAML files pulled from each package’s
  `inst/workflow/`

Snapshots are stored on orphan branches (prefixed `ss-*`) and updated
nightly via GitHub Actions.

📦 [Demo snapshot
(`ss-demo`)](https://github.com/Gilead-BioStats/workr/tree/ss-demo) —
gsm.core, gsm.mapping, gsm.kri, gsm.reporting

### Workflow Explorer

An interactive single-page app for browsing workflow pipelines across
snapshot branches. Workflows are grouped by phase, sorted by priority,
and searchable. Each card links to the source YAML and opens a detail
modal with metadata, input spec, step-by-step pipeline, and raw YAML
toggle.

🔍 [Workflow
Explorer](https://gilead-biostats.github.io/workr/dev/explorer/)

### GitHub Actions

| Workflow                | Purpose                                                                     |
|-------------------------|-----------------------------------------------------------------------------|
| `snapshot.yaml`         | Reusable: resolve packages, generate snapshot artifacts on an orphan branch |
| `nightly-snapshot.yaml` | Scheduled: runs `snapshot.yaml` nightly for configured branches             |
| `site-build.yaml`       | Reusable: build the explorer app from `ss-*` branch data                    |
| `site-deploy.yaml`      | Standalone Pages deploy (for repos without pkgdown)                         |
