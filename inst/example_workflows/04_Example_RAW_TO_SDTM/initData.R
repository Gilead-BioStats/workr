initData <- function() {
  list(
    dm_raw = utils::read.csv(system.file("raw_data/dm.csv", package = "sdtm.oak")),
    vs_raw =  utils::read.csv(system.file("raw_data/vitals_raw_data.csv", package = "sdtm.oak")),
    study_ct = utils::read.csv(system.file("raw_data/sdtm_ct.csv", package = "sdtm.oak"))
  )
}
