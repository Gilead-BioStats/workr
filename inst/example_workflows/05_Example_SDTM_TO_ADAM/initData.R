initData <- function() {
  list(
    SDTM_DM = arrow::read_parquet("inst/demo_gsmpharmaverse/data/SDTM/SDTM_DM.parquet"),
    SDTM_VS = arrow::read_parquet("inst/demo_gsmpharmaverse/data/SDTM/SDTM_VS.parquet")
  )
}
