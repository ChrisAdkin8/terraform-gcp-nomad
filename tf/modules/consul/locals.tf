locals {
  consul_server_metadata = {
    DATACENTER = var.datacenter
    GCS_BUCKET = var.gcs_bucket
    REGION     = var.region
  }
}