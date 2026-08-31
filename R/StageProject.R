#' Stage a project directory
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Copies a subset of a workflow catalog into a run directory, optionally
#' applying study-owned overrides on the way.
#'
#' A study that consumes a shared workflow library usually runs a named subset
#' of it, and sometimes needs a local fix to one workflow while the library
#' catches up. Doing that by hand means a staging script in every study;
#' `StageProject()` makes it two configuration keys, and leaves the catalog
#' itself untouched so what ran is always the catalog plus a declared,
#' reviewable list of overrides.
#'
#' @param strPath `character` Path to the workflow catalog: a directory of
#'   phase folders.
#' @param lInclude `list` Named by phase, each a character vector of workflow
#'   file names to stage, e.g. `list(`1_mappings` = c("AE.yaml"))`. `NULL`
#'   stages every workflow in every phase found under `strPath`.
#' @param strRunPath `character` Directory to stage into. Replaced on each
#'   call, so a stale workflow from a previous run cannot execute.
#' @param strOverlayPath `character` Optional directory mirroring the catalog's
#'   phase structure. A file present there replaces the catalog's copy of the
#'   same name. Default `NULL`.
#'
#' @return Invisibly, a named list of the file names staged per phase.
#'
#' @examples
#' \dontrun{
#' StageProject(
#'   strPath = "workflow",
#'   lInclude = list(`1_mappings` = c("AE.yaml", "SUBJ.yaml")),
#'   strRunPath = "data/workflows-run",
#'   strOverlayPath = "workflow-patches"
#' )
#' }
#'
#' @export
StageProject <- function(
  strPath,
  lInclude = NULL,
  strRunPath = file.path("data", "workflows-run"),
  strOverlayPath = NULL
) {
  stop_if(
    !is.character(strPath) || length(strPath) != 1,
    "[ strPath ] must be a single character string."
  )
  stop_if(!dir.exists(strPath), "[ strPath ] is not a directory: {strPath}")

  if (is.null(lInclude)) {
    lInclude <- stats::setNames(
      lapply(
        list.dirs(strPath, full.names = TRUE, recursive = FALSE),
        function(phase_path) basename(list.files(phase_path, pattern = "\\.ya?ml$"))
      ),
      list.dirs(strPath, full.names = FALSE, recursive = FALSE)
    )
  }

  stop_if(
    !is.list(lInclude) || is.null(names(lInclude)) || any(!nzchar(names(lInclude))),
    "[ lInclude ] must be a list named by phase."
  )

  unlink(strRunPath, recursive = TRUE, force = TRUE)
  lStaged <- list()

  for (strPhase in names(lInclude)) {
    strSourcePhase <- file.path(strPath, strPhase)
    strTargetPhase <- file.path(strRunPath, strPhase)
    # A phase may live entirely in the overlay: that is how a study adds a
    # workflow of its own -- a seeding step, a study-specific report -- without
    # editing the shared catalog.
    stop_if(
      !dir.exists(strSourcePhase) &&
        (is.null(strOverlayPath) || !dir.exists(file.path(strOverlayPath, strPhase))),
      "Phase '{strPhase}' is in neither the catalog at {strPath} nor the overlay."
    )
    dir.create(strTargetPhase, recursive = TRUE, showWarnings = FALSE)

    for (strName in as.character(unlist(lInclude[[strPhase]]))) {
      strSourceFile <- file.path(strSourcePhase, strName)

      if (!is.null(strOverlayPath)) {
        strOverlayFile <- file.path(strOverlayPath, strPhase, strName)
        if (file.exists(strOverlayFile)) {
          strSourceFile <- strOverlayFile
        }
      }

      stop_if(
        !file.exists(strSourceFile),
        "Workflow not found in catalog or overlay: {strPhase}/{strName}"
      )
      file.copy(strSourceFile, file.path(strTargetPhase, strName), overwrite = TRUE)
      lStaged[[strPhase]] <- c(lStaged[[strPhase]], strName)
    }
  }

  LogMessage(
    level = "info",
    message = "Staged {sum(lengths(lStaged))} workflow(s) across {length(lStaged)} phase(s) into {strRunPath}",
    cli_detail = "h3"
  )

  invisible(lStaged)
}
