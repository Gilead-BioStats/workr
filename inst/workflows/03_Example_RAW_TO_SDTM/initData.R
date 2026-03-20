initData <- function() {
  list(
    dm_raw = data.frame(
      STUDYID = "test_study",
      USUBJID = "test_study-001",
      stringsAsFactors = FALSE
    ),
    vs_raw = data.frame(
      PATNUM = "001",
      SYS_BP = 120,
      DIA_BP = 80,
      PULSE = 72,
      RESPRT = 16,
      TEMP = 36.7,
      OXY_SAT = 98,
      SUBPOS = "SITTING",
      TEMPLOC = "ORAL",
      LAT = "LEFT",
      LOC = "ARM",
      ASMNTDN = 1L,
      VTLD = "01-01-2020",
      VTLTM = "08:00",
      TMPTC = "PREDOSE",
      INSTANCE = "VISIT1",
      patient_number = "001",
      stringsAsFactors = FALSE
    ),
    study_ct = data.frame(stringsAsFactors = FALSE)
  )
}
