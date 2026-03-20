#' Launch the workr demo Shiny app
#'
#' @description Initializes and runs an interactive Shiny application
#'   that demonstrates core workr functionality. The app shows workflow
#'   YAML (editable) on the left and the resulting data on the right.
#'
#' @param lWorkflows `list` A named list of workflows as returned by
#'   \code{\link{MakeWorkflowList}}. Defaults to all example workflows
#'   shipped with workr.
#' @param lData `list` Initial named list of data objects available to
#'   workflows. Defaults to an empty list.
#' @param lConfig `list` Optional configuration hooks passed to workflow runners.
#'   Defaults to using \code{loadExample()} for \code{LoadData}.
#'
#' @return A \code{shiny.appobj} (called for its side effect of launching the app).
#'
#' @examples
#' \dontrun{
#' DemoApp_init()
#' }
#'
#' @export
DemoApp_init <- function(
  lWorkflows = NULL,
  lData = list(),
  lConfig = NULL
) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required. Install it with install.packages('shiny').")
  }
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required. Install it with install.packages('yaml').")
  }
  if (is.null(lWorkflows)) {
    lWorkflows <- MakeWorkflowList(
      strPath = "workflows",
      strPackage = "workr"
    )
  }

  if (is.null(lConfig)) {
    lConfig <- list(LoadData = loadExample)
  }

  # Register helper functions used by example workflows
  sum_step <- function(lData, y) lData$value + y
  environment(sum_step) <- globalenv()
  assign("sum_step", sum_step, envir = globalenv())

  shiny::shinyApp(
    ui = DemoApp_UI(lWorkflows),
    server = DemoApp_Server(lWorkflows, lData, lConfig)
  )
}

