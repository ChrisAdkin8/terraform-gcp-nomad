resource "google_storage_bucket" "loki" {
  name          = "${var.loki_bucket_name}-${local.project_id}"
  location      = var.region
  force_destroy = true
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
} 

resource "nomad_variable" "loki_gcs" {
  path = "nomad/jobs/loki_gateway/loki_group/loki"
  
  items = {
    gcs_service_account_key = base64decode(google_service_account_key.loki_key.private_key)
    gcs_bucket_name         = google_storage_bucket.loki.name
  }
}