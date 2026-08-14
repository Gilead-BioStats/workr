# Translation layer between generic (Python-form) pointblank YAML specs and the
# R pointblank package's public API.
#
# Why this exists: R pointblank's YAML reader silently discards every top-level
# key it does not recognize -- including `thresholds:`. A spec authored in Python
# form would therefore interrogate in R with no severity levels at all and report
# success, which is the worst possible failure mode for a validation pipeline.
# Driving the public API directly (create_agent + do.call per step) lets us
# control that, so we can warn on keys that would otherwise vanish.
#
# See https://github.com/Gilead-Public/workr/issues/91

# Python-form -> R-form renames. R errors loudly on these, so they must be
# translated rather than passed through.
.pb_method_renames <- c(
  col_vals_le = "col_vals_lte",
  col_vals_ge = "col_vals_gte"
)

.pb_arg_renames <- c(pattern = "regex")

# Python severity names -> action_levels() argument names. The `*_fraction`
# spellings are the YAML serialization names, not function arguments.
.pb_threshold_renames <- c(
  warning = "warn_at",
  error = "stop_at",
  critical = "notify_at",
  warn_fraction = "warn_at",
  stop_fraction = "stop_at",
  notify_fraction = "notify_at"
)

# Top-level keys we knowingly accept. Anything outside this set is warned about.
# The Python-only governance keys are inert in R but recognized so we stay quiet.
.pb_known_top_keys <- c(
  "tbl",
  "tbl_name",
  "label",
  "lang",
  "locale",
  "thresholds",
  "actions",
  "steps",
  "df_library",
  "owner",
  "consumers",
  "version",
  "brief",
  "final_actions",
  "missing_specs",
  "reference"
)

# The cross-language safe subset. Methods outside this set may exist in R but are
# not guaranteed to round-trip to Python pointblank.
.pb_portable_methods <- c(
  "col_exists",
  "col_vals_gt",
  "col_vals_gte",
  "col_vals_lt",
  "col_vals_lte",
  "col_vals_equal",
  "col_vals_not_equal",
  "col_vals_between",
  "col_vals_not_between",
  "col_vals_in_set",
  "col_vals_not_in_set",
  "col_vals_null",
  "col_vals_not_null",
  "col_vals_regex",
  "rows_distinct",
  "rows_complete",
  "col_schema_match",
  "col_is_character",
  "col_is_numeric",
  "col_is_integer",
  "col_is_logical",
  "col_is_date",
  "col_is_posix",
  "col_is_factor"
)

#' Convert a thresholds mapping into a named list of `action_levels()` arguments
#'
#' Returns a plain list rather than an `action_levels` object so that step-level
#' thresholds can be merged over global ones before construction.
#'
#' @keywords internal
#' @noRd
.PbThresholdArgs <- function(x) {
  if (is.null(x) || !length(x)) {
    return(list())
  }

  nms <- names(x)
  if (is.null(nms)) {
    stop(
      "`thresholds` must be a named mapping (e.g. `warning: 0.1`).",
      call. = FALSE
    )
  }

  renamed <- ifelse(
    nms %in% names(.pb_threshold_renames),
    .pb_threshold_renames[nms],
    nms
  )
  names(x) <- renamed

  unknown <- setdiff(renamed, unname(.pb_threshold_renames))
  if (length(unknown)) {
    warning(
      "Ignoring unrecognized threshold level(s): ",
      paste(unknown, collapse = ", "),
      ". Valid levels are: warning, error, critical.",
      call. = FALSE
    )
  }

  as.list(x[renamed %in% unname(.pb_threshold_renames)])
}

#' Build an `action_levels` object from a list of arguments
#'
#' @keywords internal
#' @noRd
.PbActionLevels <- function(args) {
  if (!length(args)) {
    return(NULL)
  }
  do.call(pointblank::action_levels, args)
}

