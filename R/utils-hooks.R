#' Register a load provider
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Register a named `LoadData` provider for use by `RunWorkflow()`,
#' `RunWorkflows()`, and `DemoApp_Server()`. Registered providers can be
#' referenced from `lConfig$LoadData` with a single character string.
#'
#' Registered load providers must accept `lWorkflow`, `lConfig`, and `lData`
#' as named formals.
#'
#' @param name `string` Non-empty provider name.
#' @param provider `function` Load hook implementation.
#'
#' @return Invisibly returns `name`.
#'
#' @examples
#' \dontrun{
#' register_load_provider(
#'   "example.load",
#'   function(lWorkflow, lConfig, lData) lData
#' )
#' }
#'
#' @export
register_load_provider <- function(name, provider) {
  register_hook_provider(
    strField = "LoadData",
    strName = name,
    fnProvider = provider
  )
}

#' Register a save provider
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Register a named `SaveData` provider for use by `RunWorkflow()` and
#' `RunWorkflows()`. Registered providers can be referenced from
#' `lConfig$SaveData` with a single character string.
#'
#' Registered save providers must accept `lWorkflow` and `lConfig` as named
#' formals.
#'
#' @param name `string` Non-empty provider name.
#' @param provider `function` Save hook implementation.
#'
#' @return Invisibly returns `name`.
#'
#' @examples
#' \dontrun{
#' register_save_provider(
#'   "example.save",
#'   function(lWorkflow, lConfig) invisible(NULL)
#' )
#' }
#'
#' @export
register_save_provider <- function(name, provider) {
  register_hook_provider(
    strField = "SaveData",
    strName = name,
    fnProvider = provider
  )
}

.workr_hook_registry <- local({
  registry <- new.env(parent = emptyenv())
  registry$load <- new.env(parent = emptyenv())
  registry$save <- new.env(parent = emptyenv())
  registry
})

hook_contract <- function(strField) {
  switch(
    strField,
    LoadData = list(
      kind = "load",
      expected_formals = c("lWorkflow", "lConfig", "lData")
    ),
    SaveData = list(
      kind = "save",
      expected_formals = c("lWorkflow", "lConfig")
    ),
    stop(glue::glue("Unsupported hook field `{strField}`."), call. = FALSE)
  )
}

hook_registry_env <- function(strField) {
  contract <- hook_contract(strField)
  .workr_hook_registry[[contract$kind]]
}

format_hook_formals <- function(fnProvider) {
  formal_names <- names(formals(fnProvider))
  if (length(formal_names) == 0) {
    return("()")
  }

  paste0("(", paste(formal_names, collapse = ", "), ")")
}

format_registered_providers <- function(strField) {
  provider_names <- sort(ls(envir = hook_registry_env(strField), all.names = TRUE))
  if (length(provider_names) == 0) {
    return("<none>")
  }

  paste(provider_names, collapse = ", ")
}

validate_hook_provider <- function(strField, fnProvider, strSource) {
  contract <- hook_contract(strField)

  stop_if(
    !is.function(fnProvider),
    glue::glue("{strSource} must be a function.")
  )

  formal_names <- names(formals(fnProvider))
  if (!all(contract$expected_formals %in% formal_names)) {
    stop(
      glue::glue(
        "{strSource} must accept formals ({paste(contract$expected_formals, collapse = ', ')}).\n  Got: {format_hook_formals(fnProvider)}"
      ),
      call. = FALSE
    )
  }

  fnProvider
}

lookup_registered_provider <- function(strField, strName) {
  contract <- hook_contract(strField)
  registry <- hook_registry_env(strField)

  if (!exists(strName, envir = registry, inherits = FALSE)) {
    stop(
      glue::glue(
        "Unknown {contract$kind} provider \"{strName}\".\n  Registered providers: {format_registered_providers(strField)}"
      ),
      call. = FALSE
    )
  }

  get(strName, envir = registry, inherits = FALSE)
}

resolve_config_hook <- function(lConfig, strField) {
  if (is.null(lConfig) || !(is.list(lConfig) || is.environment(lConfig))) {
    return(NULL)
  }

  if (is.environment(lConfig)) {
    if (!exists(strField, envir = lConfig, inherits = FALSE)) {
      return(NULL)
    }

    hook_value <- get(strField, envir = lConfig, inherits = FALSE)
  } else {
    if (!strField %in% names(lConfig)) {
      return(NULL)
    }

    hook_value <- lConfig[[strField]]
  }

  if (is.null(hook_value)) {
    return(NULL)
  }

  if (is.character(hook_value)) {
    stop_if(
      length(hook_value) != 1 || !nzchar(hook_value),
      paste0(
        "`lConfig$",
        strField,
        "` must be a non-empty single provider name or a function."
      )
    )

    return(lookup_registered_provider(strField, hook_value))
  }

  if (is.function(hook_value)) {
    return(validate_hook_provider(
      strField = strField,
      fnProvider = hook_value,
      strSource = paste0("`lConfig$", strField, "`")
    ))
  }

  stop(
    paste0(
      "`lConfig$",
      strField,
      "` must be a function or a single registered provider name."
    ),
    call. = FALSE
  )
}

register_hook_provider <- function(strField, strName, fnProvider) {
  contract <- hook_contract(strField)

  stop_if(
    !is.character(strName) || length(strName) != 1 || !nzchar(strName),
    "`name` must be a non-empty single character string."
  )

  fnProvider <- validate_hook_provider(
    strField = strField,
    fnProvider = fnProvider,
    strSource = glue::glue("Registered {contract$kind} provider \"{strName}\"")
  )

  assign(strName, fnProvider, envir = hook_registry_env(strField))

  invisible(strName)
}