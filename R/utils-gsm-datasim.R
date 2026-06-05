normalize_gsm_datasim_scalar <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NULL)
  }

  if (!is.atomic(x) || length(x) != 1) {
    return(NULL)
  }

  value <- x[[1]]
  if (is.character(value) && !nzchar(value)) {
    return(NULL)
  }

  value
}

gsm_datasim_provider_config <- function(lConfig) {
  cfg <- if ("gsm.datasim" %in% names(lConfig)) {
    lConfig[["gsm.datasim"]]
  } else {
    list()
  }
  stop_if(
    !is.list(cfg),
    "`lConfig$gsm.datasim` must be a list when provided."
  )

  cfg
}

gsm_datasim_config_value <- function(cfg, name, default = NULL) {
  if (!is.list(cfg) || !name %in% names(cfg)) {
    return(default)
  }

  cfg[[name]]
}

gsm_datasim_validate_choice <- function(value, field, choices) {
  field_path <- paste0("lConfig$gsm.datasim$", field)

  stop_if(
    is.null(value) ||
      !is.character(value) ||
      length(value) != 1 ||
      !nzchar(value),
    glue::glue("`{field_path}` must be a non-empty single string.")
  )

  stop_if(
    !value %in% choices,
    glue::glue(
      "Unsupported `{field_path}` value \"{value}\". Supported values: {paste(choices, collapse = ', ')}"
    )
  )

  value
}

gsm_datasim_api <- function() {
  stop_if(
    !requireNamespace("gsm.datasim", quietly = TRUE),
    paste(
      "The `gsm.datasim` load provider requires the optional `gsm.datasim` package.",
      "Install it first, for example with `pak::pkg_install(\"Gilead-BioStats/gsm.datasim@dev\")`."
    )
  )

  ns <- loadNamespace("gsm.datasim")

  list(
    create_standard_study_config = get(
      "create_standard_study_config",
      envir = ns
    ),
    generate_study_data = get("generate_study_data", envir = ns),
    quick_longitudinal_study = get("quick_longitudinal_study", envir = ns),
    set_temporal_config = get0(
      "set_temporal_config",
      envir = ns,
      inherits = FALSE
    ),
    create_study_config = get0(
      "create_study_config",
      envir = ns,
      inherits = FALSE
    ),
    add_dataset_config = get0(
      "add_dataset_config",
      envir = ns,
      inherits = FALSE
    )
  )
}

gsm_datasim_is_longitudinal <- function(cfg) {
  snapshot_count <- gsm_datasim_config_value(cfg, "snapshot_count")
  months_duration <- gsm_datasim_config_value(cfg, "months_duration")

  isTRUE(gsm_datasim_config_value(cfg, "longitudinal")) ||
    (!is.null(snapshot_count) && as.integer(snapshot_count) > 1) ||
    (!is.null(months_duration) && as.integer(months_duration) > 1)
}

gsm_datasim_snapshot_data <- function(raw_data, snapshot = "latest") {
  if (is.null(raw_data)) {
    return(list())
  }

  if (!is.list(raw_data) || length(raw_data) == 0) {
    return(raw_data)
  }

  if (
    any(vapply(raw_data, is.data.frame, logical(1))) ||
      any(vapply(raw_data, function(x) !is.list(x), logical(1)))
  ) {
    return(raw_data)
  }

  if (identical(snapshot, "latest")) {
    return(raw_data[[length(raw_data)]])
  }

  if (is.numeric(snapshot) && length(snapshot) == 1) {
    index <- as.integer(snapshot)
    stop_if(
      is.na(index) || index < 1 || index > length(raw_data),
      glue::glue(
        "`lConfig$gsm.datasim$snapshot` must be between 1 and {length(raw_data)}."
      )
    )
    return(raw_data[[index]])
  }

  stop(
    "`lConfig$gsm.datasim$snapshot` must be `\"latest\"` or a 1-based numeric index.",
    call. = FALSE
  )
}

gsm_datasim_add_legacy_aliases <- function(lData) {
  if (!is.list(lData)) {
    return(lData)
  }

  aliases <- list()
  for (name in names(lData)) {
    if (!startsWith(name, "Raw_")) {
      next
    }

    alias <- paste0("df", sub("^Raw_", "", name))
    if (!alias %in% names(lData) && !alias %in% names(aliases)) {
      aliases[[alias]] <- lData[[name]]
    }
  }

  c(lData, aliases)
}

