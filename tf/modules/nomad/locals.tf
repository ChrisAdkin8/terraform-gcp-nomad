locals {
  project_id = data.google_client_config.current.project
  
  nomad_server_metadata = {
    DATACENTER = var.datacenter
    GCS_BUCKET = var.gcs_bucket
    NOMAD_ROLE = "server"
    REGION     = var.region
  }
  
  nomad_client_metadata = {
    DATACENTER = var.datacenter
    GCS_BUCKET = var.gcs_bucket
    NOMAD_ROLE = "client"
    REGION     = var.region
  }
}