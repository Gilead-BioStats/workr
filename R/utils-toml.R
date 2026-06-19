#' Write an rproject.toml file compatible with rv (https://github.com/A2-ai/rv)
#'
#' Dependencies are pinned by commit SHA, not by tag: the DESCRIPTION version
#' recorded in the manifest does not match the repos' git tags (tags carry a
#' `v` prefix, and `.9000` dev versions have no tag at all), so tag pins can
#' never resolve. The SHA is the same reproducibility anchor manifest.csv
#' records.
#'
#' @param manifest Data frame with columns: org, package, version, repository, sha.
#' @param path Character. Output directory.
#' @param project_name Character. Project name for the toml header. Default: "library"
#' @export
write_rproject_toml <- function(manifest, path, project_name = "library") {
  lines <- c(
    '[project]',
    paste0('name = "', project_name, '"'),
    'r_version = "4.4"',
    '',
    'repositories = [',
    '    {alias = "PPM", url = "https://packagemanager.posit.co/cran/latest"}',
    ']',
    '',
    'dependencies = ['
  )

  dep_lines <- vapply(seq_len(nrow(manifest)), function(i) {
    row <- manifest[i, ]
    sprintf(
      '    { name = "%s", git = "%s", commit = "%s" }',
      row$package,
      paste0(row$repository, ".git"),
      row$sha
    )
  }, character(1))

  # Join with commas
  dep_lines <- paste0(dep_lines, ifelse(seq_along(dep_lines) < length(dep_lines), ",", ""))

  lines <- c(lines, dep_lines, ']', '')

  writeLines(lines, file.path(path, "rproject.toml"))
}
