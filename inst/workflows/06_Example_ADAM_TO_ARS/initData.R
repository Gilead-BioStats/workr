initData <- function() {
  list(
    ADVS = arrow::read_parquet("inst/demo_gsmpharmaverse/data/ADAM/ADAM_ADVS.parquet")
  )
}
