# List workflow names in a package/directory.

**\[stable\]**

Returns the bare workflow names (without the `.yaml` extension) for all
workflow YAML files discovered in the given location. This is suitable
for passing directly to the `strNames` argument of
[`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/reference/MakeWorkflowList.md).

Note: this function only inspects filenames — it does not read the
workflow files. Active/inactive filtering happens inside
[`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/reference/MakeWorkflowList.md).

## Usage

``` r
ListWorkflowNames(
  strPath = "example_workflows",
  strPackage = NULL,
  bRecursive = TRUE
)
```

## Arguments

- strPath:

  `character` The location of workflow YAML files, relative to either
  the working directory or the `strPackage` installation directory.

- strPackage:

  `character` The package name where the workflow YAML files are
  located. If `NULL`, uses an absolute path.

- bRecursive:

  `logical` Find files in nested folders? Default `TRUE`.

## Value

`character` A character vector of workflow names (IDs), with class
`"AsIs"` so that
[`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/reference/MakeWorkflowList.md)
treats them as exact matches.

## Examples

``` r
ListWorkflowNames(strPath = "example_workflows", strPackage = "workr")
#>  [1] "hello_cars"                   "mean"                        
#>  [3] "subset"                       "AE"                          
#>  [5] "SUBJ"                         "kri0001"                     
#>  [7] "DM"                           "VS"                          
#>  [9] "ADVS"                         "WorkProduct1"                
#> [11] "table_mean_arterial_pressure"
```
