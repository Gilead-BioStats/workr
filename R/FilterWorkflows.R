#' Filter a workflow list by metadata fields
#'
#' @description `r lifecycle::badge("stable")`
#'
#'   Filter a named list of workflows by matching zero or more `meta` fields
#'   against supplied values. Each `name = value` pair in `...` is applied
#'   sequentially (AND logic): a workflow must satisfy every filter to be
#'   retained.
#'
#' @param lWorkflows `list` A named list of workflows, as returned by
#'   [MakeWorkflowList()].
#' @param ... `name = value` pairs where each name is a `meta` field to filter
#'   on (e.g., `Category`, `Type`, `Active`) and the value determines which
#'   workflows are kept. Field lookup is case-insensitive. Workflows that lack
#'   the specified field entirely are removed. The class of each value controls
#'   matching behaviour:
#'   - `character`: keep workflows where any element of `meta[[field]]` matches
#'     any element of `value` (case-insensitive).
#'   - `logical`: keep workflows where `meta[[field]]` coerces to the given
#'     `TRUE`/`FALSE` value (coercion handles YAML string forms like `"true"`).
#'   - `numeric`: keep workflows where `meta[[field]]` equals any element of
#'     `value` (equality only; no comparison operators).
#'   - other types: an informative error is raised.
#'
#' @examples
#' lWorkflows <- MakeWorkflowList(strPath = "example_workflows", strPackage = "workr")
#'
#' # Filter by a character field
#' lWorkflowsAnalysis <- FilterWorkflows(lWorkflows, Type = "Analysis")
#'
#' # Multiple filters (AND logic)
#' lWorkflowsAnalysisSite <- FilterWorkflows(lWorkflows, Type = "Analysis", GroupLevel = "site")
#'
#' @returns `list` A filtered named list of workflows.
#'
#' @export
FilterWorkflows <- function(lWorkflows, ...) {
  dots <- rlang::list2(...)
  n_total <- length(lWorkflows)
  result <- purrr::reduce2(
    names(dots),
    dots,
    \(lWf, field, value) .filter_workflows_impl(lWf, field, value),
    .init = lWorkflows
  )
  if (length(dots) > 0) {
    n_kept <- length(result)
    LogMessage(
      message = "Kept {n_kept} of {n_total} workflows after applying {length(dots)} filter(s)."
    )
  }
  result
}

#' S3 generic for workflow filtering implementation
#'
#' Dispatches on `value` to apply type-specific filtering logic. Called by
#' [FilterWorkflows()], which handles the reduce loop and overall logging.
#'
#' @keywords internal
#' @noRd
.filter_workflows_impl <- function(lWorkflows, field, value, ...) {
  UseMethod(".filter_workflows_impl", value)
}

#' @export
#' @noRd
.filter_workflows_impl.character <- function(lWorkflows, field, value, ...) {
  result <- .keep_workflows(
    lWorkflows,
    field,
    value,
    function(meta_val, value) {
      # meta field may itself be a list (e.g., Category: [kri, site_risk_score])
      any(tolower(as.character(unlist(meta_val))) %in% tolower(value))
    }
  )
  value_fmt <- paste(value, collapse = ", ")
  LogMessage(
    message = "Keeping {length(result)} of {length(lWorkflows)} workflows where {field} matches {value_fmt}."
  )
  result
}

#' @export
#' @noRd
.filter_workflows_impl.logical <- function(lWorkflows, field, value, ...) {
  result <- .keep_workflows(
    lWorkflows,
    field,
    value,
    function(meta_val, value) {
      # meta_val may be a string ("true"/"false") when quoted in YAML, so
      # coerce the meta field value — not the dispatch value — to logical.
      isTRUE(as.logical(meta_val)) == value
    }
  )
  LogMessage(
    message = "Keeping {length(result)} of {length(lWorkflows)} workflows where {field} matches {value}."
  )
  result
}

#' @export
#' @noRd
.filter_workflows_impl.numeric <- function(lWorkflows, field, value, ...) {
  result <- .keep_workflows(
    lWorkflows,
    field,
    value,
    function(meta_val, value) {
      suppressWarnings(as.numeric(meta_val)) %in% value
    }
  )
  value_fmt <- paste(value, collapse = ", ")
  LogMessage(
    message = "Keeping {length(result)} of {length(lWorkflows)} workflows where {field} matches {value_fmt}."
  )
  result
}

#' @export
#' @noRd
.filter_workflows_impl.default <- function(lWorkflows, field, value, ...) {
  stop(
    paste(
      "Unsupported filter value type:",
      paste(class(value), collapse = "/"),
      "- use a character, logical, or numeric value for `value`."
    ),
    call. = FALSE
  )
}

#' Keep workflows where a meta field satisfies a predicate
#'
#' Handles the common structure of `.filter_workflows_impl()` methods: resolving
#' the field name case-insensitively per workflow, dropping workflows where the
#' field is absent, and applying `predicate` to the resolved value.
#'
#' @param lWorkflows `list` A named list of workflows.
#' @param field `character` The meta field name to look up (case-insensitive).
#' @param value The filter value; passed through to `predicate`.
#' @param predicate `function(meta_val, value)` Called with the resolved field
#'   value and `value` for each workflow. Should return `TRUE` to keep the
#'   workflow.
#'
#' @keywords internal
#' @noRd
.keep_workflows <- function(lWorkflows, field, value, predicate) {
  purrr::keep(lWorkflows, function(wf) {
    field_key <- names(wf$meta)[tolower(names(wf$meta)) == tolower(field)]
    # We explicitly exclude anything that doesn't have the field.
    if (!length(field_key)) {
      return(FALSE)
    }
    meta_val <- wf$meta[[field_key]]
    if (is.null(meta_val)) {
      return(FALSE)
    }
    predicate(meta_val, value)
  })
}
