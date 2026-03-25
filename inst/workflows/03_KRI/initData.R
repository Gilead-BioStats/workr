initData <- function() {
  dm <- gsm.core::lSource$Raw_SUBJ
  ae <- gsm.core::lSource$Raw_AE
  pd <- gsm.core::lSource$Raw_PD

  AE_data <- list(
    Raw_SUBJ = dm,
    Raw_AE = ae,
    Raw_PD = pd
  )
  
  return(AE_data)
}
