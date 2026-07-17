# Incorporating sdtm.oak

## Prepare list of data of raw-data

``` r

lData <- list(
  dm_raw = read.csv(system.file("raw_data/dm.csv", package = "sdtm.oak")),
  vs_raw =  read.csv(system.file("raw_data/vitals_raw_data.csv", package = "sdtm.oak")),
  study_ct = read.csv(system.file("raw_data/sdtm_ct.csv", package = "sdtm.oak"))
)
```

Show Raw DM preview (first 6 rows)

| STUDYID | DOMAIN | USUBJID | SUBJID | RFSTDTC | RFENDTC | RFXSTDTC | RFXENDTC | RFICDTC | RFPENDTC | DTHDTC | DTHFL | SITEID | INVID | INVNAM | BRTHDTC | AGE | AGEU | SEX | RACE | ETHNIC | ARMCD | ARM | ACTARMCD | ACTARM | COUNTRY | DMDTC | DMDY | RACE1 | RACE2 | RACE3 |
|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
| test_study | DM | test_study-375 | test_study-375 | 1999-04-14T08:36 | 2013-01-21 | 2023-04-14T08:36 | 2021-01-11T07:50 | 2007-01-15 | 2020-04-02 | 2020-04-02 | Y | 111111 | 90009 | Dr doctor9 | NA | NA | NA | F | MULTIPLE | NA | NA | NA | NA | NA | US | NA | NA | NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER | WHITE | NA |
| test_study | DM | test_study-376 | test_study-376 | 2001-03-21 | 2007-05-21 | 2020-03-21 | 2017-09-14T18:49 | NA | 2011-12-18 | 2011-12-18 | NA | 111111 | 90009 | Dr doctor9 | 1981-02-26T18:07 | 42 | YEARS | M | MULTIPLE | NOT HISPANIC OR LATINO | NA | NA | NA | NA | US | NA | NA | BLACK OR AFRICAN AMERICAN | AMERICAN INDIAN OR ALASKA NATIVE | UNKNOWN |
| test_study | DM | test_study-377 | test_study-377 | 1999-03-14 | 2021-05-05 | 2020-03-14 | 2013-08-23T12:37 | 2015-10-07 | 2021-05-05 | 2019-06-29 | NA | 111111 | 90009 | Dr doctor9 | 1968-03-19T04:36 | 56 | YEARS | NA | MULTIPLE | NOT REPORTED | NA | NA | NA | NA | US | NA | NA | ASIAN | AMERICAN INDIAN OR ALASKA NATIVE | UNKNOWN |
| test_study | DM | test_study-378 | test_study-378 | 2003-02-06T06:33 | 2021-04-24T09:06 | 2021-02-06T06:33 | 2021-04-24T09:06 | 2018-10-20 | 2017-04-11 | 2017-04-11 | NA | 111111 | 90009 | Dr doctor9 | 1979-09-24 | 45 | YEARS | M | BLACK OR AFRICAN AMERICAN | HISPANIC OR LATINO | NA | NA | NA | NA | US | NA | NA | NA | NA | NA |
| test_study | DM | test_study-379 | test_study-379 | 2003-02-06T06:33 | 2021-04-24T09:06 | 2022-02-06T06:33 | 2021-04-24T09:06 | 2018-10-20 | 2017-04-11 | 2017-04-11 | Y | 111111 | 90009 | Dr doctor9 | 1963-09-24 | 61 | YEARS | M | BLACK OR AFRICAN AMERICAN | HISPANIC OR LATINO | NA | NA | NA | NA | US | NA | NA | NA | NA | NA |

Show Raw VS preview (first 6 rows)

