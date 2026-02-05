# Incorporating admiral

## Prepare list of data of raw-data

``` r
sdtm <- list(
  SDTM_DM = arrow::read_parquet(system.file("demo_gsmpharmaverse/data/SDTM/SDTM_DM.parquet", package = "workr")),
  SDTM_VS = arrow::read_parquet(system.file("demo_gsmpharmaverse/data/SDTM/SDTM_VS.parquet", package = "workr"))
)
```

Show Raw DM preview (first 6 rows)

| STUDYID    | USUBJID        | TRT01A |
|------------|----------------|--------|
| test_study | test_study-375 | DRUG X |
| test_study | test_study-376 | DRUG X |
| test_study | test_study-377 | DRUG X |
| test_study | test_study-378 | DRUG X |
| test_study | test_study-379 | DRUG X |

Show Raw VS preview (first 6 rows)

| oak_id | raw_source | patient_number | VSTESTCD | VSTEST                   | VSORRES | VSORRESU    | VSPOS | VSLOC  | VSLAT | VSDTC            | VSTPT   | VSTPTNUM | VISIT  | VISITNUM | STUDYID    | DOMAIN | VSCAT       | USUBJID        |
|--------|------------|----------------|----------|--------------------------|---------|-------------|-------|--------|-------|------------------|---------|----------|--------|----------|------------|--------|-------------|----------------|
| 1      | vitals     | 375            | SYSBP    | Systolic Blood Pressure  | 158.00  | mmHg        | PRONE | NA     | NA    | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 |
| 1      | vitals     | 375            | DIABP    | Diastolic Blood Pressure | 92.00   | mmHg        | PRONE | NA     | NA    | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 |
| 1      | vitals     | 375            | PULSE    | Pulse Rate               | 63.00   | beats/min   | NA    | NA     | NA    | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 |
| 1      | vitals     | 375            | RESP     | Respiratory Rate         | 17.00   | breaths/min | NA    | NA     | NA    | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 |
| 1      | vitals     | 375            | TEMP     | Temperature              | 40.48   | C           | NA    | SKIN   | NA    | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 |
| 1      | vitals     | 375            | OXYSAT   | Oxygen Saturation        | 98.00   | %           | NA    | FINGER | RIGHT | 2015-05-16T07:25 | PREDOSE | 1        | VISIT1 | VISIT1   | test_study | VS     | VITAL SIGNS | test_study-375 |

### Show YAML’s of admiral transformations

    ## ```yaml
    ## meta:
    ##   ID: ADVS
    ##   Type: ADAM
    ##   Description: Create Basic ADSL
    ##   Priority: 1
    ## spec:
    ##   SDTM_DM:
    ##     _all:
    ##       required: true
    ##   SDTM_VS:
    ##     _all:
    ##       required: true
    ## steps:
    ##   - output: initial_advs
    ##     name: admiral::derive_vars_merged
    ##     params:
    ##       dataset: SDTM_VS
    ##       dataset_add: SDTM_DM
    ##       new_vars: !expr exprs(TRT01A)
    ##       by_vars: !expr exprs(STUDYID, USUBJID)
    ##   - output: advs
    ##     name: dplyr::mutate
    ##     params:
    ##       .data: initial_advs
    ##       PARAMCD: !expr rlang::expr(.data[["VSTESTCD"]])
    ##       AVAL: !expr rlang::expr(.data[["VSORRES"]])
    ##   - output: advs
    ##     name: admiral::derive_param_map
    ##     params:
    ##       dataset: advs
    ##       by_vars: !expr exprs(STUDYID, USUBJID, TRT01A, VSDTC, VISIT, VISITNUM, VSTPT, VSTPTNUM)
    ##       sysbp_code: 'SYSBP'
    ##       diabp_code: 'DIABP'
    ##       get_unit_expr: !expr rlang::expr(.data[["VSORRESU"]])
    ## ```

This workflow was inspired by portions of this `admiral`
[vignette](https://pharmaverse.github.io/admiral/cran-release/articles/bds_finding.html?q=advs#derive_param).

``` r
ADAM_workflows <- workr::MakeWorkflowList(
  strNames = "ADVS",
  strPath = "demo_gsmpharmaverse/workflows/2_SDTM_TO_ADAM/",
  strPackage = "workr"
)
ADAM <- workr::RunWorkflows(lWorkflows = ADAM_workflows, lData = sdtm)
```

``` r
map2(ADAM, names(ADAM), function(x,y) arrow::write_parquet(x, paste0("demo_gsmpharmaverse/data/ADAM/",y,".parquet"))
```

Show ADVS (first 6 rows)

``` r
ADAM$ADAM_ADVS %>%
  filter(.data[["PARAMCD"]] == "MAP") %>% 
  gt()
```

| oak_id | raw_source | patient_number | VSTESTCD | VSTEST | VSORRES | VSORRESU | VSPOS | VSLOC | VSLAT | VSDTC            | VSTPT    | VSTPTNUM | VISIT     | VISITNUM | STUDYID    | DOMAIN | VSCAT | USUBJID        | TRT01A | PARAMCD | AVAL      |
|--------|------------|----------------|----------|--------|---------|----------|-------|-------|-------|------------------|----------|----------|-----------|----------|------------|--------|-------|----------------|--------|---------|-----------|
| NA     | NA         | NA             | NA       | NA     | NA      | NA       | NA    | NA    | NA    | 2015-05-16T07:25 | PREDOSE  | 1        | VISIT1    | VISIT1   | test_study | NA     | NA    | test_study-375 | DRUG X | MAP     | 114.00000 |
| NA     | NA         | NA             | NA       | NA     | NA      | NA       | NA    | NA    | NA    | 2015-05-16T10:25 | POSTDOSE | 2        | VISIT1    | VISIT1   | test_study | NA     | NA    | test_study-375 | DRUG X | MAP     | 83.33333  |
| NA     | NA         | NA             | NA       | NA     | NA      | NA       | NA    | NA    | NA    | 2018-05-06T02:01 |          |          | SCREENING | 1        | test_study | NA     | NA    | test_study-375 | DRUG X | MAP     | 80.33333  |
| NA     | NA         | NA             | NA       | NA     | NA      | NA       | NA    | NA    | NA    | 2008-10-23T01:19 | PREDOSE  | 1        | VISIT1    | VISIT1   | test_study | NA     | NA    | test_study-376 | DRUG X | MAP     | 73.66667  |
| NA     | NA         | NA             | NA       | NA     | NA      | NA       | NA    | NA    | NA    | 2008-10-23T03:19 | POSTDOSE | 2        | VISIT1    | VISIT1   | test_study | NA     | NA    | test_study-376 | DRUG X | MAP     | 96.00000  |
