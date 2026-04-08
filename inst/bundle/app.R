if (!requireNamespace("pkgload", quietly = TRUE)) {
  stop("Package 'pkgload' is required to run this app from source.")
}

if (!requireNamespace("shiny", quietly = TRUE)) {
  stop("Package 'shiny' is required to run this app.")
}

if (!requireNamespace("yaml", quietly = TRUE)) {
  stop("Package 'yaml' is required to run this app.")
}

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
      stop("Could not find the workr package root from the current working directory.")
    }

    current <- parent
  }
}

pkg_root <- find_package_root()

pkgload::load_all(
  path = pkg_root,
  export_all = FALSE,
  helpers = FALSE,
  attach_testthat = FALSE,
  quiet = TRUE
)

# Hosted app loads only lightweight workflows (01, 02) to stay within
# shinyapps.io memory limits. Run DemoApp_init() locally for all examples.
wf_root <- file.path(pkg_root, "inst", "workflows")
lWorkflows <- c(
  workr::MakeWorkflowList(strPath = file.path(wf_root, "01_RunWorkflow")),
  workr::MakeWorkflowList(strPath = file.path(wf_root, "02_RunWorkflows"))
)

workr::DemoApp_init(lWorkflows = lWorkflows)