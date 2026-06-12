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

deploy_demo_app <- function(app_name = "workr-demoapp", account = NULL, server = "shinyapps.io") {
  if (!requireNamespace("rsconnect", quietly = TRUE)) {
    stop("Package 'rsconnect' is required to deploy the app.")
  }

  app_dir <- find_package_root()

  all_files <- list.files(app_dir, recursive = TRUE, all.files = FALSE)
  app_files <- all_files[grepl("^(R/|inst/bundle/|inst/example_workflows/0[12]_|DESCRIPTION$|NAMESPACE$)", all_files)]

  rsconnect::deployApp(
    appDir = app_dir,
    appFiles = app_files,
    appPrimaryDoc = "inst/bundle/app.R",
    appName = app_name,
    account = account,
    server = server
  )
}