initData <- function() {
  list(
    render_env = new.env(parent = globalenv()),
    ADVS = arrow::read_parquet("inst/demo_gsmpharmaverse/data/ADAM/ADAM_ADVS.parquet")
  )
}