| STUDY | PATNUM | SUBJSTAT | SITENM | INSTANCE | FORM | FORML | DATAPGID | RECORDID | RECPOS | ASMNTDN | TMPTC | VTLD | VTLTM | SUBPOS | SYS_BP | DIA_BP | PULSE | RESPRT | TEMP | TEMPLOC | OXY_SAT | LAT | LOC | VSO2SRC | NEWS107 |
|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
| Test Study | 375 | Randomized | Test Study | VISIT1 | VTLS1 | Vital Signs | 1752329 | 5734754 | 0 | 0 | Pre-dose | 16-May-15 | 7:25 | PRONE | 158 | 92 | 63 | 17 | 40.48 | SKIN | 98 | RIGHT | FINGER | MASK OXYGEN THERAPY | UNRESPONSIVE |
| Test Study | 375 | Randomized | Test Study | VISIT1 | VTLS1 | Vital Signs | 8153061 | 3712412 | 1 | 0 | Post-dose | 16-May-15 | 10:25 | SEMI-RECUMBENT | 94 | 78 | 76 | 20 | 36.75 | TYMPANIC MEMBRANE | 99 | LEFT | FINGER | ROOM AIR | NEW CONFUSION |
| Test Study | 375 | Randomized | Test Study | Screening | VTLS1 | Vital Signs | 3463516 | 1229594 | 0 | 0 |  | 6-May-18 | 2:01 | PRONE | 117 | 62 | 66 | 15 | 29.45 | ORAL CAVITY | 96 | LEFT | FINGER | ROOM AIR | VERBAL RESPONSIVE |
| Test Study | 376 | Randomized | Test Study | Screening | VTLS1 | Vital Signs | 8423253 | 9767053 | 0 | 1 |  |  |  |  | NA | NA | NA | NA | NA |  | NA |  |  |  |  |
| Test Study | 376 | Randomized | Test Study | VISIT1 | VTLS1 | Vital Signs | 1211365 | 1567778 | 0 | 0 | Pre-dose | 23-Oct-08 | 1:19 | PRONE | 85 | 68 | 73 | 21 | 38.25 | AXILLA | 93 | RIGHT | FINGER | ROOM AIR | ALERT |
| Test Study | 376 | Randomized | Test Study | VISIT1 | VTLS1 | Vital Signs | 5880552 | 7060998 | 0 | 0 | Post-dose | 23-Oct-08 | 3:19 | PRONE | 126 | 81 | 56 | 18 | 38.08 | TYMPANIC MEMBRANE | 93 | LEFT | FINGER | MASK OXYGEN THERAPY | PAIN RESPONSIVE |

Show Study CT preview (first 6 rows)

| codelist_code | term_code | term_value | collected_value | term_preferred_term | term_synonyms |
|----|----|----|----|----|----|
| C66726 | C25158 | CAPSULE | Capsule | Capsule Dosage Form | cap |
| C66726 | C25394 | PILL | Pill | Pill Dosage Form |  |
| C66726 | C29167 | LOTION | Lotion | Lotion Dosage Form |  |
| C66726 | C42887 | AEROSOL | Aerosol | Aerosol Dosage Form | aer |
| C66726 | C42944 | INHALANT | Inhalant | Inhalant Dosage Form |  |
| C66726 | C42946 | INJECTION | Injection | Injectable Dosage Form |  |

