# Create a Package Manifest

Creates a reproducible manifest of a list of GitHub-hosted R packages,
generating a manifest.csv, rproject.toml, and pulling workflow files.
This function captures the versions and workflow definitions for a set
of packages at a given point in time, enabling reproducible package
environments.

## Usage

``` r
pkgManifest(path = ".", packageList = character(), date = NULL, branch = NULL)
```

## Arguments

- path:

  Character. Path to save the manifest output. Default: "."

- packageList:

  Character vector of GitHub refs in the format "org/repo",
  "org/repo@tag", or "org/repo@sha".

- date:

  Date or character (YYYY-MM-DD). If no tag/sha is provided in a ref,
  resolve the most recent release on or before this date. Default: NULL
  (uses the latest release or default branch HEAD).

- branch:

  Character or NULL. If provided, use this branch for any refs that
  don't specify a tag/sha. Overrides date-based resolution.

## Value

Invisibly returns the manifest data frame.

## Examples

``` r
if (FALSE) { # \dontrun{
pkgManifest(
  path = "2025-q4-release",
  packageList = c(
    "Gilead-BioStats/gsm@v1.8.4",
    "Gilead-BioStats/grail"
  ),
  branch = "dev"
)
} # }
```
