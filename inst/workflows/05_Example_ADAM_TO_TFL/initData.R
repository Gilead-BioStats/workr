initData <- function() {
  list(
    render_env = new.env(parent = globalenv()),
    ADVS = data.frame(
      STUDYID = "test_study",
      USUBJID = "test_study-001",
      TRT01A = "DRUG X",
      PARAMCD = "MAP",
      AVAL = 93,
      VISIT = "VISIT1",
      VISITNUM = 1,
      VSTPT = "PREDOSE",
      stringsAsFactors = FALSE
    )
  )
}
