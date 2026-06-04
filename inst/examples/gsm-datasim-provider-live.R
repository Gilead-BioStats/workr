find_package_root <- function(path = getwd()) {
  current <- normalizePath(path, winslash = "/", mustWork = TRUE)

  repeat {
    has_description <- file.exists(file.path(current, "DESCRIPTION"))
    has_r_dir <- dir.exists(file.path(current, "R"))

    if (has_description && has_r_dir) {
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

identity_step <- function(x) {
  x
}

make_gsm_datasim_workflow <- function(id) {
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

show_header <- function(title) {
  rule <- paste(rep("=", nchar(title)), collapse = "")
  cat("\n", rule, "\n", title, "\n", rule, "\n", sep = "")
}

show_loaded_summary <- function(lData) {
  cat("Loaded objects:\n")
  print(sort(names(lData)))

  if ("Raw_SUBJ" %in% names(lData)) {
    cat("\nRaw_SUBJ preview:\n")
    print(utils::head(lData$Raw_SUBJ))
  }

  if ("dfSUBJ" %in% names(lData)) {
    cat("\ndfSUBJ is the compatibility alias for Raw_SUBJ:\n")
    print(identical(lData$Raw_SUBJ, lData$dfSUBJ))
  }

  if ("loaded_val" %in% names(lData)) {
    cat("\nloaded_val:\n")
    print(lData$loaded_val)
  }
}

run_and_report <- function(title, code) {
  show_header(title)

  result <- tryCatch(
    force(code),
    error = function(err) err
  )

  if (inherits(result, "error")) {
    cat("Run failed with:\n")
    message_text <- conditionMessage(result)
    cat(message_text, "\n", sep = "")

    if (grepl("invalid argument type", message_text, fixed = TRUE)) {
      cat(
        "\nThis usually means the installed {gsm.datasim} version does not match the runtime\n",
        "API shape expected by this checkout of {workr}. Update the optional dependency\n",
        "before retrying, or compare this script against R/utils-gsm-datasim.R.\n",
        sep = ""
      )
    }

    return(invisible(NULL))
  }

  show_loaded_summary(result$lData)
  invisible(result)
}

cat("gsm.datasim version:\n")
print(utils::packageVersion("gsm.datasim"))

run_and_report(
  title = "Live standard profile run",
  code = workr::RunWorkflow(
    lWorkflow = make_gsm_datasim_workflow("single_snapshot"),
    lData = list(caller_value = 11),
    lConfig = list(
      LoadData = "gsm.datasim",
      gsm.datasim = list(
        profile = "standard",
        study_type = "standard",
        participants = 25,
        sites = 4,
        snapshot_count = 1
      )
    ),
    bReturnResult = FALSE
  )
)

run_and_report(
  title = "Live longitudinal latest-snapshot run",
  code = workr::RunWorkflow(
    lWorkflow = make_gsm_datasim_workflow("longitudinal_case"),
    lConfig = list(
      LoadData = "gsm.datasim",
      gsm.datasim = list(
        study_type = "endpoints",
        months_duration = 2,
        participants = 10,
        sites = 3
      )
    ),
    bReturnResult = FALSE
  )
)
