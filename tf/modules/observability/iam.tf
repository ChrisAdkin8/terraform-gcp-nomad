# Service Accounts
# -----------------

# Main Loki service account
resource "google_service_account" "loki" {
  account_id   = "loki-service-account"
  display_name = "Loki Logging Service Account"
  description  = "Service account for Loki to access GCS, BigQuery, and Pub/Sub"
}

# Service account for Cloud Function (if different from main Loki SA)
resource "google_service_account" "loki_function" {
  account_id   = "loki-function-sa"
  display_name = "Loki Export Function Service Account"
  description  = "Service account for Cloud Function to export logs to BigQuery"
}

# Service account key for Loki (to be stored in Vault/Nomad variables)
resource "google_service_account_key" "loki_key" {
  service_account_id = google_service_account.loki.name
}

resource "nomad_variable" "loki_gcs_key" {
  path = "nomad/jobs/loki_gateway/backend/loki"
  
  items = {
    gcs_service_account_key = base64decode(google_service_account_key.loki_key.private_key)
  }
}

# Data source to get project number (needed for Pub/Sub service account)
data "google_project" "project" {
  project_id = local.project_id
}

# IAM Bindings - GCS Storage Bucket
# -----------------------------------

# Loki service account to access GCS bucket
resource "google_storage_bucket_iam_member" "loki_bucket_admin" {
  bucket = google_storage_bucket.loki.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.loki.email}"
}

# Function service account to read from Loki GCS bucket
resource "google_storage_bucket_iam_member" "function_loki_bucket_reader" {
  bucket = google_storage_bucket.loki.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.loki_function.email}"
}

# Function service account to manage function source bucket
resource "google_storage_bucket_iam_member" "function_source_admin" {
  bucket = google_storage_bucket.function_source.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.loki_function.email}"
}

# IAM Bindings - BigQuery
# -------------------------

# Loki service account to write to BigQuery dataset
resource "google_bigquery_dataset_iam_member" "loki_bq_editor" {
  dataset_id = google_bigquery_dataset.loki_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.loki.email}"
}

# Loki service account to use BigQuery (run queries/jobs)
resource "google_bigquery_dataset_iam_member" "loki_bq_user" {
  dataset_id = google_bigquery_dataset.loki_logs.dataset_id
  role       = "roles/bigquery.user"
  member     = "serviceAccount:${google_service_account.loki.email}"
}

# Function service account to write to BigQuery
resource "google_bigquery_dataset_iam_member" "function_bq_editor" {
  dataset_id = google_bigquery_dataset.loki_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.loki_function.email}"
}

# Pub/Sub service account to write to BigQuery
resource "google_bigquery_dataset_iam_member" "pubsub_bq_editor" {
  dataset_id = google_bigquery_dataset.loki_logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# Project-level BigQuery IAM (for job execution)
resource "google_project_iam_member" "loki_bq_job_user" {
  project = local.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.loki.email}"
}

resource "google_project_iam_member" "function_bq_job_user" {
  project = local.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.loki_function.email}"
}

# IAM Bindings - Pub/Sub
# ------------------------

# Loki service account to publish to Pub/Sub topic
resource "google_pubsub_topic_iam_member" "loki_publisher" {
  topic  = google_pubsub_topic.loki_logs.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.loki.email}"
}

# Function service account to publish to Pub/Sub topic
resource "google_pubsub_topic_iam_member" "function_publisher" {
  topic  = google_pubsub_topic.loki_logs.name
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:${google_service_account.loki_function.email}"
}

# Pub/Sub service account to create subscriptions
resource "google_pubsub_topic_iam_member" "pubsub_subscriber" {
  topic  = google_pubsub_topic.loki_logs.name
  role   = "roles/pubsub.subscriber"
  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# IAM Bindings - Cloud Functions
# --------------------------------

# Cloud Scheduler to invoke Cloud Function
/*
resource "google_cloudfunctions_function_iam_member" "scheduler_invoker" {
  project        = local.project_id
  region         = var.region
  cloud_function = "loki-export"
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.loki.email}"
}

# IAM Bindings - Cloud Scheduler
# --------------------------------

# If you need the Loki service account to manage scheduler jobs

resource "google_project_iam_member" "loki_scheduler_admin" {
  project = local.project_id
  role    = "roles/cloudscheduler.admin"
  member  = "serviceAccount:${google_service_account.loki.email}"
}
*/