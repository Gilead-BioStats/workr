# Incorporating cards

## Prepare list of data of raw-data

``` r

adam <- list(
  ADVS = arrow::read_parquet(system.file("demo_gsmpharmaverse/data/ADAM/ADAM_ADVS.parquet", package = "workr"))
)
```

Show ADAM preview (first 6 rows)

| oak_id | raw_source | patient_number | VSTESTCD | VSTEST | VSORRES | VSORRESU | VSPOS | VSLOC | VSLAT | VSDTC | VSTPT | VSTPTNUM | VISIT | VISITNUM | STUDYID | DOMAIN | VSCAT | USUBJID | TRT01A | PARAMCD | AVAL |
|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
| 1 | vitals | 375 | SYSBP | Systolic Blood Pressure | 158.00 | mmHg | PRONE | NA | NA | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 | DRUG X | SYSBP | 158.00 |
| 1 | vitals | 375 | DIABP | Diastolic Blood Pressure | 92.00 | mmHg | PRONE | NA | NA | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 | DRUG X | DIABP | 92.00 |
| 1 | vitals | 375 | PULSE | Pulse Rate | 63.00 | beats/min | NA | NA | NA | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 | DRUG X | PULSE | 63.00 |
| 1 | vitals | 375 | RESP | Respiratory Rate | 17.00 | breaths/min | NA | NA | NA | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 | DRUG X | RESP | 17.00 |
| 1 | vitals | 375 | TEMP | Temperature | 40.48 | C | NA | SKIN | NA | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 | DRUG X | TEMP | 40.48 |
| 1 | vitals | 375 | OXYSAT | Oxygen Saturation | 98.00 | % | NA | FINGER | RIGHT | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 | DRUG X | OXYSAT | 98.00 |

### Show YAML’s of cards transformations

    ## ```yaml
    ## meta:
    ##   ID: table_mean_arterial_pressure
    ##   Type: ars
    ##   Description: Create table 1 ARS
    ##   Priority: 1
    ## spec:
    ##   ADVS:
    ##     _all:
    ##       required: true
    ## steps:
    ##   - output: predose_visit1_map
    ##     name: workr::RunQuery
    ##     params:
    ##       df: ADVS
    ##       strQuery: "SELECT * FROM df WHERE PARAMCD = 'MAP' AND VISIT = 'VISIT1' AND VSTPT = 'PREDOSE'"
    ##   - output: table_predose_visit1_map
    ##     name: cards::ard_summary
    ##     params:
    ##       data: predose_visit1_map
    ##       variables:
    ##         - AVAL
    ## ```

This workflow combines aspects of `gtsummary` and `safetyCharts` modules
to demonstrate how to assemble multiple static outputs or a hybrid
approach that may include shiny/web app html-based modules.

``` r

ARS_workflows <- workr::MakeWorkflowList(
  strNames = "table_mean_arterial_pressure",
  strPath = "demo_gsmpharmaverse/workflows/3_ADAM_TO_ARS/",
  strPackage = "workr"
)
ARS <- workr::RunWorkflows(lWorkflows = ARS_workflows, lData = adam )
```

``` r

map2(ARS, names(ARS), function(x,y) arrow::write_parquet(x, paste0("demo_gsmpharmaverse/data/ARS/", y,".parquet")))
```

Show Table 1 ARS (first 6 rows)

| variable | context | stat_name | stat_label | stat     | fmt_fun | warning | error |
|----------|---------|-----------|------------|----------|---------|---------|-------|
| AVAL     | summary | N         | N          | 2        | 0       |         |       |
| AVAL     | summary | mean      | Mean       | 93.83333 | 1       |         |       |
| AVAL     | summary | sd        | SD         | 28.51997 | 1       |         |       |
| AVAL     | summary | median    | Median     | 93.83333 | 1       |         |       |
| AVAL     | summary | p25       | Q1         | 73.66667 | 1       |         |       |
| AVAL     | summary | p75       | Q3         | 114      | 1       |         |       |
| AVAL     | summary | min       | Min        | 73.66667 | 1       |         |       |
| AVAL     | summary | max       | Max        | 114      | 1       |         |       |
