#' Check a hook trace
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Turns a [HookTrace()] into a small table of pass/fail assertions: did every
#' configured hook actually fire, did any hook raise, did any workflow ask for
#' a domain nothing could resolve, and did every workflow that ran persist
#' anything.
#'
#' The point is that "the run was green" and "storage did the work" are
#' different claims. A run whose save hook silently never fired still produces
#' results in memory and exits 0; this is what catches that in an unattended
#' AWS or cron run.
#'
#' @param dfTrace `data.frame` A trace from [HookTrace()].
#' @param lConfig `list` The `lConfig` the run used, so the checks know which
#'   hooks were supposed to fire. Default `NULL`, i.e. check only what the
#'   trace itself can prove.
#' @param dfFailures `data.frame` The `failures` element of a
#'   `bContinueOnError = TRUE` run summary. Default `NULL`.
#'
#' @return A `data.frame` with columns `check`, `ok` and `detail`.
#'
#' @examples
#' CheckHookTrace(HookTrace())
#'
#' @export
CheckHookTrace <- function(dfTrace, lConfig = NULL, dfFailures = NULL) {
  stop_if(!is.data.frame(dfTrace), "[ dfTrace ] must be a data.frame.")

  lChecks <- list()
  add <- function(check, ok, detail) {
    lChecks[[length(lChecks) + 1L]] <<- data.frame(
      check = check, ok = isTRUE(ok), detail = as.character(detail),
      stringsAsFactors = FALSE
    )
  }

  dfHooks <- dfTrace[dfTrace$event %in% "hook", , drop = FALSE]
  dfDetail <- dfTrace[dfTrace$event %in% "detail", , drop = FALSE]

  fired <- function(scope, action) {
    sum(dfHooks$scope %in% scope & dfHooks$action %in% action)
  }

  # Every hook the configuration declares must have fired at least once.
  for (lScope in hook_expectations(lConfig)) {
    intFired <- fired(lScope$scope, lScope$action)
    add(
      sprintf("%s %s hook fired", lScope$scope, lScope$action),
      intFired > 0,
      sprintf("%d invocation(s) of %s", intFired, lScope$provider)
    )
  }

  dfErrors <- dfHooks[dfHooks$status %in% "error", , drop = FALSE]
  add(
    "no hook raised an error",
    nrow(dfErrors) == 0,
    if (nrow(dfErrors) == 0) {
      sprintf("%d invocation(s) ok", nrow(dfHooks))
    } else {
      paste(
        sprintf("%s %s/%s: %s", dfErrors$scope, dfErrors$action, dfErrors$workflow, dfErrors$message),
        collapse = "; "
      )
    }
  )

  dfMissing <- dfDetail[dfDetail$source %in% "missing", , drop = FALSE]
  add(
    "no input went unresolved",
    nrow(dfMissing) == 0,
    if (nrow(dfMissing) == 0) {
      "none"
    } else {
      paste(unique(sprintf("%s:%s", dfMissing$workflow, dfMissing$domain)), collapse = ", ")
    }
  )

  if (fired(c("workflow", "phase"), "save") > 0) {
    strLoaded <- unique(dfHooks$workflow[dfHooks$action %in% "load" & dfHooks$scope %in% c("workflow", "phase")])
    strSaved <- unique(dfHooks$workflow[dfHooks$action %in% "save" & dfHooks$scope %in% c("workflow", "phase")])
    strFailed <- as.character(dfFailures$workflow %||% character())
    strUnsaved <- setdiff(setdiff(strLoaded, strSaved), strFailed)
    add(
      "every workflow that loaded also saved",
      length(strUnsaved) == 0,
      if (length(strUnsaved) == 0) {
        sprintf("%d workflow(s) saved", length(strSaved))
      } else {
        paste(strUnsaved, collapse = ", ")
      }
    )
  }

  if (!is.null(dfFailures)) {
    add(
      "no workflow failed",
      NROW(dfFailures) == 0,
      sprintf("%d failure(s)", NROW(dfFailures))
    )
  }

  do.call(rbind, lChecks)
}

# Which hooks the configuration says should fire, so a hook that was configured
# and silently never ran is a failed check rather than an absence of evidence.
hook_expectations <- function(lConfig) {
  if (!is.list(lConfig)) {
    return(list())
  }

  lExpected <- list()
  for (strField in c("LoadData", "SaveData")) {
    if (!is.null(lConfig[[strField]])) {
      lExpected[[length(lExpected) + 1L]] <- list(
        scope = "workflow",
        action = if (identical(strField, "LoadData")) "load" else "save",
        provider = hook_provider_label(lConfig, strField)
      )
    }
  }
  for (strPhase in names(lConfig$phases %||% list())) {
    lPhase <- lConfig$phases[[strPhase]]
    for (strField in c("LoadData", "SaveData")) {
      if (!is.null(lPhase[[strField]])) {
        lExpected[[length(lExpected) + 1L]] <- list(
          scope = "phase",
          action = if (identical(strField, "LoadData")) "load" else "save",
          provider = hook_provider_label(lPhase, strField)
        )
      }
    }
  }
  for (strField in c("LoadData", "SaveData")) {
    if (!is.null(lConfig$project[[strField]])) {
      lExpected[[length(lExpected) + 1L]] <- list(
        scope = "project",
        action = if (identical(strField, "LoadData")) "load" else "save",
        provider = hook_provider_label(lConfig$project, strField)
      )
    }
  }

  lExpected
}
