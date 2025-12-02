#------------------------------------------------------------------------------
# Consul Cluster Service Account
#------------------------------------------------------------------------------
resource "google_service_account" "default" {
  account_id  = "${var.name_prefix}-consul-sa"
  description = "Custom SA for Consul cluster"
}

resource "google_project_iam_member" "default" {
  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/compute.viewer",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer",
    "roles/storage.objectViewer",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.default.email}"
}