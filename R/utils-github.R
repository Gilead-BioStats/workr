#' Parse a GitHub ref string into org, repo, and optional ref
#'
#' @param ref Character. A GitHub ref like "org/repo" or "org/repo@tag_or_sha"
#' @return A list with elements: org, repo, ref (NULL if not specified)
parse_github_ref <- function(ref) {
  if (grepl("@", ref)) {
    parts <- strsplit(ref, "@")[[1]]
    org_repo <- parts[1]
    git_ref <- parts[2]
  } else {
    org_repo <- ref
    git_ref <- NULL
  }

  org_repo_parts <- strsplit(org_repo, "/")[[1]]
  if (length(org_repo_parts) != 2) {
    stop("Invalid GitHub ref: '", ref, "'. Expected format: 'org/repo' or 'org/repo@tag'")
  }

  list(
    org = org_repo_parts[1],
    repo = org_repo_parts[2],
    ref = git_ref
  )
}

#' Resolve a package to its full metadata using the GitHub API via gh CLI
#'
#' @param org Character. GitHub organization.
#' @param repo Character. Repository name.
#' @param ref Character or NULL. Tag, SHA, or branch name.
#' @param date Date or NULL. If ref is NULL, find latest release on or before this date.
#' @return A list with org, repo, version, repository, url, sha, ref.
resolve_package <- function(org, repo, ref = NULL, date = NULL) {
  full_repo <- paste0(org, "/", repo)

  if (is.null(ref)) {
    ref <- resolve_ref_by_date(org, repo, date)
  }

  # Get the commit SHA for this ref
  sha <- gh_get_sha(org, repo, ref)

  # Get the version from DESCRIPTION at this ref
  version <- gh_get_version(org, repo, sha)

  list(
    org = org,
    repo = repo,
    version = version,
    repository = paste0("https://github.com/", full_repo),
    url = paste0("https://github.com/", full_repo, "/archive/", sha, ".tar.gz"),
    sha = sha,
    ref = ref
  )
}

#' Execute a gh api call and return stdout/stderr lines
#' @keywords internal
gh_api <- function(args) {
  system2("gh", args, stdout = TRUE, stderr = TRUE)
}


#' Resolve a ref by date — find the latest release/tag on or before the given date
#'
#' @param org Character. GitHub organization.
#' @param repo Character. Repository name.
#' @param date Date or NULL. If NULL, uses the latest release.
#' @return Character. The resolved tag name or default branch.
resolve_ref_by_date <- function(org, repo, date = NULL) {
  full_repo <- paste0(org, "/", repo)

  if (is.null(date)) {
    # Get latest release tag
    result <- gh_api(
      c("api", paste0("repos/", full_repo, "/releases/latest"), "--jq", ".tag_name")
    )
    if (length(result) > 0 && !grepl("Not Found", result[1])) {
      return(trimws(result[1]))
    }
    # No releases — fall back to default branch
    result <- gh_api(
      c("api", paste0("repos/", full_repo), "--jq", ".default_branch")
    )
    return(trimws(result[1]))
  }

  # Get all release tag names and dates separately
  tags <- gh_api(
    c("api", paste0("repos/", full_repo, "/releases"), "--paginate",
      "--jq", ".[].tag_name")
  )
  dates <- gh_api(
    c("api", paste0("repos/", full_repo, "/releases"), "--paginate",
      "--jq", ".[].published_at")
  )

  if (length(tags) == 0 || all(grepl("Not Found", tags))) {
    return(resolve_tag_by_date(org, repo, date))
  }

  releases <- data.frame(
    tag = trimws(tags),
    date = as.Date(substr(trimws(dates), 1, 10)),
    stringsAsFactors = FALSE
  )

  if (is.null(releases) || nrow(releases) == 0) {
    stop("No releases found for ", full_repo)
  }

  candidates <- releases[releases$date <= date, , drop = FALSE]
  if (nrow(candidates) == 0) {
    stop("No releases found for ", full_repo, " on or before ", date)
  }

  # Return the most recent
  candidates$tag[which.max(candidates$date)]
}

#' Resolve a tag by date when no releases exist
#'
#' @param org Character. GitHub organization.
#' @param repo Character. Repository name.
#' @param date Date. Find latest tag on or before this date.
#' @return Character. The resolved tag name.
resolve_tag_by_date <- function(org, repo, date) {
  full_repo <- paste0(org, "/", repo)

  # Get tags with their commit dates
  result <- gh_api(
    c("api", paste0("repos/", full_repo, "/tags"), "--paginate",
      "--jq", ".[].name")
  )

  if (length(result) == 0) {
    stop("No tags or releases found for ", full_repo)
  }

  # For each tag, get the commit date
  tag_dates <- lapply(result, function(tag) {
    commit_info <- gh_api(
      c("api", paste0("repos/", full_repo, "/git/ref/tags/", tag),
        "--jq", ".object.sha")
    )
    sha <- trimws(commit_info[1])
    commit_date_str <- gh_api(
      c("api", paste0("repos/", full_repo, "/commits/", sha),
        "--jq", ".commit.committer.date")
    )
    list(tag = tag, date = as.Date(substr(trimws(commit_date_str[1]), 1, 10)))
  })

  tag_df <- do.call(rbind, lapply(tag_dates, as.data.frame, stringsAsFactors = FALSE))
  candidates <- tag_df[tag_df$date <= date, , drop = FALSE]

  if (nrow(candidates) == 0) {
    stop("No tags found for ", full_repo, " on or before ", date)
  }

  candidates$tag[which.max(candidates$date)]
}


#' Get the commit SHA for a given ref
#'
#' @param org Character. GitHub organization.
#' @param repo Character. Repository name.
#' @param ref Character. Tag, branch, or SHA.
#' @return Character. The full commit SHA.
gh_get_sha <- function(org, repo, ref) {
  full_repo <- paste0(org, "/", repo)
  result <- gh_api(
    c("api", paste0("repos/", full_repo, "/commits/", ref), "--jq", ".sha")
  )
  if (length(result) == 0 || grepl("Not Found", result[1])) {
    stop("Could not resolve ref '", ref, "' for ", full_repo)
  }
  trimws(result[1])
}

#' Get the package version from DESCRIPTION file at a given SHA
#'
#' @param org Character. GitHub organization.
#' @param repo Character. Repository name.
#' @param sha Character. Commit SHA.
#' @return Character. The package version string.
gh_get_version <- function(org, repo, sha) {
  full_repo <- paste0(org, "/", repo)
  result <- gh_api(
    c("api", paste0("repos/", full_repo, "/contents/DESCRIPTION?ref=", sha),
      "--jq", ".content")
  )

  if (length(result) == 0 || grepl("Not Found", result[1])) {
    warning("No DESCRIPTION file found for ", full_repo, " at ", sha, ". Using 'unknown'.")
    return("unknown")
  }

  # Decode base64 content
  desc_content <- rawToChar(base64enc::base64decode(paste0(result, collapse = "")))
  version_line <- grep("^Version:", strsplit(desc_content, "\n")[[1]], value = TRUE)

  if (length(version_line) == 0) {
    warning("No Version field in DESCRIPTION for ", full_repo)
    return("unknown")
  }

  trimws(sub("^Version:\\s*", "", version_line[1]))
}
