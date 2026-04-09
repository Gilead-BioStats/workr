# Incorporating TFL libraries like \`gtsummary\`

## Prepare list of data of raw-data

``` r
adam <- list(
  ADVS = arrow::read_parquet(system.file("demo_gsmpharmaverse/data/ADAM/ADAM_ADVS.parquet", package = "workr"))
)
```

Show ADAM preview (first 6 rows)

| oak_id | raw_source | patient_number | VSTESTCD | VSTEST                   | VSORRES | VSORRESU    | VSPOS | VSLOC  | VSLAT | VSDTC            | VSTPT   | VSTPTNUM | VISIT  | VISITNUM | STUDYID    | DOMAIN | VSCAT       | USUBJID        | TRT01A | PARAMCD | AVAL   |
|--------|------------|----------------|----------|--------------------------|---------|-------------|-------|--------|-------|------------------|---------|----------|--------|----------|------------|--------|-------------|----------------|--------|---------|--------|
| 1      | vitals     | 375            | SYSBP    | Systolic Blood Pressure  | 158.00  | mmHg        | PRONE | NA     | NA    | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 | DRUG X | SYSBP   | 158.00 |
| 1      | vitals     | 375            | DIABP    | Diastolic Blood Pressure | 92.00   | mmHg        | PRONE | NA     | NA    | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 | DRUG X | DIABP   | 92.00  |
| 1      | vitals     | 375            | PULSE    | Pulse Rate               | 63.00   | beats/min   | NA    | NA     | NA    | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 | DRUG X | PULSE   | 63.00  |
| 1      | vitals     | 375            | RESP     | Respiratory Rate         | 17.00   | breaths/min | NA    | NA     | NA    | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 | DRUG X | RESP    | 17.00  |
| 1      | vitals     | 375            | TEMP     | Temperature              | 40.48   | C           | NA    | SKIN   | NA    | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 | DRUG X | TEMP    | 40.48  |
| 1      | vitals     | 375            | OXYSAT   | Oxygen Saturation        | 98.00   | %           | NA    | FINGER | RIGHT | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 | DRUG X | OXYSAT  | 98.00  |

### Show YAML’s of visualization transformations

    ## ```yaml
    ## meta:
    ##   ID: WorkProduct1
    ##   Type: TFL
    ##   Description: Create Basic Work Product/Report which can modularize the tables included
    ##   Priority: 1
    ## spec:
    ##   ADVS:
    ##     _all:
    ##       required: true
    ## steps:
    ##   - output: lParams
    ##     name: list
    ##     params:
    ##       'dfADVS': ADVS
    ##   - output: table1
    ##     name: rmarkdown::render
    ##     params:
    ##       input: !expr  here::here("demo_gsmpharmaverse", "report_templates", "WorkProduct1.Rmd")
    ##       output_file: !expr   here::here("demo_gsmpharmaverse", "TFLS", "WorkProduct1.html")
    ##       envir: !expr new.env(parent = globalenv())
    ##       params: lParams
    ## ```

This workflow uses `gtsummary` to demonstrate how to assemble static
outputs or a hybrid approach that may include shiny/web app html-based
modules.

``` r
TFL_workflows <- workr::MakeWorkflowList(
  strNames = "WorkProduct1",
  strPath = "demo_gsmpharmaverse/workflows/3_ADAM_TO_TFL/",
  strPackage = "workr"
)
workr::RunWorkflows(lWorkflows = TFL_workflows, lData = adam )
```

An example report
[here](https://gilead-biostats.github.io/workr/dev/examples/WorkProduct1.md)
