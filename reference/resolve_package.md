# Resolve a package to its full metadata using the GitHub API via gh CLI

Resolve a package to its full metadata using the GitHub API via gh CLI

## Usage

``` r
resolve_package(org, repo, ref = NULL, date = NULL)
```

## Arguments

- org:

  Character. GitHub organization.

- repo:

  Character. Repository name.

- ref:

  Character or NULL. Tag, SHA, or branch name.

- date:

  Date or NULL. If ref is NULL, find latest release on or before this
  date.

## Value

A list with org, repo, version, repository, url, sha, ref.
