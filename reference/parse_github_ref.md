# Parse a GitHub ref string into org, repo, and optional ref

Parse a GitHub ref string into org, repo, and optional ref

## Usage

``` r
parse_github_ref(ref)
```

## Arguments

- ref:

  Character. A GitHub ref like "org/repo" or "org/repo@tag_or_sha"

## Value

A list with elements: org, repo, ref (NULL if not specified)
