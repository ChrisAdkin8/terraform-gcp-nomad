# Service Accounts
# -----------------

# Main Loki service account
resource "google_service_account" "loki" {
  account_id   = "loki-service-account"
  display_name = "Loki Logging Service Account"
  description  = "Service account for Loki to access GCS, BigQuery, and Pub/Sub"
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

# IAM Bindings - GCS Storage Bucket
# -----------------------------------

# Loki service account to access GCS bucket
resource "google_storage_bucket_iam_member" "loki_bucket_admin" {
  bucket = google_storage_bucket.loki.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.loki.email}"
}