resource "google_storage_bucket" "loki" {
  name          = "${var.loki_bucket_name}-${var.project_id}"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = var.log_retention_days
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
  path = "nomad/jobs/loki/loki_group/loki"

  items = {
    gcs_bucket_name = google_storage_bucket.loki.name
  }
}