gsm_datasim_standard_config <- function(api, cfg, default_study_id) {
  config <- api$create_standard_study_config(
    study_id = normalize_gsm_datasim_scalar(gsm_datasim_config_value(
      cfg,
      "study_id"
    )) %||%
      default_study_id,
    participant_count = as.integer(gsm_datasim_config_value(
      cfg,
      "participants",
      100
    )),
    site_count = as.integer(gsm_datasim_config_value(cfg, "sites", 10)),
    analytics_package = gsm_datasim_config_value(cfg, "analytics_package"),
    analytics_workflows = gsm_datasim_config_value(cfg, "analytics_workflows"),
    study = gsm_datasim_config_value(cfg, "study", TRUE),
    subjects = gsm_datasim_config_value(cfg, "subjects", TRUE),
    sites_data = gsm_datasim_config_value(cfg, "sites_data", TRUE),
    adverse_events = gsm_datasim_config_value(cfg, "adverse_events", TRUE),
    protocol_deviations = gsm_datasim_config_value(
      cfg,
      "protocol_deviations",
      TRUE
    ),
    lab_data = gsm_datasim_config_value(cfg, "lab_data", TRUE),
    subject_visits = gsm_datasim_config_value(cfg, "subject_visits", TRUE),
    visit_schedule = gsm_datasim_config_value(cfg, "visit_schedule", TRUE),
    enrollment = gsm_datasim_config_value(cfg, "enrollment", TRUE),
    data_changes = gsm_datasim_config_value(cfg, "data_changes", TRUE),
    data_entry = gsm_datasim_config_value(cfg, "data_entry", TRUE),
    queries = gsm_datasim_config_value(cfg, "queries", TRUE),
    pharmacokinetics = gsm_datasim_config_value(cfg, "pharmacokinetics", TRUE),
    study_drug_completion = gsm_datasim_config_value(
      cfg,
      "study_drug_completion",
      TRUE
    ),
    study_completion = gsm_datasim_config_value(cfg, "study_completion", TRUE),
    inclusion_exclusion = gsm_datasim_config_value(
      cfg,
      "inclusion_exclusion",
      TRUE
    ),
    exclusions = gsm_datasim_config_value(cfg, "exclusions", TRUE),
    country = gsm_datasim_config_value(cfg, "country", TRUE),
    death = gsm_datasim_config_value(cfg, "death", TRUE),
    randomization = gsm_datasim_config_value(cfg, "randomization", TRUE),
    overall_response = gsm_datasim_config_value(cfg, "overall_response", TRUE),
    outlier_intensity = gsm_datasim_config_value(cfg, "outlier_intensity", 1)
  )

  if (is.function(api$set_temporal_config)) {
    config <- api$set_temporal_config(
      config = config,
      start_date = gsm_datasim_config_value(cfg, "start_date"),
      snapshot_count = as.integer(gsm_datasim_config_value(
        cfg,
        "snapshot_count",
        1
      )),
      snapshot_width = gsm_datasim_config_value(cfg, "snapshot_width", "months")
    )
  }

  config
}

#' Built-in gsm.datasim load provider
#'
#' `r lifecycle::badge("experimental")`
#'
#' The built-in `"gsm.datasim"` `LoadData` provider generates workflow inputs
#' with the optional {gsm.datasim} package. Configure it by setting
#' `lConfig$LoadData = "gsm.datasim"` and passing provider options in
#' `lConfig$gsm.datasim`.
#'
#' Supported adapter fields include `profile`, `study_type`, `participants`,
#' `sites`, `snapshot_count`, `months_duration`, `snapshot`, and `config`.
#' The returned objects keep `Raw_*` names and also add `df*` aliases for
#' compatibility with existing workflows.
#'
#' @return A list of generated workflow input objects to merge into `lData`.
#' @name gsm_datasim_provider
NULL

