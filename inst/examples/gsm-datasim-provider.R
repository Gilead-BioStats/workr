find_package_root <- function(path = getwd()) {
  current <- normalizePath(path, winslash = "/", mustWork = TRUE)

  repeat {
    if (
      file.exists(file.path(current, "DESCRIPTION")) &&
        dir.exists(file.path(current, "R"))
    ) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      return(NULL)
    }

    current <- parent
  }
}

pkg_root <- find_package_root()

if (!is.null(pkg_root) && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(
    path = pkg_root,
    export_all = FALSE,
    helpers = FALSE,
    attach_testthat = FALSE,
    quiet = TRUE
  )
} else if (!requireNamespace("workr", quietly = TRUE)) {
  stop(
    "Install {workr}, or run this script from the package root with {pkgload} installed.",
    call. = FALSE
  )
}

if (!requireNamespace("gsm.datasim", quietly = TRUE)) {
  stop(
    paste(
      "This example requires the optional {gsm.datasim} package.",
      "Install it first, for example with pak::pkg_install(\"Gilead-BioStats/gsm.datasim@dev\")."
    ),
    call. = FALSE
  )
}

identity_step <- function(x) x

example_workflow <- function(id) {
  list(
    meta = list(Type = "example", ID = id),
    steps = list(
      list(
        name = "identity_step",
        output = "res",
        params = list(x = "loaded_val")
      )
    )
  )
}

run_example <- function(title, workflow_id, gsm_config, lData = list()) {
  cat("\n", title, "\n", strrep("=", nchar(title)), "\n", sep = "")

  result <- tryCatch(
    workr::RunWorkflow(
      lWorkflow = example_workflow(workflow_id),
      lData = lData,
      lConfig = list(LoadData = "gsm.datasim", gsm.datasim = gsm_config),
      bReturnResult = FALSE
    ),
    error = function(err) err
  )

  if (inherits(result, "error")) {
    cat("Run failed:\n", conditionMessage(result), "\n", sep = "")
    return(invisible(NULL))
  }

  loaded <- result$lData
  cat("Loaded objects:\n")
  print(sort(names(loaded)))

  if ("Raw_SUBJ" %in% names(loaded)) {
    cat("\nRaw_SUBJ preview:\n")
    print(utils::head(loaded$Raw_SUBJ))
  }

  if ("dfSUBJ" %in% names(loaded)) {
    cat("\ndfSUBJ aliases Raw_SUBJ:\n")
    print(identical(loaded$Raw_SUBJ, loaded$dfSUBJ))
  }

  if ("loaded_val" %in% names(loaded)) {
    cat("\nloaded_val:\n")
    print(loaded$loaded_val)
  }

  invisible(result)
}

cat("gsm.datasim version:\n")
print(utils::packageVersion("gsm.datasim"))

run_example(
  title = "Standard single-snapshot run",
  workflow_id = "single_snapshot",
  gsm_config = list(
    profile = "standard",
    study_type = "standard",
    participants = 25,
    sites = 4,
    snapshot_count = 1
  ),
  lData = list(caller_value = 11)
)

run_example(
  title = "Longitudinal latest-snapshot run",
  workflow_id = "longitudinal_case",
  gsm_config = list(
    study_type = "endpoints",
    months_duration = 2,
    participants = 10,
    sites = 3
  )
)