### Show YAML’s of sdtm.oak transformations

    ## ```yaml
    ## meta:
    ##   ID: DM
    ##   Type: SDTM
    ##   Description: Transform Raw DM to SDTM DM
    ##   Priority: 1
    ## spec:
    ##   dm_raw:
    ##     STUDYID:
    ##       type: character
    ##     USUBJID:
    ##       type: character
    ## steps:
    ##   - output: dm
    ##     name: workr::RunQuery
    ##     params:
    ##       df: dm_raw
    ##       strQuery: "SELECT STUDYID, USUBJID, 'DRUG X' as TRT01A FROM df"
    ## ```

    ## ```yaml
    ## meta:
    ##   ID: VS
    ##   Type: SDTM
    ##   Description: Transform Raw VS to SDTM VS following sdtm.oak article
    ##   Priority: 1
    ## spec:
    ##   # Read in data
    ##   vs_raw:
    ##     _all:
    ##       required: true
    ##   study_ct:
    ##     _all:
    ##       required: true
    ## steps:
    ##   # Create oak_id_vars
    ##   - output: vs_raw
    ##     name: sdtm.oak::generate_oak_id_vars
    ##     params:
    ##       raw_dat: vs_raw
    ##       pat_var: "PATNUM"
    ##       raw_src: "vitals"
    ##   # Map topic variable SYSBP and its qualifiers.
    ##   - output: vs_sysbp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       raw_dat: vs_raw
    ##       raw_var: "SYS_BP"
    ##       tgt_var: "VSTESTCD"
    ##       tgt_val: "SYSBP"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66741"
    ##   - output: vs_sysbp
    ##     name: workr::RunQuery
    ##     params:
    ##       df: vs_sysbp
    ##       strQuery: "SELECT * FROM df WHERE VSTESTCD IS NOT NULL"
    ##   # Map topic variable SYSBP and its qualifiers.
    ##   - output: vs_sysbp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_sysbp
    ##       raw_dat: vs_raw
    ##       raw_var: "SYS_BP"
    ##       tgt_var: "VSTEST"
    ##       tgt_val: "Systolic Blood Pressure"
    ##       ct_spec: study_ct
    ##       ct_clst: "C67153"
    ##   - output: vs_sysbp
    ##     name: sdtm.oak::assign_no_ct
    ##     params:
    ##       tgt_dat: vs_sysbp
    ##       raw_dat:  vs_raw
    ##       raw_var: "SYS_BP"
    ##       tgt_var: "VSORRES"
    ##   - output: vs_sysbp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_sysbp
    ##       raw_dat: vs_raw
    ##       raw_var: "SYS_BP"
    ##       tgt_var: "VSORRESU"
    ##       tgt_val: "mmHg"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66770"
    ##   - output: vs_sysbp
    ##     name: sdtm.oak::assign_ct
    ##     params:
    ##       tgt_dat: vs_sysbp
    ##       raw_dat: vs_raw
    ##       raw_var: "SUBPOS"
    ##       tgt_var: "VSPOS"
    ##       ct_spec: study_ct
    ##       ct_clst: "C71148"
    ## 
    ##   # Map topic variable DIABP and its qualifiers.
    ##   - output: vs_diabp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       raw_dat: vs_raw
    ##       raw_var: "DIA_BP"
    ##       tgt_var: "VSTESTCD"
    ##       tgt_val: "DIABP"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66741"
    ##   - output: vs_diabp
    ##     name: workr::RunQuery
    ##     params:
    ##       df: vs_diabp
    ##       strQuery: "SELECT * FROM df WHERE VSTESTCD IS NOT NULL"
    ##   - output: vs_diabp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_diabp
    ##       raw_dat: vs_raw
    ##       raw_var: "DIA_BP"
    ##       tgt_var: "VSTEST"
    ##       tgt_val: "Diastolic Blood Pressure"
    ##       ct_spec: study_ct
    ##       ct_clst: "C67153"
    ##   - output: vs_diabp
    ##     name: sdtm.oak::assign_no_ct
    ##     params:
    ##       tgt_dat: vs_diabp
    ##       raw_dat: vs_raw
    ##       raw_var: "DIA_BP"
    ##       tgt_var: "VSORRES"
    ##   - output: vs_diabp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_diabp
    ##       raw_dat: vs_raw
    ##       raw_var: "DIA_BP"
    ##       tgt_var: "VSORRESU"
    ##       tgt_val: "mmHg"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66770"
    ##   - output: vs_diabp
    ##     name: sdtm.oak::assign_ct
    ##     params:
    ##       tgt_dat: vs_diabp
    ##       raw_dat: vs_raw
    ##       raw_var: "SUBPOS"
    ##       tgt_var: "VSPOS"
    ##       ct_spec: study_ct
    ##       ct_clst: "C71148"
    ## 
    ##   - output: vs_pulse
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       raw_dat: vs_raw
    ##       raw_var: "PULSE"
    ##       tgt_var: "VSTESTCD"
    ##       tgt_val: "PULSE"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66741"
    ##   - output: vs_pulse
    ##     name: workr::RunQuery
    ##     params:
    ##       df: vs_pulse
    ##       strQuery: "SELECT * FROM df WHERE VSTESTCD IS NOT NULL"
    ##   - output: vs_pulse
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_pulse
    ##       raw_dat: vs_raw
    ##       raw_var: "PULSE"
    ##       tgt_var: "VSTEST"
    ##       tgt_val: "Pulse Rate"
    ##       ct_spec: study_ct
    ##       ct_clst: "C67153"
    ##   - output: vs_pulse
    ##     name: sdtm.oak::assign_no_ct
    ##     params:
    ##       tgt_dat: vs_pulse
    ##       raw_dat: vs_raw
    ##       raw_var: "PULSE"
    ##       tgt_var: "VSORRES"
    ##   - output: vs_pulse
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_pulse
    ##       raw_dat: vs_raw
    ##       raw_var: "PULSE"
    ##       tgt_var: "VSORRESU"
    ##       tgt_val: "beats/min"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66770"
    ## 
    ##   - output: vs_resp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       raw_dat: vs_raw
    ##       raw_var: "RESPRT"
    ##       tgt_var: "VSTESTCD"
    ##       tgt_val: "RESP"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66741"
    ##   - output: vs_resp
    ##     name: workr::RunQuery
    ##     params:
    ##       df: vs_resp
    ##       strQuery: "SELECT * FROM df WHERE VSTESTCD IS NOT NULL"
    ##   - output: vs_resp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_resp
    ##       raw_dat: vs_raw
    ##       raw_var: "RESPRT"
    ##       tgt_var: "VSTEST"
    ##       tgt_val: "Respiratory Rate"
    ##       ct_spec: study_ct
    ##       ct_clst: "C67153"
    ##   - output: vs_resp
    ##     name: sdtm.oak::assign_no_ct
    ##     params:
    ##       tgt_dat: vs_resp
    ##       raw_dat: vs_raw
    ##       raw_var: "RESPRT"
    ##       tgt_var: "VSORRES"
    ##   - output: vs_resp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_resp
    ##       raw_dat: vs_raw
    ##       raw_var: "RESPRT"
    ##       tgt_var: "VSORRESU"
    ##       tgt_val: "breaths/min"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66770"
    ## 
    ##   - output: vs_temp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       raw_dat: vs_raw
    ##       raw_var: "TEMP"
    ##       tgt_var: "VSTESTCD"
    ##       tgt_val: "TEMP"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66741"
    ##   - output: vs_temp
    ##     name: workr::RunQuery
    ##     params:
    ##       df: vs_temp
    ##       strQuery: "SELECT * FROM df WHERE VSTESTCD IS NOT NULL"
    ##   - output: vs_temp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_temp
    ##       raw_dat: vs_raw
    ##       raw_var: "TEMP"
    ##       tgt_var: "VSTEST"
    ##       tgt_val: "Temperature"
    ##       ct_spec: study_ct
    ##       ct_clst: "C67153"
    ##   - output: vs_temp
    ##     name: sdtm.oak::assign_no_ct
    ##     params:
    ##       tgt_dat: vs_temp
    ##       raw_dat: vs_raw
    ##       raw_var: "TEMP"
    ##       tgt_var: "VSORRES"
    ##   - output: vs_temp
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_temp
    ##       raw_dat: vs_raw
    ##       raw_var: "TEMP"
    ##       tgt_var: "VSORRESU"
    ##       tgt_val: "C"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66770"
    ##   - output: vs_temp
    ##     name: sdtm.oak::assign_ct
    ##     params:
    ##       tgt_dat: vs_temp
    ##       raw_dat: vs_raw
    ##       raw_var: "TEMPLOC"
    ##       tgt_var: "VSLOC"
    ##       ct_spec: study_ct
    ##       ct_clst: "C74456"
    ## 
    ##   - output: vs_oxysat
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       raw_dat: vs_raw
    ##       raw_var: "OXY_SAT"
    ##       tgt_var: "VSTESTCD"
    ##       tgt_val: "OXYSAT"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66741"
    ##   - output: vs_oxysat
    ##     name: workr::RunQuery
    ##     params:
    ##       df: vs_oxysat
    ##       strQuery: "SELECT * FROM df WHERE VSTESTCD IS NOT NULL"
    ##   - output: vs_oxysat
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_oxysat
    ##       raw_dat: vs_raw
    ##       raw_var: "OXY_SAT"
    ##       tgt_var: "VSTEST"
    ##       tgt_val: "Oxygen Saturation"
    ##       ct_spec: study_ct
    ##       ct_clst: "C67153"
    ##   - output: vs_oxysat
    ##     name: sdtm.oak::assign_no_ct
    ##     params:
    ##       tgt_dat: vs_oxysat
    ##       raw_dat: vs_raw
    ##       raw_var: "OXY_SAT"
    ##       tgt_var: "VSORRES"
    ##   - output: vs_oxysat
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_oxysat
    ##       raw_dat: vs_raw
    ##       raw_var: "OXY_SAT"
    ##       tgt_var: "VSORRESU"
    ##       tgt_val: "%"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66770"
    ##   - output: vs_oxysat
    ##     name: sdtm.oak::assign_ct
    ##     params:
    ##       tgt_dat: vs_oxysat
    ##       raw_dat: vs_raw
    ##       raw_var: "LAT"
    ##       tgt_var: "VSLAT"
    ##       ct_spec: study_ct
    ##       ct_clst: "C99073"
    ##   - output: vs_oxysat
    ##     name: sdtm.oak::assign_ct
    ##     params:
    ##       tgt_dat: vs_oxysat
    ##       raw_dat: vs_raw
    ##       raw_var: "LOC"
    ##       tgt_var: "VSLOC"
    ##       ct_spec: study_ct
    ##       ct_clst: "C74456"
    ## 
    ##   - output: vs_raw_asmntdn_cond
    ##     name: sdtm.oak::condition_add
    ##     params:
    ##       dat: vs_raw
    ##       '...': !expr rlang::expr(ASMNTDN == 1L)
    ##   - output: vs_vsall
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       raw_dat: vs_raw_asmntdn_cond
    ##       raw_var: "ASMNTDN"
    ##       tgt_var: "VSTESTCD"
    ##       tgt_val: "VSALL"
    ##       ct_spec: study_ct
    ##       ct_clst: "C66741"
    ##   - output: vs_vsall
    ##     name: workr::RunQuery
    ##     params:
    ##       df: vs_vsall
    ##       strQuery: "SELECT * FROM df WHERE VSTESTCD IS NOT NULL"
    ##   - output: vs_vsall
    ##     name: sdtm.oak::hardcode_ct
    ##     params:
    ##       tgt_dat: vs_vsall
    ##       raw_dat: vs_raw
    ##       raw_var: "ASMNTDN"
    ##       tgt_var: "VSTEST"
    ##       tgt_val: "Vital Signs"
    ##       ct_spec: study_ct
    ##       ct_clst: "C67153"
    ## 
    ##   # Combine all the topic variables into a single data frame and map qualifiers
    ##   # applicable to all topic variables
    ##   - output: vs
    ##     name: dplyr::bind_rows
    ##     params:
    ##       vs_vsall: vs_vsall
    ##       vs_sysbp: vs_sysbp
    ##       vs_diabp: vs_diabp
    ##       vs_pulse: vs_pulse
    ##       vs_resp: vs_resp
    ##       vs_temp: vs_temp
    ##       vs_oxysat: vs_oxysat
    ##   - output: vs
    ##     name: sdtm.oak::assign_datetime
    ##     params:
    ##       tgt_dat: vs
    ##       raw_dat: vs_raw
    ##       raw_var: !expr rlang::expr(c("VTLD", "VTLTM"))
    ##       tgt_var: "VSDTC"
    ##       raw_fmt: !expr rlang::expr(c(list(c("d-m-y", "dd-mmm-yyyy")), "H:M"))
    ##   - output: vs
    ##     name: sdtm.oak::assign_ct
    ##     params:
    ##       tgt_dat: vs
    ##       raw_dat: vs_raw
    ##       raw_var: "TMPTC"
    ##       tgt_var: "VSTPT"
    ##       ct_spec: study_ct
    ##       ct_clst: "TPT"
    ##   - output: vs
    ##     name: sdtm.oak::assign_ct
    ##     params:
    ##       tgt_dat: vs
    ##       raw_dat: vs_raw
    ##       raw_var: "TMPTC"
    ##       tgt_var: "VSTPTNUM"
    ##       ct_spec: study_ct
    ##       ct_clst: "TPTNUM"
    ##   - output: vs
    ##     name: sdtm.oak::assign_ct
    ##     params:
    ##       tgt_dat: vs
    ##       raw_dat: vs_raw
    ##       raw_var: "INSTANCE"
    ##       tgt_var: "VISIT"
    ##       ct_spec: study_ct
    ##       ct_clst: "VISIT"
    ##   - output: vs
    ##     name: sdtm.oak::assign_ct
    ##     params:
    ##       tgt_dat: vs
    ##       raw_dat: vs_raw
    ##       raw_var: "INSTANCE"
    ##       tgt_var: "VISITNUM"
    ##       ct_spec: study_ct
    ##       ct_clst: "VISITNUM"
    ##   - output: vs
    ##     name: dplyr::mutate
    ##     params:
    ##       '.data': vs
    ##       STUDYID: 'test_study'
    ##       DOMAIN: 'VS'
    ##       VSCAT: 'VITAL SIGNS'
    ##       USUBJID: !expr rlang::expr(paste0("test_study", "-", .data$patient_number))
    ## ```