#' Normalize a single YAML step into a method name and argument list
#'
#' Handles bare-string steps (`- rows_distinct`), which R pointblank's own YAML
#' reader rejects with "argument is of length zero".
#'
#' @keywords internal
#' @noRd
.PbTranslateStep <- function(step, global_thresholds = list()) {
  if (is.character(step) && length(step) == 1L) {
    method <- step
    args <- list()
  } else if (is.list(step) && length(step) == 1L && !is.null(names(step))) {
    method <- names(step)[[1L]]
    args <- step[[1L]] %||% list()
    if (!is.list(args)) {
      args <- as.list(args)
    }
  } else if (is.list(step) && length(step) > 1L && !is.null(names(step))) {
    # Silently using only the first key here would drop the remaining
    # validations without any signal.
    stop(
      "Each entry of `steps` must be a single-key mapping; got ",
      length(step),
      " keys: ",
      paste(names(step), collapse = ", "),
      ". Split these into separate `steps` entries.",
      call. = FALSE
    )
  } else {
    stop(
      "Each entry of `steps` must be a validation method name or a single-key mapping.",
      call. = FALSE
    )
  }

  if (method %in% names(.pb_method_renames)) {
    method <- unname(.pb_method_renames[[method]])
  }

  if (!method %in% .pb_portable_methods) {
    warning(
      "Validation method '",
      method,
      "' is outside the cross-language portable ",
      "subset and may not behave identically in Python pointblank.",
      call. = FALSE
    )
  }

  if (!length(args)) {
    args <- list()
  } else if (!is.null(names(args))) {
    nms <- names(args)
    names(args) <- ifelse(
      nms %in% names(.pb_arg_renames),
      .pb_arg_renames[nms],
      nms
    )
  }

  # Step-level thresholds are MERGED over the global ones rather than replacing
  # them. Verified on pointblank 0.12.4: passing a step-level `actions` replaces
  # the global action_levels outright, leaving unspecified levels as NA -- so a
  # step that tightens only `warning` would silently discard the global `error`.
  # Merging is the safer reading.
  # TODO(#91): confirm Python pointblank's precedence before relying on this.
  if (!is.null(args$thresholds)) {
    merged <- utils::modifyList(
      global_thresholds,
      .PbThresholdArgs(args$thresholds)
    )
    args$thresholds <- NULL
    args$actions <- .PbActionLevels(merged)
  }

  list(method = method, args = args)
}

#' Interrogate a data frame against a generic pointblank spec
#'
#' Ignores any `tbl:` field in the spec and injects `data` directly. `tbl:` is an
#' R formula in R pointblank and a lambda in Python, so it is the one field that
#' provably cannot round-trip between the two languages.
#'
#' @return A pointblank agent that has been interrogated.
#' @keywords internal
#' @noRd
.PbInterrogate <- function(data, spec, domain = NULL) {
  rlang::check_installed(
    "pointblank",
    reason = "to validate data against pointblank-style specs."
  )

  unknown <- setdiff(names(spec), .pb_known_top_keys)
  if (length(unknown)) {
    warning(
      "Ignoring unrecognized top-level spec key(s)",
      if (!is.null(domain)) paste0(" in '", domain, "'") else "",
      ": ",
      paste(unknown, collapse = ", "),
      call. = FALSE
    )
  }

  # Use [[ ]] with exact = TRUE throughout: `spec$tbl` partial-matches `tbl_name`.
  if (!is.null(spec[["tbl", exact = TRUE]])) {
    LogMessage(
      level = "info",
      message = "Ignoring `tbl` in spec; validating data supplied by the workflow."
    )
  }

  global_thresholds <- .PbThresholdArgs(
    spec[["thresholds", exact = TRUE]] %||% spec[["actions", exact = TRUE]]
  )

  agent <- pointblank::create_agent(
    tbl = data,
    tbl_name = spec[["tbl_name", exact = TRUE]] %||% domain %||% "data",
    label = spec[["label", exact = TRUE]],
    actions = .PbActionLevels(global_thresholds)
  )

  for (step in spec[["steps", exact = TRUE]]) {
    translated <- .PbTranslateStep(step, global_thresholds)
    fn <- tryCatch(
      getExportedValue("pointblank", translated$method),
      error = function(e) {
        stop(
          "Unknown pointblank validation method: '",
          translated$method,
          "'.",
          call. = FALSE
        )
      }
    )
    agent <- do.call(fn, c(list(agent), translated$args))
  }

  # Interrogation progress is pointblank's own console chatter; workr reports
  # results through its own logging.
  suppressMessages(pointblank::interrogate(agent))
}

#' Summarize an interrogated agent into a tidy result
#'
#' @keywords internal
#' @noRd
.PbSummarize <- function(agent, domain) {
  vs <- agent$validation_set

  # `notify` is NA when no threshold was set for that level; treat NA as "not
  # breached" so an unset level never aborts a workflow.
  breached <- function(x) isTRUE(any(x, na.rm = TRUE))

  level <- if (breached(vs$notify)) {
    "critical"
  } else if (breached(vs$stop)) {
    "error"
  } else if (breached(vs$warn)) {
    "warning"
  } else {
    "pass"
  }

  failed <- vs[!vs$all_passed %in% TRUE, , drop = FALSE]

  list(
    domain = domain,
    dialect = "pointblank",
    level = level,
    passed = level == "pass",
    n_steps = nrow(vs),
    n_failed_steps = nrow(failed),
    failed_steps = failed$assertion_type,
    agent = agent
  )
}
