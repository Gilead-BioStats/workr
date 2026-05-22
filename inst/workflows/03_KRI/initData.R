initData <- function() {
  dm <- data.frame(
    studyid = rep("STUDY-1", 4),
    invid = c("SITE-01", "SITE-01", "SITE-02", "SITE-02"),
    country = c("US", "US", "CA", "CA"),
    subjid = c("S001", "S002", "S003", "S004"),
    subject_nsv = c("SUBJ-001", "SUBJ-002", "SUBJ-003", "SUBJ-004"),
    enrollyn = c("Y", "Y", "Y", "N"),
    timeonstudy = c(40L, 35L, 52L, 10L),
    firstparticipantdate = as.Date(c("2024-01-05", "2024-01-07", "2024-01-10", "2024-01-11")),
    firstdosedate = as.Date(c("2024-01-06", "2024-01-08", "2024-01-11", "2024-01-12")),
    timeontreatment = c(38, 33, 50, 8),
    agerep = c("18-64", "18-64", "65+", "18-64"),
    sex = c("F", "M", "F", "M"),
    race = c("WHITE", "ASIAN", "BLACK", "WHITE"),
    mincreated_dts = as.POSIXct(c("2024-02-01 08:00:00", "2024-02-01 08:05:00", "2024-02-01 08:10:00", "2024-02-01 08:15:00"), tz = "UTC"),
    stringsAsFactors = FALSE
  )

  ae <- data.frame(
    studyid = rep("STUDY-1", 6),
    subjid = c("S001", "S001", "S002", "S003", "S003", "S004"),
    aeser = c("N", "Y", "N", "Y", "N", "N"),
    aest_dt = as.Date(c("2024-02-02", "2024-02-10", "2024-02-05", "2024-02-08", "2024-02-20", "2024-02-03")),
    aeen_dt = as.Date(c("2024-02-04", "2024-02-13", "2024-02-07", "2024-02-09", "2024-02-23", "2024-02-05")),
    mdrpt_nsv = c("Headache", "Nausea", "Fatigue", "Dizziness", "Rash", "Cough"),
    mdrsoc_nsv = c("Nervous system disorders", "Gastrointestinal disorders", "General disorders", "Nervous system disorders", "Skin disorders", "Respiratory disorders"),
    aetoxgr = c("1", "2", "1", "3", "1", "1"),
    aeongo = c("N", "N", "N", "N", "Y", "N"),
    aerel = c("Y", "Y", "N", "Y", "N", "N"),
    mincreated_dts = as.POSIXct(c("2024-02-02 09:00:00", "2024-02-10 09:10:00", "2024-02-05 09:20:00", "2024-02-08 09:30:00", "2024-02-20 09:40:00", "2024-02-03 09:50:00"), tz = "UTC"),
    stringsAsFactors = FALSE
  )

  list(
    Raw_SUBJ = dm,
    Raw_AE = ae
  )
}
