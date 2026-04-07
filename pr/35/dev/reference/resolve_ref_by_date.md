# Resolve a ref by date — find the latest release/tag on or before the given date

Resolve a ref by date — find the latest release/tag on or before the
given date

## Usage

``` r
resolve_ref_by_date(org, repo, date = NULL)
```

## Arguments

- org:

  Character. GitHub organization.

- repo:

  Character. Repository name.

- date:

  Date or NULL. If NULL, uses the latest release.

## Value

Character. The resolved tag name or default branch.