gsm_datasim_simulated_data <- function(lWorkflow, lConfig) {
  cfg <- gsm_datasim_provider_config(lConfig)
  profile <- gsm_datasim_validate_choice(
    gsm_datasim_config_value(cfg, "profile", "standard"),
    "profile",
    c("standard", "custom")
  )
  study_type <- gsm_datasim_validate_choice(
    gsm_datasim_config_value(cfg, "study_type", "standard"),
    "study_type",
    c("standard", "endpoints")
  )

  default_study_id <- lWorkflow$meta$ID %||% lWorkflow$uid %||% "STUDY001"
  default_study_name <- lWorkflow$meta$ID %||% lWorkflow$uid %||% "STUDY001"

  if (identical(profile, "custom")) {
    stop_if(
      !is.list(gsm_datasim_config_value(cfg, "config")),
      "`lConfig$gsm.datasim$config` must be a study configuration list when `profile = \"custom\"`."
    )
  }

  api <- gsm_datasim_api()

  if (gsm_datasim_is_longitudinal(cfg)) {
    study <- api$quick_longitudinal_study(
      study_name = normalize_gsm_datasim_scalar(gsm_datasim_config_value(
        cfg,
        "study_name"
      )) %||%
        default_study_name,
      participants = as.integer(gsm_datasim_config_value(
        cfg,
        "participants",
        1000
      )),
      sites = as.integer(gsm_datasim_config_value(cfg, "sites", 150)),
      months_duration = as.integer(
        gsm_datasim_config_value(
          cfg,
          "months_duration",
          gsm_datasim_config_value(cfg, "snapshot_count", 12)
        )
      ),
      study_type = study_type,
      include_pipeline = isTRUE(gsm_datasim_config_value(
        cfg,
        "include_pipeline"
      )),
      outlier_intensity = gsm_datasim_config_value(cfg, "outlier_intensity", 1),
      verbose = isTRUE(gsm_datasim_config_value(cfg, "verbose"))
    )

    return(gsm_datasim_snapshot_data(
      raw_data = study$raw_data %||% list(),
      snapshot = gsm_datasim_config_value(cfg, "snapshot", "latest")
    ))
  }

  if (identical(profile, "custom")) {
    return(gsm_datasim_snapshot_data(
      raw_data = api$generate_study_data(
        config = gsm_datasim_config_value(cfg, "config"),
        workflow_path = gsm_datasim_config_value(
          cfg,
          "workflow_path",
          "workflow/1_mappings"
        ),
        mappings = gsm_datasim_config_value(cfg, "mappings"),
        package = gsm_datasim_config_value(cfg, "package", "gsm.mapping"),
        verbose = isTRUE(gsm_datasim_config_value(cfg, "verbose"))
      ),
      snapshot = gsm_datasim_config_value(cfg, "snapshot", "latest")
    ))
  }

  stop_if(
    !identical(study_type, "standard"),
    paste(
      "Single-snapshot `gsm.datasim` loading with `profile = \"standard\"` only supports `study_type = \"standard\"`.",
      "Use `profile = \"custom\"` with a prebuilt config, or set a longitudinal configuration instead."
    )
  )

  gsm_datasim_snapshot_data(
    raw_data = api$generate_study_data(
      config = gsm_datasim_standard_config(api, cfg, default_study_id),
      workflow_path = gsm_datasim_config_value(
        cfg,
        "workflow_path",
        "workflow/1_mappings"
      ),
      mappings = gsm_datasim_config_value(cfg, "mappings"),
      package = gsm_datasim_config_value(cfg, "package", "gsm.mapping"),
      verbose = isTRUE(gsm_datasim_config_value(cfg, "verbose"))
    ),
    snapshot = gsm_datasim_config_value(cfg, "snapshot", "latest")
  )
}

gsm_datasim_load_provider <- function(lWorkflow, lConfig, lData) {
  if (is.null(lData)) {
    lData <- list()
  }

  stop_if(!is.list(lData), "`lData` must be a list.")

  generated <- gsm_datasim_simulated_data(
    lWorkflow = lWorkflow,
    lConfig = lConfig
  )

  stop_if(
    !is.list(generated),
    "The `gsm.datasim` provider must resolve to a list of workflow input objects."
  )

  utils::modifyList(gsm_datasim_add_legacy_aliases(generated), lData)
}

workr_register_builtin_providers <- function() {
  register_load_provider("gsm.datasim", gsm_datasim_load_provider)
  invisible(TRUE)
}

.onLoad <- function(libname, pkgname) {
  workr_register_builtin_providers()
  invisible(NULL)
}
