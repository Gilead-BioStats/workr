test_that("RunQuery executes SQL against a data frame", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("dbplyr")
  skip_if_not_installed("duckdb")

  df <- data.frame(x = 1:3, y = c("a", "b", "c"))
  result <- RunQuery("SELECT x FROM df WHERE x > 1", df)

  expect_s3_class(result, "data.frame")
  expect_equal(result$x, c(2, 3))
})

test_that("RunQuery validates FROM df placeholder", {
  expect_error(RunQuery("SELECT 1", data.frame(x = 1)), "FROM df")
})
