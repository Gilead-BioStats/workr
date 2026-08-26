#' Hook trace
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Records every load/save hook invocation of a run: which scope fired, for
#' which workflow, through which provider, how long it took, and whether it
#' failed. When storage is a hook, this is the answer to "where did it go
#' wrong?" for a run nobody watched -- a cron job, an AWS batch run, an
#' overnight `rv run`.
#'
#' Providers add their own detail rows with [HookTraceRecord()]: the object key
#' they read or wrote, the domain it satisfied, and where it came from. Those
#' rows inherit the scope, action and workflow of the hook that is running, so
#' a provider never has to know how it was invoked.
#'
#' @details
#' Every row has the same columns:
#'
#' * `scope` -- `project`, `phase` or `workflow`, i.e. which `lConfig` slot the
#'   hook came from.
#' * `action` -- `load` or `save`.
#' * `workflow` -- `Type_ID` of the workflow, or `NA` for project-scope hooks.
#' * `provider` -- the registered provider name, or `<function>` for a literal
#'   function.
#' * `event` -- `hook` for the invocation summary, `detail` for a provider row.
#' * `status` -- `ok` or `error` on `hook` rows.
#' * `duration_ms` -- wall time of the invocation, on `hook` rows.
#' * `key`, `domain`, `source` -- provider detail: the object acted on, the
#'   domain it satisfied, and where it resolved from (e.g. `s3`, `lData`,
#'   `missing`).
#' * `message` -- error message, or free text from a provider.
#'
#' The trace lives for the session. [RunStudy()] resets it per run; call
#' [HookTraceReset()] yourself when driving `RunProject()` directly.
#'
#' @return
#' `HookTrace()` returns a `data.frame` with one row per event, in order.
#' `HookTraceReset()` invisibly returns `TRUE`.
#' `HookTraceRecord()` invisibly returns `TRUE`.
#'
#' @examples
#' HookTraceReset()
#' HookTrace()
#'
#' @name HookTrace
NULL

.workr_hook_trace <- local({
  trace <- new.env(parent = emptyenv())
  trace$events <- list()
  trace$context <- NULL
  trace
})

HOOK_TRACE_COLUMNS <- c(
  "scope", "action", "workflow", "provider", "event",
  "status", "duration_ms", "key", "domain", "source", "message"
)

#' @rdname HookTrace
#' @export
HookTraceReset <- function() {
  .workr_hook_trace$events <- list()
  .workr_hook_trace$context <- NULL
  invisible(TRUE)
}

#' @rdname HookTrace
#' @export
HookTrace <- function() {
  events <- .workr_hook_trace$events
  empty <- stats::setNames(
    lapply(HOOK_TRACE_COLUMNS, function(column) {
      if (identical(column, "duration_ms")) numeric() else character()
    }),
    HOOK_TRACE_COLUMNS
  )
  if (length(events) == 0) {
    return(as.data.frame(empty, stringsAsFactors = FALSE))
  }

  do.call(
    rbind,
    lapply(events, function(event) {
      as.data.frame(
        utils::modifyList(
          stats::setNames(
            lapply(HOOK_TRACE_COLUMNS, function(column) {
              if (identical(column, "duration_ms")) NA_real_ else NA_character_
            }),
            HOOK_TRACE_COLUMNS
          ),
          event
        ),
        stringsAsFactors = FALSE
      )
    })
  )
}

#' @param key `string` Object key, path or table the provider acted on.
#' @param domain `string` Data domain the object satisfied.
#' @param source `string` Where the object resolved from, e.g. `"s3"`,
#'   `"lData"`, `"missing"`.
#' @param message `string` Free text.
#'
#' @rdname HookTrace
#' @export
HookTraceRecord <- function(
  key = NA_character_,
  domain = NA_character_,
  source = NA_character_,
  message = NA_character_
) {
  context <- .workr_hook_trace$context
  hook_trace_append(utils::modifyList(
    context %||% list(scope = NA_character_, action = NA_character_,
                      workflow = NA_character_, provider = NA_character_),
    list(
      event = "detail",
      key = as.character(key),
      domain = as.character(domain),
      source = as.character(source),
      message = as.character(message)
    )
  ))
}

hook_trace_append <- function(event) {
  .workr_hook_trace$events[[length(.workr_hook_trace$events) + 1L]] <- event
  invisible(TRUE)
}

# The provider name when `lConfig` named one, so a trace row says which
# implementation ran rather than just "something was configured".
hook_provider_label <- function(lConfig, strField) {
  # A project-scope hook is a function by the time RunProject() sees it, so the
  # name the configuration used is carried alongside it.
  if (is.list(lConfig)) {
    strName <- lConfig[[paste0(strField, "Name")]]
    if (is.character(strName) && length(strName) == 1) {
      return(strName)
    }
  }

  value <- if (is.environment(lConfig)) {
    if (exists(strField, envir = lConfig, inherits = FALSE)) {
      get(strField, envir = lConfig, inherits = FALSE)
    }
  } else if (is.list(lConfig)) {
    lConfig[[strField]]
  }

  if (is.character(value) && length(value) == 1) value else "<function>"
}

# Run one hook invocation inside the trace: providers called within `expr` see
# the enclosing context, and the invocation itself is timed and recorded --
# including when it throws, which is the row that matters at 3am.
with_hook_trace <- function(scope, action, workflow, provider, expr) {
  previous <- .workr_hook_trace$context
  .workr_hook_trace$context <- list(
    scope = scope,
    action = action,
    workflow = workflow %||% NA_character_,
    provider = provider %||% NA_character_
  )
  started <- Sys.time()
  on.exit(.workr_hook_trace$context <- previous, add = TRUE)

  record <- function(status, message = NA_character_) {
    hook_trace_append(utils::modifyList(
      .workr_hook_trace$context,
      list(
        event = "hook",
        status = status,
        duration_ms = as.numeric(difftime(Sys.time(), started, units = "secs")) * 1000,
        message = message
      )
    ))
  }

  result <- withCallingHandlers(
    tryCatch(
      expr,
      error = function(error) {
        record("error", conditionMessage(error))
        stop(error)
      }
    ),
    warning = function(warning) {
      HookTraceRecord(message = conditionMessage(warning), source = "warning")
    }
  )

  record("ok")
  result
}

# Which lConfig slot a workflow-level hook came from. RunProject() stamps
# `HookScope` when a `lConfig$phases` entry contributed the hook, so a
# phase-scoped override is distinguishable from the top-level one.
hook_scope <- function(lConfig) {
  scope <- if (is.environment(lConfig)) {
    if (exists("HookScope", envir = lConfig, inherits = FALSE)) {
      get("HookScope", envir = lConfig, inherits = FALSE)
    }
  } else if (is.list(lConfig)) {
    lConfig[["HookScope"]]
  }

  if (is.character(scope) && length(scope) == 1) scope else "workflow"
}

workflow_trace_name <- function(lWorkflow) {
  if (is.null(lWorkflow)) {
    return(NA_character_)
  }
  paste(lWorkflow$meta$Type %||% "", lWorkflow$meta$ID %||% "", sep = "_")
}
