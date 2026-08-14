#' Emit a formatted log record
#'
#' The single point where log output actually reaches the console. Keeping this
#' separate from `LogMessage()` gives tests a seam: mock `appender()` with
#' `local_mocked_bindings()` to silence expected levels without wrapping every
#' call in `suppressMessages()`.
#'
#' @param level Log level, e.g. `"info"` or `"warn"`.
#' @param msg Already-formatted message text.
#'
#' @keywords internal
#' @noRd
appender <- function(level, msg) {
  message("[", toupper(level), "] ", msg)
}

#' Internal message helper
#'
#' @keywords internal
#' @noRd
LogMessage <- function(level = "info", message, cli_detail = NULL) {
  msg <- glue::glue(message, .envir = parent.frame())
  if (!is.null(cli_detail)) {
    msg <- glue::glue("{msg}")
  }
  appender(level, msg)
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

  # `inherits = TRUE` walks the namespace's parents -- imports, base, and the
  # attached search path -- so base/attached functions like `read.csv` resolve
  # here too, without needing an explicit namespace qualifier.
  if (exists(strName, envir = asNamespace("workr"), inherits = TRUE)) {
    return(get(strName, envir = asNamespace("workr"), inherits = TRUE))
  }

  stop(glue::glue("Function '{strName}' not found."))
}

#' Classify a per-domain spec as legacy or pointblank-style
#'
#' The two dialects are structurally disjoint: a legacy domain spec is always a
#' named list of column definitions, while a pointblank spec is either a path to
#' a `*_spec.yaml` file or a mapping containing `steps`.
#'
#' An unrecognized shape is an error rather than a silent fallback to legacy --
#' a malformed pointblank spec must never quietly degrade into "no validation".
#'
#' @keywords internal
#' @noRd
.SpecDialect <- function(spec, domain) {
  if (is.character(spec) && length(spec) == 1L) {
    return("pointblank_file")
  }

  if (is.list(spec)) {
    if ("steps" %in% names(spec)) {
      return("pointblank_inline")
    }
    # A mapping carrying pointblank-only top-level keys but no `steps` is a
    # malformed pointblank spec, not a legacy one. Falling through to legacy
    # here would validate nothing at all.
    pb_markers <- intersect(
      names(spec),
      c("tbl", "tbl_name", "label", "lang", "locale", "thresholds", "actions")
    )
    if (length(pb_markers) > 0L) {
      stop(
        glue::glue(
          "Spec for domain '{domain}' looks like a pointblank spec \\
          ({paste(pb_markers, collapse = ', ')}) but has no `steps`. \\
          Add a `steps:` list, or remove these keys to use a legacy spec."
        ),
        call. = FALSE
      )
    }
    # A legacy spec is a named list; the historical `required_cols` / `required`
    # / `columns` keys are also legacy.
    if (length(spec) == 0L || !is.null(names(spec))) {
      return("legacy")
    }
  }

  stop(
    glue::glue(
      "Unrecognized spec format for domain '{domain}'. Expected a legacy column \\
      mapping, a path to a pointblank spec file, or a mapping containing `steps`."
    ),
    call. = FALSE
  )
}

#' Validate one domain against a legacy spec
#'
#' Preserves historical behavior exactly: column *existence* is checked, and any
#' declared `type:` is deliberately ignored. Enforcing types here would newly
#' fail workflows that pass today on unchanged data; migrate a spec to
#' pointblank form to opt into type checking.
#'
#' The `_all: {required: true}` wildcard is deliberately permissive. It marks a
#' domain as "needed, but not picky about its shape", so it asserts only that
#' the table is non-empty -- it names no columns, so it can claim nothing about
#' them. Use a pointblank spec where real column-level assertions are wanted.
#'
#' @keywords internal
#' @noRd
.CheckSpecLegacy <- function(data, spec, domain) {
  required_cols <- NULL
  if (is.list(spec)) {
    required_cols <- spec$required_cols %||% spec$required %||% spec$columns
  }

  if (!is.null(required_cols)) {
    missing_cols <- setdiff(required_cols, names(data))
    if (length(missing_cols) > 0) {
      stop(glue::glue(
        "Missing required columns in '{domain}': {paste(missing_cols, collapse = ', ')}"
      ))
    }
  }

  wildcard <- .SpecWildcardRequired(spec)
  if (wildcard) {
    stop_if(
      is.null(ncol(data)) || ncol(data) == 0L || nrow(data) == 0L,
      "Required input '{domain}' is empty."
    )
  }

  n_steps <- length(required_cols %||% character(0)) + as.integer(wildcard)

  list(
    domain = domain,
    dialect = "legacy",
    level = "pass",
    passed = TRUE,
    n_steps = n_steps,
    n_failed_steps = 0L,
    failed_steps = character(0),
    agent = NULL
  )
}