#' Demo app UI
#'
#' @param lWorkflows `list` Named list of workflows.
#'
#' @return A Shiny UI definition.
#'
#' @export
DemoApp_UI <- function(lWorkflows) {
  workflow_names <- names(lWorkflows)
  if (is.null(workflow_names)) {
    workflow_names <- paste0("workflow_", seq_along(lWorkflows))
  }

  shiny::fluidPage(
    shiny::tags$style(shiny::HTML("
      html, body { height: 100%; margin: 0; overflow: hidden; }
      .container-fluid { display: flex; flex-direction: column; height: 100vh; padding: 8px 15px; }
      h2 { margin: 0 0 4px 0; font-size: 20px; }
      .header-row { flex-shrink: 0; display: flex; align-items: center; gap: 12px; margin-bottom: 6px;
                    padding: 4px 0; border-bottom: 1px solid #ddd; }
      .header-row .form-group { margin-bottom: 0; }
      .header-row select { height: 30px; padding: 2px 8px; }
      .header-row .btn { padding: 4px 12px; }
      .header-row .step-status { color: #888; font-size: 13px; margin-left: auto; }
      .main-row { flex: 1; display: flex; gap: 8px; min-height: 0; overflow: hidden; }
      .yaml-col { flex: 5; display: flex; flex-direction: column; min-height: 0; }
      .yaml-col textarea { flex: 1; resize: none !important; font-family: monospace; font-size: 12px; }
      .yaml-col .form-group { flex: 1; display: flex; flex-direction: column; margin: 0; }
      .data-keys-col { flex: 1.5; display: flex; flex-direction: column; min-height: 0; }
      .detail-col { flex: 3.5; display: flex; flex-direction: column; min-height: 0; }
      .data-key { cursor: pointer; padding: 3px 8px; border-bottom: 1px solid #eee; font-size: 13px; }
      .data-key:hover { background: #f0f0f0; }
      .data-key.active { background: #337ab7; color: #fff; }
      .data-key-list { border: 1px solid #ddd; border-radius: 4px; overflow-y: auto; flex: 1; }
      .data-detail { border: 1px solid #ddd; border-radius: 4px; padding: 8px; overflow: auto; flex: 1; }
      .col-label { font-weight: bold; font-size: 13px; margin-bottom: 2px; flex-shrink: 0; }
      .log-section { flex-shrink: 0; margin-top: 4px; }
      .log-toggle { cursor: pointer; padding: 4px 10px; background: #f5f5f5; border: 1px solid #ddd;
                    border-radius: 4px 4px 0 0; font-weight: bold; user-select: none; font-size: 12px; }
      .log-toggle:hover { background: #e8e8e8; }
      .log-panel { border: 1px solid #ddd; border-top: none; border-radius: 0 0 4px 4px;
                   max-height: 120px; overflow-y: auto; padding: 6px; font-family: monospace;
                   font-size: 11px; background: #1e1e1e; color: #d4d4d4; white-space: pre-wrap; }
      .log-panel #log_output { margin: 0; padding: 0; background: transparent; border: none; color: inherit; }
    ")),
    shiny::tags$h2("workr Demo"),
    shiny::tags$div(class = "header-row",
      shiny::tags$div(
        shiny::selectInput("workflow_select", NULL, choices = workflow_names, width = "250px")
      ),
      shiny::actionButton("run_all", "Run All"),
      shiny::actionButton("run_step", "Run Step"),
      shiny::actionButton("reset", "Reset"),
      shiny::tags$span(class = "step-status", shiny::textOutput("step_status", inline = TRUE))
    ),
    shiny::tags$div(class = "main-row",
      shiny::tags$div(class = "yaml-col",
        shiny::tags$div(class = "col-label", "Workflow YAML"),
        shiny::textAreaInput("yaml_editor", label = NULL, value = "", width = "100%")
      ),
      shiny::tags$div(class = "data-keys-col",
        shiny::tags$div(class = "col-label", "lData"),
        shiny::tags$div(class = "data-key-list",
          shiny::uiOutput("data_keys")
        )
      ),
      shiny::tags$div(class = "detail-col",
        shiny::tags$div(class = "col-label", shiny::textOutput("detail_title", inline = TRUE)),
        shiny::tags$div(class = "data-detail",
          shiny::uiOutput("data_detail")
        )
      )
    ),
    shiny::tags$div(class = "log-section",
      shiny::tags$div(
        class = "log-toggle",
        onclick = "var p = document.getElementById('log-panel'); p.style.display = p.style.display === 'none' ? 'block' : 'none';",
        shiny::icon("terminal"), " Log"
      ),
      shiny::tags$div(
        id = "log-panel",
        class = "log-panel",
        style = "display: block;",
        shiny::verbatimTextOutput("log_output")
      )
    )
  )
}

#' Demo app server
#'
#' @param lWorkflows `list` Named list of workflows.
#' @param lData `list` Initial data list.
#' @param lConfig `list` Optional configuration hooks passed to workflow runners.
#'
#' @return A Shiny server function.
#'
#' @export
DemoApp_Server <- function(lWorkflows, lData, lConfig = NULL) {
  init_lData <- lData
  if (is.null(init_lData)) {
    init_lData <- list()
  }

  get_workflow_data <- function(wf) {
    if (
      !is.null(lConfig) &&
      exists("LoadData", lConfig) &&
      is.function(lConfig$LoadData) &&
      all(c("lWorkflow", "lConfig", "lData") %in% names(formals(lConfig$LoadData)))
    ) {
      return(lConfig$LoadData(lWorkflow = wf, lConfig = lConfig, lData = init_lData))
    }
    init_lData
  }

  function(input, output, session) {
    rv <- shiny::reactiveValues(
      lData = init_lData,
      step_index = 0L,
      selected_key = NULL,
      logs = stats::setNames(rep("", length(lWorkflows)), names(lWorkflows)),
      current_wf = names(lWorkflows)[1]
    )

    # Update YAML editor when workflow selection changes and reset data
    shiny::observeEvent(input$workflow_select, {
      wf <- lWorkflows[[input$workflow_select]]
      yaml_text <- yaml::as.yaml(wf)
      shiny::updateTextAreaInput(session, "yaml_editor", value = yaml_text)
      rv$lData <- tryCatch(
        get_workflow_data(wf),
        error = function(e) {
          append_log(paste0("[ERROR] ", conditionMessage(e), "\n"))
          init_lData
        }
      )
      rv$step_index <- 0L
      rv$current_wf <- input$workflow_select
    })

    # Helper to append to current workflow's log
    append_log <- function(text) {
      wf <- rv$current_wf
      rv$logs[[wf]] <- paste0(rv$logs[[wf]], text)
    }

    # Helper to capture log messages and errors from workr functions
    capture_log <- function(expr) {
      msgs <- character(0)
      result <- tryCatch(
        withCallingHandlers(
          expr,
          message = function(m) {
            msgs <<- c(msgs, conditionMessage(m))
            invokeRestart("muffleMessage")
          }
        ),
        error = function(e) {
          msgs <<- c(msgs, paste0("[ERROR] ", conditionMessage(e), "\n"))
          NULL
        }
      )
      if (length(msgs) > 0) {
        append_log(paste(msgs, collapse = ""))
      }
      result
    }

    # Run All: execute the full workflow
    shiny::observeEvent(input$run_all, {
      yaml_text <- input$yaml_editor
      lWorkflow <- tryCatch(yaml::yaml.load(yaml_text), error = function(e) NULL)
      if (is.null(lWorkflow)) {
        append_log("[ERROR] Failed to parse YAML\n")
        return()
      }
      append_log(paste0("--- Run All: ", lWorkflow$meta$Type, "_", lWorkflow$meta$ID, " ---\n"))
      result <- capture_log({
        if (is.null(lWorkflow$path) && !is.null(lWorkflows[[rv$current_wf]]$path)) {
          lWorkflow$path <- lWorkflows[[rv$current_wf]]$path
        }
        RunWorkflow(lWorkflow, rv$lData, lConfig = lConfig, bReturnResult = FALSE)
      })
      if (!is.null(result) && !is.null(result$lData)) {
        rv$lData <- result$lData
        rv$step_index <- length(lWorkflow$steps)
      }
    })

    # Run Step: execute one step at a time
    shiny::observeEvent(input$run_step, {
      yaml_text <- input$yaml_editor
      lWorkflow <- yaml::yaml.load(yaml_text)
      n_steps <- length(lWorkflow$steps)
      next_step <- rv$step_index + 1L

      if (next_step > n_steps) {
        shiny::showNotification("All steps already executed. Select a new workflow or edit YAML.", type = "message")
        return()
      }

      step <- lWorkflow$steps[[next_step]]
      append_log(paste0("--- Run Step ", next_step, ": ", step$name, " ---\n"))
      result <- capture_log({
        RunStep(
          lStep = step,
          lData = rv$lData,
          lMeta = lWorkflow$meta,
          lSpec = lWorkflow$spec
        )
      })
      if (!is.null(result)) {
        rv$lData[[step$output]] <- result
      }
      rv$step_index <- next_step
    })

    # Step status display
    output$step_status <- shiny::renderText({
      yaml_text <- input$yaml_editor
      lWorkflow <- tryCatch(yaml::yaml.load(yaml_text), error = function(e) NULL)
      n_steps <- if (!is.null(lWorkflow)) length(lWorkflow$steps) else 0
      paste0("Step ", rv$step_index, " of ", n_steps)
    })

    # Reset: clear log for current workflow, reset data and step counter
    shiny::observeEvent(input$reset, {
      wf <- lWorkflows[[input$workflow_select]]
      yaml_text <- yaml::as.yaml(wf)
      shiny::updateTextAreaInput(session, "yaml_editor", value = yaml_text)
      rv$lData <- tryCatch(
        get_workflow_data(wf),
        error = function(e) {
          append_log(paste0("[ERROR] ", conditionMessage(e), "\n"))
          init_lData
        }
      )
      rv$step_index <- 0L
      rv$selected_key <- NULL
      rv$logs[[rv$current_wf]] <- ""
    })

    # Track selected data key
    shiny::observeEvent(input$selected_key, {
      rv$selected_key <- input$selected_key
    })

    # Render clickable list of lData keys
    output$data_keys <- shiny::renderUI({
      keys <- names(rv$lData)
      if (is.null(keys) || length(keys) == 0) {
        return(shiny::tags$div(class = "data-key", "(empty)"))
      }
      active <- rv$selected_key
      lapply(keys, function(k) {
        cls <- if (identical(k, active)) "data-key active" else "data-key"
        icon <- if (is.data.frame(rv$lData[[k]])) {
          shiny::icon("table")
        } else if (is.numeric(rv$lData[[k]]) || is.character(rv$lData[[k]])) {
          shiny::icon("font")
        } else {
          shiny::icon("cube")
        }
        shiny::tags$div(
          class = cls,
          onclick = sprintf("Shiny.setInputValue('selected_key', '%s', {priority: 'event'})", k),
          icon, " ", k
        )
      })
    })

    # Render detail title
    output$detail_title <- shiny::renderText({
      key <- rv$selected_key
      if (is.null(key) || !key %in% names(rv$lData)) return("Select an item")
      obj <- rv$lData[[key]]
      if (is.data.frame(obj)) {
        paste0(key, " (", nrow(obj), " x ", ncol(obj), " data.frame)")
      } else {
        paste0(key, " (", class(obj)[1], ")")
      }
    })

    # Render detail panel with appropriate widget
    output$data_detail <- shiny::renderUI({
      key <- rv$selected_key
      if (is.null(key) || !key %in% names(rv$lData)) {
        return(shiny::tags$em("Click an item on the left to inspect it."))
      }
      obj <- rv$lData[[key]]
      if (is.data.frame(obj)) {
        shiny::tableOutput("detail_table")
      } else {
        shiny::verbatimTextOutput("detail_print")
      }
    })

    # Table renderer for data.frames
    output$detail_table <- shiny::renderTable({
      key <- rv$selected_key
      if (is.null(key) || !key %in% names(rv$lData)) return(NULL)
      obj <- rv$lData[[key]]
      if (is.data.frame(obj)) obj else NULL
    })

    # Print renderer for everything else
    output$detail_print <- shiny::renderPrint({
      key <- rv$selected_key
      if (is.null(key) || !key %in% names(rv$lData)) return(invisible())
      obj <- rv$lData[[key]]
      if (is.data.frame(obj)) return(invisible())
      str(obj)
    })

    # Log output — show current workflow's log
    output$log_output <- shiny::renderText({
      rv$logs[[rv$current_wf]]
    })
  }
}
