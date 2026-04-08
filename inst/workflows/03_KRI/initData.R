initData <- function() {
  dm <- clindata::rawplus_dm
  ae <- clindata::rawplus_ae

  list(
    Raw_SUBJ = dm,
    Raw_AE = ae
  )
}
