# List workflow YAML files in a package/directory.

**\[stable\]**

Returns a named character vector of paths to workflow YAML files,
similar to [`fs::dir_ls()`](https://fs.r-lib.org/reference/dir_ls.html).
Use
[`ListWorkflowNames()`](https://gilead-biostats.github.io/workr/dev/reference/ListWorkflowNames.md)
to get just the bare workflow names, or
[`MakeWorkflowList()`](https://gilead-biostats.github.io/workr/dev/reference/MakeWorkflowList.md)
to load and validate the workflows.

## Usage

``` r
ListWorkflows(strPath = "workflow", strPackage = NULL, bRecursive = TRUE)
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

`character` A named character vector of absolute paths to YAML files,
where names are the bare filenames (e.g. `"cars.yaml"`).

## Examples

``` r
ListWorkflows(strPath = "workflow", strPackage = "workr")
#>                                                                                           hello_cars.yaml 
#>                           "/home/runner/work/_temp/Library/workr/workflow/01_RunWorkflow/hello_cars.yaml" 
#>                                                                                                 mean.yaml 
#>                                "/home/runner/work/_temp/Library/workr/workflow/02_RunWorkflows/mean.yaml" 
#>                                                                                               subset.yaml 
#>                              "/home/runner/work/_temp/Library/workr/workflow/02_RunWorkflows/subset.yaml" 
#>                                                                                                   AE.yaml 
#>                                           "/home/runner/work/_temp/Library/workr/workflow/03_KRI/AE.yaml" 
#>                                                                                                 SUBJ.yaml 
#>                                         "/home/runner/work/_temp/Library/workr/workflow/03_KRI/SUBJ.yaml" 
#>                                                                                              kri0001.yaml 
#>                                      "/home/runner/work/_temp/Library/workr/workflow/03_KRI/kri0001.yaml" 
#>                                                                                                   DM.yaml 
#>                           "/home/runner/work/_temp/Library/workr/workflow/04_Example_RAW_TO_SDTM/DM.yaml" 
#>                                                                                                   VS.yaml 
#>                           "/home/runner/work/_temp/Library/workr/workflow/04_Example_RAW_TO_SDTM/VS.yaml" 
#>                                                                                                 ADVS.yaml 
#>                        "/home/runner/work/_temp/Library/workr/workflow/05_Example_SDTM_TO_ADAM/ADVS.yaml" 
#>                                                                                         WorkProduct1.yaml 
#>                 "/home/runner/work/_temp/Library/workr/workflow/06_Example_ADAM_TO_TFL/WorkProduct1.yaml" 
#>                                                                         table_mean_arterial_pressure.yaml 
#> "/home/runner/work/_temp/Library/workr/workflow/07_Example_ADAM_TO_ARS/table_mean_arterial_pressure.yaml" 
```