This workflow was designed to mimic and follow this respective
`sdtm.oak`
[vignette](https://pharmaverse.github.io/sdtm.oak/articles/findings_domain.html).

## Run Respective Workflows to Arrive at SDTM datasets

``` r

SDTM_workflows <- workr::MakeWorkflowList(
  strNames = c("VS", "DM"),
  strPath = "demo_gsmpharmaverse/workflows/1_RAW_TO_SDTM/",
  strPackage = "workr"
)
SDTM <- workr::RunWorkflows(lWorkflows = SDTM_workflows, lData = lData)
```

``` r

# Take Results and save them as parquets in a SDTM folder 
# or wherever it needs to be saved, gsm has a load/save configuartion as well
purrr::map2(
  SDTM,
  names(SDTM),
  function(x,y) arrow::write_parquet(x, paste0("demo_gsmpharmaverse/data/SDTM/", y,".parquet")) 
)
```

Show SDTM VS (first 6 rows)

| oak_id | raw_source | patient_number | VSTESTCD | VSTEST | VSORRES | VSORRESU | VSPOS | VSLOC | VSLAT | VSDTC | VSTPT | VSTPTNUM | VISIT | VISITNUM | STUDYID | DOMAIN | VSCAT | USUBJID |
|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
| 1 | vitals | 375 | SYSBP | Systolic Blood Pressure | 158.00 | mmHg | PRONE | NA | NA | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 |
| 1 | vitals | 375 | DIABP | Diastolic Blood Pressure | 92.00 | mmHg | PRONE | NA | NA | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 |
| 1 | vitals | 375 | PULSE | Pulse Rate | 63.00 | beats/min | NA | NA | NA | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 |
| 1 | vitals | 375 | RESP | Respiratory Rate | 17.00 | breaths/min | NA | NA | NA | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 |
| 1 | vitals | 375 | TEMP | Temperature | 40.48 | C | NA | SKIN | NA | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 |
| 1 | vitals | 375 | OXYSAT | Oxygen Saturation | 98.00 | % | NA | FINGER | RIGHT | 2015-05-16T07:25 | PREDOSE | 1 | VISIT1 | VISIT1 | test_study | VS | VITAL SIGNS | test_study-375 |
