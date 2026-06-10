# Built-in gsm.datasim load provider

**\[experimental\]**

## Value

A list of generated workflow input objects to merge into `lData`.

## Details

The built-in `"gsm.datasim"` `LoadData` provider generates workflow
inputs with the optional gsm.datasim package. Configure it by setting
`lConfig$LoadData = "gsm.datasim"` and passing provider options in
`lConfig$gsm.datasim`.

Supported adapter fields include `profile`, `study_type`,
`participants`, `sites`, `snapshot_count`, `months_duration`,
`snapshot`, and `config`. The returned objects keep `Raw_*` names and
also add `df*` aliases for compatibility with existing workflows.
