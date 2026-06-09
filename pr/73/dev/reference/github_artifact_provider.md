# Built-in GitHub artifact providers

**\[experimental\]**

## Details

The built-in `"github_artifact"` load and save providers serialize
selected workflow data to an artifact bundle and restore that bundle in
a later run. Configure them with `lConfig$LoadData = "github_artifact"`
or `lConfig$SaveData = "github_artifact"` and pass provider options in
`lConfig$github_artifact`.

Save operations write a local bundle that operators can publish with
`actions/upload-artifact` or a custom uploader callback. Restore
operations query the GitHub Actions API and therefore require a token
exposed as `GH_TOKEN` or `GITHUB_PAT` with `actions: read` permission.
