provider "google" {
  region  = var.region
  project = local.project_id

  batching {
    enable_batching = true
    send_after      = "10s"
  }

  request_timeout = "60s"
}

provider "consul" {
  address = "http://${module.consul.fqdn}:8500"
  token   = var.initial_management_token
}
