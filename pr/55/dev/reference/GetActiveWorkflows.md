# Get names of active workflows from a package/directory.

**\[experimental\]**

Discovers YAML workflow files in the given location and returns the
names of those whose `meta$MetricActive` is not explicitly `FALSE`. This
is the same discovery logic used by
[`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/dev/reference/MakeWorkflowList.md),
and its result is suitable for passing directly to its `strNames`
argument.

## Usage

``` r
GetActiveWorkflows(
  strNames = NULL,
  strPath = "workflow",
  strPackage = NULL,
  bExact = FALSE,
  bRecursive = TRUE
)
```

## Arguments

- strNames:

  `array of character` Optional subset of workflow names to consider.
  `NULL` (the default) considers all discovered workflows.

- strPath:

  `character` The location of workflow YAML files, relative to either
  the working directory or the `strPackage` installation directory.

- strPackage:

  `character` The package name where the workflow YAML files are
  located. If `NULL`, an absolute path is used.

- bExact:

  `logical` Should `strNames` matches be exact? Default `FALSE`.

- bRecursive:

  `logical` Find files in nested folders? Default `TRUE`.

## Value

`character` A character vector of workflow names (IDs) whose
`meta$MetricActive` is absent or `TRUE`.

## Examples

``` r
GetActiveWorkflows(
  strPath = "workflows",
  strPackage = "workr"
)
#>  [1] "hello_cars"                   "mean"                        
#>  [3] "subset"                       "AE"                          
#>  [5] "SUBJ"                         "kri0001"                     
#>  [7] "DM"                           "VS"                          
#>  [9] "ADVS"                         "WorkProduct1"                
#> [11] "table_mean_arterial_pressure"
```
