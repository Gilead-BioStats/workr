# Generate a package list from a manifest.csv file

Reads a manifest.csv and returns a character vector of GitHub refs
formatted for use with
[`pkgManifest()`](https://gilead-public.github.io/workr/dev/reference/pkgManifest.md).

## Usage

``` r
pkgListFromManifest(path = "manifest.csv")
```

## Arguments

- path:

  Character. Path to the manifest.csv file.

## Value

Character vector of GitHub refs in "org/repo" format.

## Examples

``` r
if (FALSE) { # \dontrun{
pkgs <- pkgListFromManifest("manifest.csv")
pkgManifest(packageList = pkgs, branch = "dev")
} # }
```
