#' Internal message helper
#'
#' @keywords internal
#' @noRd
LogMessage <- function(level = "info", message, cli_detail = NULL) {
  msg <- glue::glue(message, .envir = parent.frame())
  prefix <- toupper(level)
  if (!is.null(cli_detail)) {
    msg <- glue::glue("{msg}")
  }
  message("[", prefix, "] ", msg)
}

#' Resolve function namespaced or local
#'
#' @keywords internal
#' @noRd
GetStrFunctionIfNamespaced <- function(strName) {
  if (!is.character(strName) || length(strName) != 1) {
    stop("strName must be a single character string")
  }

  if (grepl("::", strName, fixed = TRUE)) {
    parts <- strsplit(strName, "::", fixed = TRUE)[[1]]
    if (length(parts) != 2) {
      stop("Invalid namespaced function string")
    }
    pkg <- parts[[1]]
    fn <- parts[[2]]
    return(getExportedValue(pkg, fn))
  }

  if (exists(strName, envir = .GlobalEnv, inherits = FALSE)) {
    return(get(strName, envir = .GlobalEnv, inherits = FALSE))
  }

  if (exists(strName, envir = parent.frame(), inherits = TRUE)) {
    return(get(strName, envir = parent.frame(), inherits = TRUE))
  }

  if (exists(strName, envir = asNamespace("workr"), inherits = TRUE)) {
    return(get(strName, envir = asNamespace("workr"), inherits = TRUE))
  }

  stop(glue::glue("Function '{strName}' not found."))
}

#' Basic spec validation helper
#'
#' @keywords internal
#' @noRd
CheckSpec <- function(lData, lSpec) {
  if (is.null(lSpec) || is.null(lData)) {
    return(invisible(TRUE))
  }

  if (!is.list(lSpec) || length(lSpec) == 0) {
    return(invisible(TRUE))
  }

  for (domain in names(lSpec)) {
    if (!domain %in% names(lData)) {
      next
    }

    spec <- lSpec[[domain]]
    required_cols <- NULL
    if (is.list(spec)) {
      required_cols <- spec$required_cols %||% spec$required %||% spec$columns
    }

    if (!is.null(required_cols)) {
      missing_cols <- setdiff(required_cols, names(lData[[domain]]))
      if (length(missing_cols) > 0) {
        stop(glue::glue("Missing required columns in '{domain}': {paste(missing_cols, collapse = ', ')}"))
      }
    }
  }

  invisible(TRUE)
}

`%||%` <- function(x, y) {
  if (!is.null(x)) x else y
}

#' Simple conditional stop helper
#'
#' @keywords internal
#' @noRd
stop_if <- function(cnd, message) {
  if (isTRUE(cnd)) {
    stop(message, call. = FALSE)
  }
  invisible(TRUE)
}