#' Is a legacy spec's `_all` wildcard set to required?
#'
#' @keywords internal
#' @noRd
.SpecWildcardRequired <- function(spec) {
  if (!is.list(spec)) {
    return(FALSE)
  }
  isTRUE(spec[["_all", exact = TRUE]]$required)
}

#' Resolve a spec file path, optionally relative to the workflow file
#'
#' @keywords internal
#' @noRd
.ResolveSpecPath <- function(spec, domain, strPath = NULL) {
  path <- spec
  if (!is.null(strPath) && !file.exists(path)) {
    path <- file.path(dirname(strPath), spec)
  }

  stop_if(
    !file.exists(path),
    "Spec file for domain '{domain}' not found: {spec}"
  )

  path
}

#' Load a per-domain spec into its parsed pointblank form
#'
#' File-referenced and inline pointblank specs converge on the same
#' representation here, so downstream code has a single path to handle.
#'
#' @keywords internal
#' @noRd
.LoadSpec <- function(spec, dialect, domain, strPath = NULL) {
  if (identical(dialect, "pointblank_file")) {
    return(yaml::read_yaml(.ResolveSpecPath(spec, domain, strPath)))
  }
  spec
}

#' Apply the spec failure contract to one domain's results
#'
#' `error` and `critical` abort the workflow; `warning` is logged and execution
#' continues. See <https://github.com/Gilead-Public/workr/issues/91>.
#'
#' @keywords internal
#' @noRd
.EnforceSpecResult <- function(result) {
  if (result$level %in% c("error", "critical")) {
    stop(
      glue::glue(
        "Spec validation failed for '{result$domain}' at level '{result$level}': \\
        {result$n_failed_steps} of {result$n_steps} step(s) failed \\
        ({paste(unique(result$failed_steps), collapse = ', ')})."
      ),
      call. = FALSE
    )
  }

  if (identical(result$level, "warning")) {
    LogMessage(
      level = "warn",
      message = paste0(
        "Spec validation warning for '",
        result$domain,
        "': ",
        result$n_failed_steps,
        " of ",
        result$n_steps,
        " step(s) failed."
      )
    )
  }

  invisible(result)
}

#' Validate a single domain against its spec
#'
#' Dispatches on dialect, then enforces the failure contract.
#'
#' @keywords internal
#' @noRd
.CheckSpecDomain <- function(data, spec, domain, strPath = NULL) {
  dialect <- .SpecDialect(spec, domain)

  if (identical(dialect, "legacy")) {
    return(.CheckSpecLegacy(data, spec, domain))
  }

  spec <- .LoadSpec(spec, dialect, domain, strPath)
  result <- .PbSummarize(.PbInterrogate(data, spec, domain), domain)
  .EnforceSpecResult(result)

  result
}

#' Spec validation helper
#'
#' Validates `lData` against `lSpec`, supporting both the legacy workr spec
#' format and generic (Python-compatible) pointblank specs. See
#' <https://github.com/Gilead-Public/workr/issues/91>.
#'
#' Failure contract: `error` and `critical` threshold breaches abort; `warning`
#' is logged and execution continues. Legacy specs remain a hard stop.
#'
#' @param lData Named list of domain data frames.
#' @param lSpec Named list mapping domain names to specs.
#' @param strPath Optional path to the workflow file, used to resolve relative
#'   spec file paths.
#'
#' @return Invisibly, a named list of per-domain validation results.
#' @keywords internal
#' @noRd
CheckSpec <- function(lData, lSpec, strPath = NULL) {
  if (is.null(lSpec) || is.null(lData)) {
    return(invisible(list()))
  }

  if (!is.list(lSpec) || length(lSpec) == 0) {
    return(invisible(list()))
  }

  domains <- names(lSpec)

  missing_domains <- setdiff(domains, names(lData))
  stop_if(
    length(missing_domains) > 0,
    "Spec-declared input '{missing_domains[[1]]}' not found in lData."
  )

  results <- lapply(
    domains,
    function(domain) {
      .CheckSpecDomain(lData[[domain]], lSpec[[domain]], domain, strPath)
    }
  )
  names(results) <- domains

  invisible(results)
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
    stop(glue::glue(message, .envir = parent.frame()), call. = FALSE)
  }
  invisible(TRUE)
}
