# Pull workflow files from inst/workflow for each package

For each resolved package, pulls files from `inst/workflow`. If that
directory is missing but `inst/workflows` exists, a warning asks
maintainers to rename to the preferred convention and re-run
`snapshot()`. Pulled files are merged directly into a `workflows/`
subdirectory under `path`. Destination filename collisions across
repositories emit a warning and the most recently pulled file wins.

## Usage

``` r
pull_workflows(resolved, path)
```

## Arguments

- resolved:

  List of resolved package metadata (each with org, repo, sha).

- path:

  Character. Output directory.
