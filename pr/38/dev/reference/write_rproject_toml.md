# Write an rproject.toml file compatible with rv (https://github.com/A2-ai/rv)

Write an rproject.toml file compatible with rv
(https://github.com/A2-ai/rv)

## Usage

``` r
write_rproject_toml(manifest, path, project_name = "library")
```

## Arguments

- manifest:

  Data frame with columns: org, package, version, repository, sha.

- path:

  Character. Output directory.

- project_name:

  Character. Project name for the toml header. Default: "library"
