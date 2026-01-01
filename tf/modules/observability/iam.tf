resource "google_storage_bucket_iam_member" "nomad_client_loki_access" {
  bucket = google_storage_bucket.loki.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.nomad_client_sa_email}"
}

resource "random_password" "grafana_admin" {
  length           = 16
  special          = true
  # I have removed $ # & ! ( ) < > and others that break scripts
  override_special = "_%-" 
}