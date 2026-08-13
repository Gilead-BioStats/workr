# Test helper: silence expected log levels via the `appender()` seam.
#
# `LogMessage()` routes all output through `appender()`, so mocking that one
# binding suppresses log chatter without `suppressMessages()` wrappers -- which
# would also swallow genuine `message()` conditions a test means to assert on.

#' Silence log output for the given levels within the calling test
#'
#' Levels not listed still reach the console, so an unexpected `warn` or `fatal`
#' record stays visible rather than being hidden by a blanket suppression.
#'
#' @param levels Character vector of log levels to discard.
#' @param .env Environment whose exit triggers the unmock; defaults to the caller.
#'
#' @keywords internal
#' @noRd
local_quiet_log <- function(levels = "info", .env = parent.frame()) {
  levels <- tolower(levels)

  testthat::local_mocked_bindings(
    appender = function(level, msg) {
      if (tolower(level) %in% levels) {
        return(invisible(NULL))
      }
      message("[", toupper(level), "] ", msg)
    },
    .package = "workr",
    .env = .env
  )
}
