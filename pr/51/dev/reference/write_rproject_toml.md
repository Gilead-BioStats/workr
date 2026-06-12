# Write an rproject.toml file compatible with rv (https://github.com/A2-ai/rv)

Dependencies are pinned by commit SHA, not by tag: the DESCRIPTION
version recorded in the manifest does not match the repos' git tags
(tags carry a `v` prefix, and `.9000` dev versions have no tag at all),
so tag pins can never resolve. The SHA is the same reproducibility
anchor manifest.csv records.

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
