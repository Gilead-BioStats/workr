# Custom S3 load/save hooks for workr, following the gismo.runner pattern of
# keeping the S3 client and storage paths in runtime configuration.

s3_key <- function(prefix, name) {
  prefix <- sub("^/+|/+$", "", prefix)
  if (nzchar(prefix)) paste(prefix, name, sep = "/") else name
}

workflow_name <- function(lWorkflow) {
  paste(lWorkflow$meta$Type, lWorkflow$meta$ID, sep = "_")
}

workr::register_load_provider(
  "example.s3.load",
  function(lWorkflow, lConfig, lData) {
    settings <- lConfig$s3
    response <- settings$client$get_object(
      Bucket = settings$bucket,
      Key = settings$input_key
    )

    loaded <- unserialize(response$Body)
    lData[[settings$input_name]] <- loaded
    lData
  }
)

workr::register_save_provider(
  "example.s3.save",
  function(lWorkflow, lConfig) {
    settings <- lConfig$s3
    key <- s3_key(
      settings$output_prefix,
      paste0(workflow_name(lWorkflow), ".rds")
    )

    settings$client$put_object(
      Bucket = settings$bucket,
      Key = key,
      Body = serialize(lWorkflow$lResult, connection = NULL)
    )
    invisible(key)
  }
)

run_with_s3_error_log <- function(lWorkflow, lConfig, lData = list()) {
  tryCatch(
    workr::RunWorkflow(
      lWorkflow = lWorkflow,
      lData = lData,
      lConfig = lConfig
    ),
    error = function(err) {
      settings <- lConfig$s3
      timestamp <- format(Sys.time(), "%Y%m%dT%H%M%SZ", tz = "UTC")
      key <- s3_key(
        settings$error_prefix,
        paste0(workflow_name(lWorkflow), "_", timestamp, ".log")
      )
      log_text <- paste(
        paste("timestamp_utc:", timestamp),
        paste("workflow:", workflow_name(lWorkflow)),
        paste("error:", conditionMessage(err)),
        sep = "\n"
      )

      tryCatch(
        settings$client$put_object(
          Bucket = settings$bucket,
          Key = key,
          Body = charToRaw(paste0(log_text, "\n")),
          ContentType = "text/plain"
        ),
        error = function(upload_err) {
          warning(
            "Could not upload error log to s3://",
            settings$bucket,
            "/",
            key,
            ": ",
            conditionMessage(upload_err),
            call. = FALSE
          )
        }
      )

      stop(err)
    }
  )
}

# The input object at input_key is expected to be an RDS-serialized data.frame.
# AWS credentials and region are read by paws from the standard environment.
summarise_scores <- function(subjects) {
  data.frame(
    n = nrow(subjects),
    mean_score = mean(subjects$score, na.rm = TRUE)
  )
}

example_workflow <- list(
  meta = list(Type = "Example", ID = "score_summary"),
  steps = list(
    list(
      name = "summarise_scores",
      output = "score_summary",
      params = list(subjects = "subjects")
    )
  )
)

example_config <- list(
  LoadData = "example.s3.load",
  SaveData = "example.s3.save",
  s3 = list(
    client = paws::s3(),
    bucket = "my-workr-bucket",
    input_key = "studies/S0001/input/subjects.rds",
    input_name = "subjects",
    output_prefix = "studies/S0001/output",
    error_prefix = "studies/S0001/logs"
  )
)

# Run after replacing the bucket and keys above:
# result <- run_with_s3_error_log(example_workflow, example_config)
