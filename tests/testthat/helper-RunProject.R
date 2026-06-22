write_project_workflow <- function(
  project_path,
  phase,
  id,
  step_name = "base::identity",
  output = "out",
  params = list(x = id)
) {
  phase_path <- file.path(project_path, phase)
  dir.create(phase_path, recursive = TRUE, showWarnings = FALSE)

  workflow <- list(
    meta = list(Type = "phase", ID = id),
    steps = list(
      list(name = step_name, output = output, params = params)
    )
  )

  yaml::write_yaml(workflow, file.path(phase_path, paste0(id, ".yaml")))
}

write_phase_config <- function(project_path, phase, lines) {
  writeLines(lines, file.path(project_path, phase, "_config.yaml"))
}
