initData <- function() {
  d <- clindata::rawplus_lb
  set.seed(42)
  subs <- sample(unique(d$subjid), 20)
  list(
    raw = d[d$subjid %in% subs, ]
  )
}
