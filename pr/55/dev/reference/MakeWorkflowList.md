# Load workflows from a package/directory.

**\[stable\]**

Create a list of workflows for use in pipelines.

## Usage

``` r
MakeWorkflowList(
  strNames = GetActiveWorkflows(strPath = strPath, strPackage = strPackage, bRecursive =
    bRecursive),
  strPath = "workflow",
  strPackage = NULL,
  bExact = inherits(strNames, "AsIs"),
  bRecursive = TRUE
)
```

## Arguments

- strNames:

  `array of character` List of workflows to include. Defaults to the
  result of
  [`GetActiveWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/GetActiveWorkflows.md),
  which excludes any workflow with `meta$MetricActive: false`. Pass
  `NULL` explicitly to include all workflows regardless of their
  `MetricActive` setting.

- strPath:

  `character` The location of workflow YAML files, relative to either
  the working directory or the `strPackage` installation directory.

- strPackage:

  `character` The package name where the workflow YAML files are
  located. If `NULL`, the package will use an absolute path.

- bExact:

  `logical` Should `strNames` matches be exact? Defaults to `TRUE` when
  `strNames` has class `"AsIs"` (as it does if it comes from
  [`GetActiveWorkflows()`](https://gilead-biostats.github.io/workr/dev/reference/GetActiveWorkflows.md)),
  `FALSE` otherwise.

- bRecursive:

  `logical` Find files in nested folders? Default `TRUE`.

## Value

`list` A list of workflows with workflow and parameter metadata.

## Examples

``` r
# get specific workflow files
workflow <- MakeWorkflowList(
  strName = "cars",
  strPath = "workflow",
  strPackage = "workr"
)
```
