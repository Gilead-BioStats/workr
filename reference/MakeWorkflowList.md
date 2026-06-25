# Load workflows from a package/directory.

**\[stable\]**

Create a list of workflows for use in pipelines.

## Usage

``` r
MakeWorkflowList(
  strNames = ListWorkflowNames(strPath = strPath, strPackage = strPackage, bRecursive =
    bRecursive),
  strPath = "example_workflows",
  strPackage = NULL,
  bExact = inherits(strNames, "AsIs"),
  bRecursive = TRUE,
  bActiveOnly = TRUE
)
```

## Arguments

- strNames:

  `array of character` Workflow names to include. Defaults to all
  workflow names found at `strPath`/`strPackage`. Pass an
  [`I()`](https://rdrr.io/r/base/AsIs.html)-wrapped vector for exact
  matching (as returned by
  [`ListWorkflowNames()`](https://gilead-biostats.github.io/workr/reference/ListWorkflowNames.md)).

- strPath:

  `character` The location of workflow YAML files, relative to either
  the working directory or the `strPackage` installation directory.

- strPackage:

  `character` The package name where the workflow YAML files are
  located. If `NULL`, the package will use an absolute path.

- bExact:

  `logical` Should `strNames` matches be exact? Defaults to `TRUE` when
  `strNames` has class `"AsIs"` (as returned by
  [`ListWorkflowNames()`](https://gilead-biostats.github.io/workr/reference/ListWorkflowNames.md)),
  `FALSE` otherwise.

- bRecursive:

  `logical` Find files in nested folders? Default `TRUE`.

- bActiveOnly:

  `logical` Should workflows with `meta$Active: false` be excluded?
  Default `TRUE`. Set to `FALSE` to load all workflows regardless of
  their `Active` setting.

## Value

`list` A list of workflows with workflow and parameter metadata.

## Examples

``` r
# Load all active workflows from a package
workflow <- MakeWorkflowList(
  strPath = "example_workflows",
  strPackage = "workr"
)

# Load a specific workflow by name
workflow <- MakeWorkflowList(
  strNames = "cars",
  strPath = "example_workflows",
  strPackage = "workr"
)
```
