initData <- function() {
  d <- data.frame(
    subjid = c("S001", "S001", "S002", "S002", "S003", "S003", "S004", "S004"),
    lbtstnam = c(
      "Cholesterol (High Performance)", "Glucose",
      "Cholesterol (High Performance)", "Glucose",
      "Cholesterol (High Performance)", "Glucose",
      "Cholesterol (High Performance)", "Glucose"
    ),
    siresn = c(205, 98, 187, 102, 223, 95, 176, 99),
    stringsAsFactors = FALSE
  )

  set.seed(42)
  subs <- sample(unique(d$subjid), 3)
  list(
    raw = d[d$subjid %in% subs, ]
  )
}
