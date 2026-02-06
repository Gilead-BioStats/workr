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

The core functions in {workr} were originally implemented as part of the
{gsm} framework for risk-based quality montoring (RBQM). The {gsm} team
developed a stable, reusable model for generating metrics to monitor
clinical trials.

Our challenge was figuring out how to run those metrics across a large
portfolio; Take 30 studies with monthly snapshots, each needing 15
metrics computed in 5 steps and you get 27,000 metric computations per
year. To make things more complex, each study has slightly different
requirements, so maintaining individual scripts quickly becomes
unmaintainable.

{workr}’s solution: Define workflows once, customize via `meta`
parameters, and compose them into larger pipelines.

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

Each step in a workflow: 1. Calls a function (specified by `step$name`)
2. Passes parameters from `params` (resolving references to `lData`,
`meta`, or literal values) 3. Saves the result to `lData` using the
`output` name 4. Makes it available for the next step

By chaining steps (and even whole workflows) together, you can build
complex pipelines from simple, reusable components.
