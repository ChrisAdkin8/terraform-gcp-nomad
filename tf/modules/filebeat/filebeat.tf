resource "google_project_service" "logging_api" {
  project = var.project_id
  service = "logging.googleapis.com"
}

# Create a Google Cloud service account
resource "google_service_account" "filebeat" {
  account_id   = var.service_account_name
  display_name = "Service account for Filebeat to send logs to Google Cloud Logging"
}

# Assign Logs Writer role to the service account
resource "google_project_iam_member" "filebeat_logs_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.filebeat.email}"
}

# Generate a service account key (JSON)
resource "google_service_account_key" "filebeat_key" {
  service_account_id = google_service_account.filebeat.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}

# Save the JSON key locally
resource "local_file" "filebeat_gcp_key" {
  content  = google_service_account_key.filebeat_key.private_key
  filename = "${path.module}/filebeat-gcp-key.json"
}

# Nomad job file for Filebeat
data "template_file" "filebeat_config" {
  template = file("${path.module}/filebeat.yml.tpl")

  vars = {
    nomad_addr = var.nomad_addr
    project_id = var.project_id
  }
}
resource "local_file" "filebeat_config" {
  content  = data.template_file.filebeat_config.rendered
  filename = "${path.module}/filebeat.yml"
}

resource "nomad_job" "filebeat" {
  jobspec = templatefile("${path.module}/filebeat.nomad.tpl",  {
    image       = "elastic/filebeat:8.16.1",
    module_path = "${path.module}",
    nomad_addr  = var.nomad_addr,
    project_id  = var.project_id
  })

  depends_on = [ local_file.filebeat_config ]
}

#resource "local_file" "foo" {
#  content = templatefile("${path.module}/filebeat.nomad.tpl",  {
#    image       = "elastic/filebeat:8.16.1",
#    module_path = "${path.module}",
#    nomad_addr  = var.nomad_addr,
#    project_id  = var.project_id
#  })
#  filename = "${path.module}/jobspec.hcl"
#}