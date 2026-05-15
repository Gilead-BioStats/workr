# Pull workflow files from inst/workflow or inst/workflows for each package

For each resolved package, checks `inst/workflow` first, then falls back
to `inst/workflows`. Only when both are absent is the package skipped
with a message. Matched files are merged directly into a `workflows/`
subdirectory under `path`. Duplicate output paths across packages are
detected and can emit warnings or errors.

## Usage

``` r
pull_workflows(resolved, path, collision_action = c("warn", "error"))
```

## Arguments

- resolved:

  List of resolved package metadata (each with org, repo, sha).

- path:

  Character. Output directory.

- collision_action:

  Character. How to handle collisions when multiple packages map to the
  same destination path in `workflows/`. One of `"warn"` (default) or
  `"error"`.
