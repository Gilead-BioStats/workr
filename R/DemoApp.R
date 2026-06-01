#' Launch the workr demo Shiny app
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Initializes and runs an interactive Shiny application
#'   that demonstrates core workr functionality. The app shows workflow
#'   YAML (editable) on the left and the resulting data on the right.
#'
#' @param lWorkflows `list` A named list of workflows as returned by
#'   \code{\link{MakeWorkflowList}}. Defaults to all example workflows
#'   shipped with workr.
#' @param lData `list` Initial named list of data objects available to
#'   workflows. Defaults to \code{list(value = 2, cars = datasets::cars)}.
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
  lData = list(value = 2, cars = datasets::cars),
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
      strPath = "workflow",
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
#' @description
#' `r lifecycle::badge("stable")`
#' Builds the Shiny user interface for the demo application.
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

  workflow_paths <- purrr::map_chr(lWorkflows, function(wf) wf$path %||% "")
  folder_names <- basename(dirname(workflow_paths))
  folder_names[folder_names == "."] <- "(root)"
  folder_choices <- unique(folder_names)

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
      .main-row { flex: 1; display: flex; gap: 0; min-height: 0; overflow: hidden; }
      .panel-resize-handle { width: 5px; cursor: col-resize; background: #e0e0e0; flex-shrink: 0;
                             transition: background 0.2s; }
      .panel-resize-handle:hover, .panel-resize-handle.dragging { background: #337ab7; }
      .yaml-col { flex: 5; display: flex; flex-direction: column; min-height: 0; min-width: 100px; }
            .yaml-editor-list { flex: 1; min-height: 0; overflow-y: auto; border: 1px solid #ddd; border-radius: 4px; padding: 6px; }
            .yaml-workflow-card { border: 1px solid #ddd; border-radius: 4px; margin-bottom: 6px; background: #fff; }
            .yaml-workflow-card summary { cursor: pointer; padding: 8px 10px; font-weight: 600; user-select: none; transition: background 0.3s, color 0.3s; display: flex; justify-content: space-between; align-items: center; }
            .yaml-workflow-card .wf-step-count { font-weight: 400; font-size: 12px; color: #aaa; margin-left: auto; }
            .yaml-workflow-card.wf-complete summary { background: #e6f4ea; color: #1f8a3a; }
            .yaml-workflow-card.wf-complete .wf-step-count { color: #6abf7b; }
            .yaml-workflow-card.wf-complete { border-color: #a8dab5; }
            .yaml-workflow-body { border-top: 1px solid #eee; padding: 8px 10px; max-height: 300px; overflow-y: auto; }
            .yaml-workflow-body pre { margin: 0; font-family: monospace; font-size: 12px; white-space: pre; color: #1a1a1a; }
            .yaml-done { color: #1f8a3a; font-weight: 600; }
            .yaml-workflow-card .wf-edit-btn { font-size: 11px; padding: 2px 8px; margin-left: 8px; }
      .data-keys-col { flex: 1.5; display: flex; flex-direction: column; min-height: 0; min-width: 80px; }
      .detail-col { flex: 3.5; display: flex; flex-direction: column; min-height: 0; min-width: 100px; }
      .data-key { cursor: pointer; padding: 3px 8px; border-bottom: 1px solid #eee; font-size: 13px; }
      .data-key:hover { background: #f0f0f0; }
      .data-key.active { background: #337ab7; color: #fff; }
      .data-key-list { border: 1px solid #ddd; border-radius: 4px; overflow-y: auto; flex: 1; }
      .data-detail { border: 1px solid #ddd; border-radius: 4px; padding: 8px; overflow: auto; flex: 1; }
      .data-detail table { white-space: nowrap; }
      .col-label { font-weight: bold; font-size: 13px; margin-bottom: 2px; flex-shrink: 0; }
      .log-section { flex-shrink: 0; margin-top: 0; }
      .log-resize-handle { height: 5px; cursor: row-resize; background: #e0e0e0; flex-shrink: 0;
                          transition: background 0.2s; }
      .log-resize-handle:hover, .log-resize-handle.dragging { background: #337ab7; }
      .log-toggle { cursor: pointer; padding: 4px 10px; background: #f5f5f5; border: 1px solid #ddd;
                    border-radius: 4px 4px 0 0; font-weight: bold; user-select: none; font-size: 12px; }
      .log-toggle:hover { background: #e8e8e8; }
      .log-panel { border: 1px solid #ddd; border-top: none; border-radius: 0 0 4px 4px;
                   height: 120px; overflow-y: auto; padding: 6px; font-family: monospace;
                   font-size: 11px; background: #1e1e1e; color: #d4d4d4; white-space: pre-wrap; }
      .log-panel #log_output { margin: 0; padding: 0; background: transparent; border: none; color: inherit; }
    ")),
    shiny::tags$script(shiny::HTML("\
      Shiny.addCustomMessageHandler('setButtonDisabled', function(message) {\
        var btn = document.getElementById(message.id);\
        if (!btn) return;\
        btn.disabled = !!message.disabled;\
      });\
      document.addEventListener('DOMContentLoaded', function() {\
        document.querySelectorAll('.panel-resize-handle').forEach(function(handle) {\
          handle.addEventListener('mousedown', function(e) {\
            e.preventDefault();\
            var prev = handle.previousElementSibling;\
            var next = handle.nextElementSibling;\
            if (!prev || !next) return;\
            handle.classList.add('dragging');\
            var startX = e.clientX;\
            var prevW = prev.getBoundingClientRect().width;\
            var nextW = next.getBoundingClientRect().width;\
            function onMove(e2) {\
              var dx = e2.clientX - startX;\
              var newPrev = Math.max(80, prevW + dx);\
              var newNext = Math.max(80, nextW - dx);\
              prev.style.flex = 'none';\
              next.style.flex = 'none';\
              prev.style.width = newPrev + 'px';\
              next.style.width = newNext + 'px';\
            }\
            function onUp() {\
              handle.classList.remove('dragging');\
              document.removeEventListener('mousemove', onMove);\
              document.removeEventListener('mouseup', onUp);\
            }\
            document.addEventListener('mousemove', onMove);\
            document.addEventListener('mouseup', onUp);\
          });\
        });\
        var logHandle = document.querySelector('.log-resize-handle');\
        if (logHandle) {\
          logHandle.addEventListener('mousedown', function(e) {\
            e.preventDefault();\
            var logPanel = document.getElementById('log-panel');\
            var mainRow = document.querySelector('.main-row');\
            if (!logPanel || !mainRow) return;\
            logHandle.classList.add('dragging');\
            var startY = e.clientY;\
            var logH = logPanel.getBoundingClientRect().height;\
            var mainH = mainRow.getBoundingClientRect().height;\
            function onMove(e2) {\
              var dy = startY - e2.clientY;\
              var newLogH = Math.max(40, logH + dy);\
              var newMainH = Math.max(80, mainH - dy);\
              logPanel.style.height = newLogH + 'px';\
              logPanel.style.maxHeight = 'none';\
              mainRow.style.flex = 'none';\
              mainRow.style.height = newMainH + 'px';\
            }\
            function onUp() {\
              logHandle.classList.remove('dragging');\
              document.removeEventListener('mousemove', onMove);\
              document.removeEventListener('mouseup', onUp);\
            }\
            document.addEventListener('mousemove', onMove);\
            document.addEventListener('mouseup', onUp);\
          });\
        }\
      });\
    ")),
    shiny::tags$h2("workr Demo"),
    shiny::tags$div(class = "header-row",
      shiny::tags$div(
        shiny::selectInput("folder_select", NULL, choices = folder_choices, width = "250px")
      ),
      shiny::actionButton("run_all", "Run All"),
      shiny::actionButton("run_step", "Run Step"),
      shiny::actionButton("reset", "Reset"),
      shiny::tags$span(class = "step-status", shiny::textOutput("step_status", inline = TRUE))
    ),
    shiny::tags$div(class = "main-row",
      shiny::tags$div(class = "yaml-col",
        shiny::tags$div(class = "col-label", "lWorkflows"),
        shiny::tags$div(class = "yaml-editor-list", shiny::uiOutput("yaml_editors"))
      ),
      shiny::tags$div(class = "panel-resize-handle"),
      shiny::tags$div(class = "data-keys-col",
        shiny::tags$div(class = "col-label", "lData"),
        shiny::tags$div(class = "data-key-list",
          shiny::uiOutput("data_keys")
        )
      ),
      shiny::tags$div(class = "panel-resize-handle"),
      shiny::tags$div(class = "detail-col",
        shiny::tags$div(class = "col-label", shiny::textOutput("detail_title", inline = TRUE)),
        shiny::tags$div(class = "data-detail",
          shiny::uiOutput("data_detail")
        )
      )
    ),
    shiny::tags$div(class = "log-resize-handle"),
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
#' @description
#' `r lifecycle::badge("stable")`
#' Creates the server logic for the demo Shiny app, including workflow
#' execution and displayed results.
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
      return(lConfig$LoadData(lWorkflow = wf, lConfig = lConfig, lData = list()))
    }
    init_lData
  }

  function(input, output, session) {
    workflow_names <- names(lWorkflows)
    workflow_paths <- purrr::map_chr(lWorkflows, function(wf) wf$path %||% "")
    workflow_folders <- basename(dirname(workflow_paths))
    workflow_folders[workflow_folders == "."] <- "(root)"
    folder_levels <- unique(workflow_folders)
    folder_map <- split(workflow_names, workflow_folders)

    wf_id <- function(wf_name) gsub("[^A-Za-z0-9_]", "_", wf_name)
    wf_edit_btn_id <- function(wf_name) paste0("yaml_edit_", wf_id(wf_name))

    workflow_to_yaml_text <- function(wf) {
      wf_path <- wf$path %||% ""
      if (is.character(wf_path) && length(wf_path) == 1 && nzchar(wf_path) && file.exists(wf_path)) {
        return(paste(readLines(wf_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n"))
      }
      yaml::as.yaml(wf)
    }

    default_yaml_cache <- purrr::map(lWorkflows, workflow_to_yaml_text)

    rv <- shiny::reactiveValues(
      lData = init_lData,
      step_state = stats::setNames(rep(0L, length(workflow_names)), workflow_names),
      selected_key = NULL,
      logs = stats::setNames(rep("", length(folder_levels)), folder_levels),
      current_folder = folder_levels[[1]],
      yaml_cache = default_yaml_cache
    )

    html_resource_aliases <- new.env(parent = emptyenv())
    html_resource_counter <- 0L

    # Track which workflow is being edited in the modal.
    editing_wf_name <- shiny::reactiveVal(NULL)

    # Edit button observers: open a modal for each workflow.
    purrr::walk(workflow_names, function(wf_name) {
      shiny::observeEvent(input[[wf_edit_btn_id(wf_name)]], {
        yaml_text <- rv$yaml_cache[[wf_name]] %||% yaml::as.yaml(lWorkflows[[wf_name]])
        editing_wf_name(wf_name)
        shiny::showModal(shiny::modalDialog(
          title = paste0("Edit: ", wf_name),
          shiny::textAreaInput(
            "modal_yaml_editor",
            label = NULL,
            value = yaml_text,
            width = "100%",
            height = "400px"
          ),
          shiny::tags$style(".modal-body #modal_yaml_editor { font-family: monospace; font-size: 13px; }"),
          footer = shiny::tagList(
            shiny::modalButton("Cancel"),
            shiny::actionButton("modal_yaml_save", "Save & Reset", class = "btn-primary")
          ),
          size = "l",
          easyClose = TRUE
        ))
      }, ignoreInit = TRUE)
    })

    # Modal save: update cache, reset that workflow's folder, close modal.
    shiny::observeEvent(input$modal_yaml_save, {
      new_yaml <- input$modal_yaml_editor
      wf_name <- editing_wf_name()
      if (is.character(new_yaml) && length(new_yaml) == 1 &&
          is.character(wf_name) && length(wf_name) == 1 && nzchar(wf_name)) {
        rv$yaml_cache[[wf_name]] <- new_yaml
        # Reset the folder so the change takes effect (but keep edited yaml)
        initialize_folder_state(rv$current_folder, reset_logs = FALSE, reset_yaml = FALSE)
        append_log(paste0("[INFO] YAML updated for `", wf_name, "`. Workflow reset.\n"))
      }
      editing_wf_name(NULL)
      shiny::removeModal()
    })

    normalize_lData <- function(x) {
      if (!is.list(x) || is.null(names(x))) {
        return(x)
      }
      keep <- !duplicated(names(x), fromLast = TRUE)
      x[keep]
    }

    escape_html <- function(x) {
      x <- gsub("&", "&amp;", x, fixed = TRUE)
      x <- gsub("<", "&lt;", x, fixed = TRUE)
      x <- gsub(">", "&gt;", x, fixed = TRUE)
      x
    }

    is_html_file_path <- function(x) {
      is.character(x) &&
        length(x) == 1 &&
        !is.na(x) &&
        grepl("\\.html?$", x, ignore.case = TRUE) &&
        file.exists(x)
    }

    get_html_resource_src <- function(path) {
      norm_path <- tryCatch(
        normalizePath(path, winslash = "/", mustWork = TRUE),
        error = function(e) NULL
      )
      if (is.null(norm_path)) {
        return(NULL)
      }

      dir_path <- dirname(norm_path)
      if (exists(dir_path, envir = html_resource_aliases, inherits = FALSE)) {
        alias <- get(dir_path, envir = html_resource_aliases, inherits = FALSE)
      } else {
        html_resource_counter <<- html_resource_counter + 1L
        alias <- paste0("workr_html_", html_resource_counter)
        shiny::addResourcePath(alias, dir_path)
        assign(dir_path, alias, envir = html_resource_aliases)
      }

      file_name <- utils::URLencode(basename(norm_path), reserved = TRUE)
      paste0("/", alias, "/", file_name)
    }

    render_yaml_progress <- function(yaml_text, steps_done) {
      lines <- strsplit(yaml_text %||% "", "\n", fixed = TRUE)[[1]]
      if (length(lines) == 0) {
        return(shiny::tags$pre(""))
      }

      step_starts <- grep("^\\s*-\\s+(name|output):", lines, perl = TRUE)
      done_line <- rep(FALSE, length(lines))
      if (length(step_starts) > 0 && steps_done > 0) {
        step_ends <- c(step_starts[-1] - 1L, length(lines))
        done_n <- min(steps_done, length(step_starts))
        for (i in seq_len(done_n)) {
          done_line[step_starts[i]:step_ends[i]] <- TRUE
        }
      }

      html_lines <- vapply(seq_along(lines), function(i) {
        txt <- escape_html(lines[[i]])
        if (done_line[[i]]) {
          paste0('<span class="yaml-done">', txt, "</span>")
        } else {
          txt
        }
      }, character(1))

      shiny::tags$pre(shiny::HTML(paste(html_lines, collapse = "\n")))
    }

    get_folder_workflows <- function(folder_name) {
      folder_map[[folder_name]] %||% character(0)
    }

    get_workflow_from_editor <- function(wf_name) {
      yaml_text <- rv$yaml_cache[[wf_name]] %||% yaml::as.yaml(lWorkflows[[wf_name]])
      lWorkflow <- tryCatch(
        yaml::yaml.load(yaml_text, eval.expr = TRUE),
        error = function(e) NULL
      )
      if (is.null(lWorkflow)) {
        return(NULL)
      }
      if (is.null(lWorkflow$path) && !is.null(lWorkflows[[wf_name]]$path)) {
        lWorkflow$path <- lWorkflows[[wf_name]]$path
      }
      lWorkflow
    }

    initialize_folder_state <- function(folder_name, reset_logs = FALSE, reset_yaml = TRUE) {
      wf_names <- get_folder_workflows(folder_name)
      if (length(wf_names) == 0) {
        rv$lData <- init_lData
        return(invisible(NULL))
      }

      first_wf <- lWorkflows[[wf_names[[1]]]]
      rv$lData <- tryCatch(
        normalize_lData(get_workflow_data(first_wf)),
        error = function(e) {
          append_log(paste0("[ERROR] ", conditionMessage(e), "\n"))
          init_lData
        }
      )

      for (wf_name in wf_names) {
        if (isTRUE(reset_yaml)) {
          rv$yaml_cache[[wf_name]] <- workflow_to_yaml_text(lWorkflows[[wf_name]])
        }
        rv$step_state[[wf_name]] <- 0L
      }

      if (isTRUE(reset_logs)) {
        rv$logs[[folder_name]] <- ""
      }

      rv$selected_key <- NULL
      invisible(NULL)
    }

    # Initialize and react to folder selection.
    shiny::observeEvent(input$folder_select, {
      rv$current_folder <- input$folder_select
      initialize_folder_state(rv$current_folder)
    }, ignoreInit = FALSE)

    # Helper to append to current workflow's log
    append_log <- function(text) {
      folder <- rv$current_folder
      rv$logs[[folder]] <- paste0(rv$logs[[folder]], text)
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

    # Render one collapsible YAML editor per workflow in the selected folder.
    output$yaml_editors <- shiny::renderUI({
      wf_names <- get_folder_workflows(rv$current_folder)
      if (length(wf_names) == 0) {
        return(shiny::tags$em("No workflows found in this folder."))
      }

      # Determine which workflow should be expanded: first incomplete one
      # But only expand if at least one step has been run (collapse all initially)
      any_started <- any(purrr::map_lgl(wf_names, function(wn) (rv$step_state[[wn]] %||% 0L) > 0L))
      active_wf <- NULL
      if (any_started) {
        for (wn in wf_names) {
          lw <- get_workflow_from_editor(wn)
          n_steps <- if (is.null(lw)) 0L else length(lw$steps %||% list())
          if ((rv$step_state[[wn]] %||% 0L) < n_steps) {
            active_wf <- wn
            break
          }
        }
        # If all complete, collapse all
        # active_wf stays NULL
      }

      shiny::tagList(lapply(seq_along(wf_names), function(i) {
        wf_name <- wf_names[[i]]
        yaml_text <- rv$yaml_cache[[wf_name]]
        if (!is.character(yaml_text) || length(yaml_text) != 1) {
          yaml_text <- yaml::as.yaml(lWorkflows[[wf_name]])
        }
        steps_done <- rv$step_state[[wf_name]] %||% 0L
        lw <- get_workflow_from_editor(wf_name)
        n_steps <- if (is.null(lw)) 0L else length(lw$steps %||% list())
        is_complete <- steps_done >= n_steps && n_steps > 0

        card_class <- if (is_complete) "yaml-workflow-card wf-complete" else "yaml-workflow-card"
        is_open <- identical(wf_name, active_wf)

        body <- shiny::tags$div(
          class = "yaml-workflow-body",
          render_yaml_progress(yaml_text, steps_done)
        )

        step_label <- paste0(steps_done, "/", n_steps)
        display_name <- paste0("Workflow ", i, ": ", wf_name)
        summary_content <- shiny::tagList(
          shiny::tags$span(display_name),
          shiny::actionButton(
            wf_edit_btn_id(wf_name), "Edit",
            class = "btn-xs wf-edit-btn",
            onclick = "event.stopPropagation(); event.preventDefault();"
          ),
          shiny::tags$span(class = "wf-step-count", step_label)
        )

        shiny::tags$details(
          class = card_class,
          open = if (is_open) "open" else NULL,
          shiny::tags$summary(summary_content),
          body
        )
      }))
    })

    # Run All: execute all workflows in the selected folder.
    shiny::observeEvent(input$run_all, {
      wf_names <- get_folder_workflows(rv$current_folder)
      if (length(wf_names) == 0) {
        append_log("[ERROR] No workflows available in selected folder.\n")
        return()
      }

      append_log(paste0("--- Run All Folder: ", rv$current_folder, " ---\n"))
      current_data <- rv$lData

      for (wf_name in wf_names) {
        lWorkflow <- get_workflow_from_editor(wf_name)
        if (is.null(lWorkflow)) {
          append_log(paste0("[ERROR] Failed to parse YAML for workflow `", wf_name, "`.\n"))
          break
        }

        append_log(paste0("--- Workflow: ", wf_name, " ---\n"))
        result <- capture_log({
          RunWorkflow(lWorkflow, current_data, lConfig = lConfig, bReturnResult = FALSE)
        })

        if (is.null(result) || is.null(result$lData)) {
          break
        }

        current_data <- normalize_lData(result$lData)
        rv$step_state[[wf_name]] <- length(lWorkflow$steps %||% list())
      }

      rv$lData <- normalize_lData(current_data)
      keys <- names(rv$lData)
      if (length(keys) > 0) rv$selected_key <- keys[[length(keys)]]
    })

    # Run Step: execute next pending step across workflows in selected folder.
    shiny::observeEvent(input$run_step, {
      wf_names <- get_folder_workflows(rv$current_folder)
      if (length(wf_names) == 0) {
        shiny::showNotification("No workflows available in selected folder.", type = "message")
        return()
      }

      picked_wf <- NULL
      picked_workflow <- NULL
      next_step <- NULL

      for (wf_name in wf_names) {
        lWorkflow <- get_workflow_from_editor(wf_name)
        if (is.null(lWorkflow)) {
          next
        }
        n_steps <- length(lWorkflow$steps %||% list())
        wf_done <- rv$step_state[[wf_name]] %||% 0L
        if (wf_done < n_steps) {
          picked_wf <- wf_name
          picked_workflow <- lWorkflow
          next_step <- wf_done + 1L
          break
        }
      }

      if (is.null(picked_wf)) {
        shiny::showNotification("All steps already executed. Reset to run again.", type = "message")
        return()
      }

      step <- picked_workflow$steps[[next_step]]
      append_log(paste0("--- ", picked_wf, " | Run Step ", next_step, ": ", step$name, " ---\n"))
      result <- capture_log({
        RunStep(
          lStep = step,
          lData = rv$lData,
          lMeta = picked_workflow$meta,
          lSpec = picked_workflow$spec
        )
      })
      if (!is.null(result)) {
        rv$lData[[step$output]] <- result
        rv$lData <- normalize_lData(rv$lData)
        rv$selected_key <- step$output
      }
      rv$step_state[[picked_wf]] <- next_step
    })

    # Disable run buttons when all steps are complete; re-enable otherwise.
    shiny::observe({
      wf_names <- get_folder_workflows(rv$current_folder)
      if (length(wf_names) == 0) {
        done <- TRUE
      } else {
        done <- all(purrr::map_lgl(wf_names, function(wf_name) {
          lWorkflow <- get_workflow_from_editor(wf_name)
          if (is.null(lWorkflow)) {
            return(FALSE)
          }
          n_steps <- length(lWorkflow$steps %||% list())
          (rv$step_state[[wf_name]] %||% 0L) >= n_steps
        }))
      }
      session$sendCustomMessage("setButtonDisabled", list(id = "run_all", disabled = done))
      session$sendCustomMessage("setButtonDisabled", list(id = "run_step", disabled = done))
    })

    # Compute workflow/step summary (shared by header and yaml label)
    wf_summary <- shiny::reactive({
      wf_names <- get_folder_workflows(rv$current_folder)
      if (length(wf_names) == 0) return("No workflows")
      totals <- purrr::map_int(wf_names, function(wf_name) {
        lWorkflow <- get_workflow_from_editor(wf_name)
        if (is.null(lWorkflow)) 0L else length(lWorkflow$steps %||% list())
      })
      done <- purrr::map_int(wf_names, function(wf_name) rv$step_state[[wf_name]] %||% 0L)
      wf_complete <- sum(done >= totals & totals > 0L)
      paste0("Workflow ", wf_complete, "/", length(wf_names), ". Step ", sum(done), "/", sum(totals))
    })

    output$step_status <- shiny::renderText({ wf_summary() })

    # Reset: clear log for current workflow, reset data and step counter
    shiny::observeEvent(input$reset, {
      initialize_folder_state(rv$current_folder, reset_logs = TRUE)
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
      } else if (is_html_file_path(obj)) {
        shiny::uiOutput("detail_html")
      } else {
        shiny::verbatimTextOutput("detail_print")
      }
    })

    # HTML renderer for file path values that point to .html files
    output$detail_html <- shiny::renderUI({
      key <- rv$selected_key
      if (is.null(key) || !key %in% names(rv$lData)) return(NULL)
      obj <- rv$lData[[key]]
      if (!is_html_file_path(obj)) return(NULL)
      src <- get_html_resource_src(obj)
      if (is.null(src)) {
        return(shiny::tags$em("Unable to load HTML file."))
      }

      shiny::tags$iframe(
        src = src,
        style = "width: 100%; height: 100%; min-height: 420px; border: 0;"
      )
    })

    # Table renderer for data.frames
    output$detail_table <- shiny::renderTable({
      key <- rv$selected_key
      if (is.null(key) || !key %in% names(rv$lData)) return(NULL)
      obj <- rv$lData[[key]]
      if (!is.data.frame(obj)) return(NULL)

      # renderTable() uses xtable internally, which cannot print list columns.
      has_list_cols <- vapply(obj, is.list, logical(1))
      if (any(has_list_cols)) {
        obj[has_list_cols] <- lapply(obj[has_list_cols], function(col) {
          vapply(col, function(cell) {
            if (is.null(cell)) return("NULL")
            if (length(cell) == 0) return("[]")
            if (is.atomic(cell) && length(cell) == 1) return(as.character(cell))
            paste(capture.output(str(cell, give.attr = FALSE)), collapse = " ")
          }, character(1))
        })
      }

      obj
    })

    # Print renderer for everything else
    output$detail_print <- shiny::renderPrint({
      key <- rv$selected_key
      if (is.null(key) || !key %in% names(rv$lData)) return(invisible())
      obj <- rv$lData[[key]]
      if (is.data.frame(obj)) return(invisible())
      if (is_html_file_path(obj)) return(invisible())
      str(obj)
    })

    # Log output — show current workflow's log
    output$log_output <- shiny::renderText({
      rv$logs[[rv$current_folder]]
    })
  }
}
