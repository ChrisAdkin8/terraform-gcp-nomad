provider "google" {
  project = var.project_id
  region  = var.region
}

provider "nomad" {
  address = "http://${module.nomad.fqdn}:4646"
  region  = var.region
}
