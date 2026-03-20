initData <- function() {
  list(
    SDTM_DM = data.frame(
      STUDYID = "test_study",
      USUBJID = "test_study-001",
      TRT01A = "DRUG X",
      stringsAsFactors = FALSE
    ),
    SDTM_VS = data.frame(
      STUDYID = "test_study",
      USUBJID = "test_study-001",
      VSTESTCD = "SYSBP",
      VSORRES = 120,
      VSORRESU = "mmHg",
      VSDTC = "2020-01-01T08:00",
      VISIT = "VISIT1",
      VISITNUM = 1,
      VSTPT = "PREDOSE",
      VSTPTNUM = 0,
      stringsAsFactors = FALSE
    )
  )
}
