#' @keywords internal
"_PACKAGE"

## usethis namespace: start

#' @import rlang
#' @importFrom dplyr %>%
#' @importFrom dplyr select
#' @importFrom glue glue
#' @importFrom lifecycle badge
#' @importFrom lifecycle deprecated
#' @importFrom purrr keep map map2 map_chr map_dbl imap
#' @importFrom utils capture.output read.csv str write.csv
## usethis namespace: end

NULL

workr_register_builtin_providers <- function() {
  register_load_provider("github_artifact", github_artifact_load_provider)
  register_save_provider("github_artifact", github_artifact_save_provider)
  register_load_provider("gsm.datasim", gsm_datasim_load_provider)
  invisible(TRUE)
}

.onLoad <- function(libname, pkgname) {
  workr_register_builtin_providers()
  invisible(NULL)
}
