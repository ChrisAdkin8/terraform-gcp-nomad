resource "google_storage_bucket" "loki" {
  name          = "${var.loki_bucket_name}-${var.project_id}"
  location      = var.region
  force_destroy = true
  labels        = merge(var.labels, { service = "loki" })

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # Loki's compactor enforces log_retention_days itself. This rule is only a
  # backstop for anything it leaves behind, a week later so the two don't race.
  lifecycle_rule {
    condition {
      age = var.log_retention_days + 7
    }
    action {
      type = "Delete"
    }
  }

  # The compactor rewrites index files every few minutes; without this,
  # versioning would keep every superseded copy until the backstop above.
  lifecycle_rule {
    condition {
      days_since_noncurrent_time = 7
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
  path = "nomad/jobs/loki/loki/loki"

  items = {
    gcs_bucket_name = google_storage_bucket.loki.name
  }
}