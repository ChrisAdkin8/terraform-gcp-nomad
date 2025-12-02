
# BigQuery Dataset for log analysis
resource "google_bigquery_dataset" "loki_logs" {
  dataset_id                 = var.bigquery_dataset_name
  friendly_name              = "Loki Logs"
  description                = "Dataset for Loki log exports and analysis"
  location                   = var.region
  delete_contents_on_destroy = false
  
  default_table_expiration_ms = var.log_retention_days * 24 * 60 * 60 * 1000
  
  labels = {
    env     = "production"
    service = "loki"
  }
}

# BigQuery table for log entries
resource "google_bigquery_table" "log_entries" {
  dataset_id          = google_bigquery_dataset.loki_logs.dataset_id
  table_id            = "log_entries"
  deletion_protection = false
  
  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }
  
  clustering = ["stream_labels", "level"]
  
  schema = jsonencode([
    {
      name        = "timestamp"
      type        = "TIMESTAMP"
      mode        = "REQUIRED"
      description = "Log entry timestamp"
    },
    {
      name        = "stream_labels"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Loki stream labels (JSON)"
    },
    {
      name        = "log_line"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Raw log line"
    },
    {
      name        = "level"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Log level (info, warn, error, etc)"
    },
    {
      name        = "job"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Job name"
    },
    {
      name        = "namespace"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Namespace"
    },
    {
      name        = "pod"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Pod name"
    },
    {
      name        = "container"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Container name"
    },
    {
      name        = "labels"
      type        = "RECORD"
      mode        = "REPEATED"
      description = "Additional labels"
      fields = [
        {
          name = "key"
          type = "STRING"
          mode = "NULLABLE"
        },
        {
          name = "value"
          type = "STRING"
          mode = "NULLABLE"
        }
      ]
    },
    # Required Pub/Sub metadata columns
    {
      name        = "subscription_name"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Pub/Sub subscription name"
    },
    {
      name        = "message_id"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Pub/Sub message ID"
    },
    {
      name        = "publish_time"
      type        = "TIMESTAMP"
      mode        = "NULLABLE"
      description = "Pub/Sub publish timestamp"
    },
    {
      name        = "attributes"
      type        = "STRING"
      mode        = "NULLABLE"
      description = "Pub/Sub message attributes (JSON)"
    }
  ])
}

# Cloud Function or Cloud Run for exporting logs to BigQuery
# GCS bucket for Cloud Function source code
resource "google_storage_bucket" "function_source" {
  name          = "${var.loki_bucket_name}-${local.project_id}-func-source"
  location      = var.region
  force_destroy = true
  
  uniform_bucket_level_access = true
}

resource "google_project_service" "cloudscheduler" {
  project = local.project_id
  service = "cloudscheduler.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "cloudfunctions" {
  project = local.project_id
  service = "cloudfunctions.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "pubsub" {
  project = local.project_id
  service = "pubsub.googleapis.com"
  
  disable_on_destroy = false
}

resource "google_project_service" "bigquery" {
  project = local.project_id
  service = "bigquery.googleapis.com"
  
  disable_on_destroy = false
}

# Update the scheduler job to depend on the API
resource "google_cloud_scheduler_job" "loki_export" {
  name             = "loki-bigquery-export"
  description      = "Periodic job to export Loki logs to BigQuery"
  schedule         = "*/15 * * * *"
  time_zone        = "UTC"
  attempt_deadline = "320s"
  
  http_target {
    http_method = "POST"
    uri         = "https://${var.region}-${local.project_id}.cloudfunctions.net/loki-export"
    oidc_token {
      service_account_email = google_service_account.loki.email
    }
  }
  
  depends_on = [
    google_project_service.cloudscheduler
  ]
}

# Pub/Sub topic for log streaming (optional)
resource "google_pubsub_topic" "loki_logs" {
  name = "loki-logs-stream"
  
  message_retention_duration = "86400s" # 1 day
}
/*
resource "google_pubsub_subscription" "loki_logs_bq" {
  name  = "loki-logs-bigquery-subscription"
  topic = google_pubsub_topic.loki_logs.name
  
  bigquery_config {
    table            = "${google_bigquery_table.log_entries.project}.${google_bigquery_table.log_entries.dataset_id}.${google_bigquery_table.log_entries.table_id}"
    use_topic_schema = false
    write_metadata   = true
  }
  
  depends_on = [
    google_bigquery_dataset_iam_member.loki_bq_editor
  ]
}

# Cloud Function for log export
resource "google_cloudfunctions_function" "loki_export" {
  name        = "loki-export"
  description = "Export Loki logs to BigQuery"
  runtime     = "python311"  # or your preferred runtime
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.function_source.name
  entry_point          = "export_logs"  # Your function entry point
  
  service_account_email = google_service_account.loki_function.email
  
  timeout = 300

  environment_variables = {
    PROJECT_ID      = local.project_id
    DATASET_ID      = google_bigquery_dataset.loki_logs.dataset_id
    TABLE_ID        = google_bigquery_table.log_entries.table_id
    LOKI_BUCKET     = google_storage_bucket.loki.name
  }

  event_trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.loki.name
  }
}

# Upload function source code
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_source.output_path
}

data "archive_file" "function_source" {
  type        = "zip"
  output_path = "${path.module}/function-source.zip"
  source_dir  = "${path.module}/function-code"  # Directory containing your function code
}

# Now update the IAM member to depend on the function
resource "google_cloudfunctions_function_iam_member" "scheduler_invoker" {
  project        = local.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.loki_export.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.loki.email}"
  
  depends_on = [
    google_cloudfunctions_function.loki_export
  ]
}
*/