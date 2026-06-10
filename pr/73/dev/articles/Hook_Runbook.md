# Hook Operations Runbook

## Purpose

This runbook covers the operational hook surface introduced for
[workr](https://gilead-biostats.github.io/workr) workflows:

- `LoadData = "gsm.datasim"` to generate simulated study inputs
- `SaveData = "github_artifact"` to serialize workflow state into an
  artifact bundle
- `LoadData = "github_artifact"` to restore a previously saved bundle

The intended cycle is:

1.  Load workflow inputs
2.  Execute the workflow
3.  Save selected `lData` entries as an artifact bundle
4.  Restore that bundle in a later run

## End-to-End Flow

The save provider writes a local bundle containing:

- `manifest.yaml`
- one `.rds` payload file per selected `lData` entry

The restore provider resolves a workflow run, downloads the named
artifact bundle, reads `manifest.yaml`, and restores the saved objects
into `lData`.

``` r

lConfig <- list(
  LoadData = "gsm.datasim",
  SaveData = "github_artifact",
  gsm.datasim = list(
    profile = "standard",
    study_type = "standard",
    participants = 250,
    sites = 25,
    snapshot_count = 3
  ),
  github_artifact = list(
    path = tempdir(),
    artifact_name = "workr-study-state",
    include = c("Raw_SUBJ", "dfSUBJ", "result")
  )
)
```

In a follow-up run, restore the prior bundle with:

``` r

lConfig <- list(
  LoadData = "github_artifact",
  github_artifact = list(
    repo = "owner/repo",
    artifact_name = "workr-study-state",
    policy = "latest_success"
  )
)
```

## GitHub Actions Authentication

`gsm.datasim` loading does not require GitHub authentication.

`github_artifact` restore does require GitHub API access because
[workr](https://gilead-biostats.github.io/workr) must:

- list successful workflow runs
- list artifacts for a run
- download the chosen artifact bundle

For GitHub Actions runs, expose the workflow token to R as `GH_TOKEN` or
`GITHUB_PAT` and grant at least:

``` yaml
permissions:
  contents: read
  actions: read
```

For fine-grained personal access tokens, grant repository access plus
**Actions: Read**.

If you publish bundles with `actions/upload-artifact`, the
[workr](https://gilead-biostats.github.io/workr) save provider only
prepares the local bundle. The workflow is responsible for uploading
that directory after
[`RunWorkflow()`](https://gilead-biostats.github.io/workr/dev/reference/RunWorkflow.md)
completes.

## Operator Checklist

Before enabling the full hook cycle in CI:

1.  Confirm the installed
    [workr](https://gilead-biostats.github.io/workr) version contains
    the hook contract plus both built-in providers.
2.  Set `LoadData` and `SaveData` to registered provider names, not raw
    strings elsewhere in the config.
3.  Provide `repo` for `github_artifact` restore when running outside
    the source repository.
4.  Decide whether restore should use an explicit `run_id` or
    `policy = "latest_success"`.
5.  Upload the saved bundle directory if the workflow should be
    restorable by a later run.

## Troubleshooting

### `Unknown load provider` or `Unknown save provider`

The package was loaded without the built-in registration path. Verify
the branch includes the combined startup registration and that the
provider name matches exactly.

### `Artifact restore failed ... actions: read`

The GitHub token is missing, expired, or lacks `actions: read`. Export
`GH_TOKEN` or `GITHUB_PAT` for the R process and update workflow
permissions.

### `Artifact ... not found for run-id`

The restore job resolved the wrong workflow run or artifact name. Check
`artifact_name`, `repo`, and whether the save job uploaded the bundle
directory.

### `manifest.yaml is missing`

The uploaded artifact did not contain the
[workr](https://gilead-biostats.github.io/workr) bundle root. Upload the
bundle directory created by the save provider, not only the payload
subdirectory.

### Payload file is missing or corrupt

The artifact was partially uploaded or modified after creation. Re-run
the save workflow and verify all payload files under `payload/` are
present.
