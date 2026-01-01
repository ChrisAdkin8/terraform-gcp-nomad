provider "google" {
  region     = var.region
  project    = var.project_id 

  batching {
    enable_batching = true
    send_after      = "10s"
  }
  
  request_timeout = "60s"
}

provider "nomad" {
  address = "http://${module.nomad.fqdn}:4646"
  region  = var.region
}

provider "consul" {
  alias   = "primary"
  address = "http://${module.consul.fqdn}:8500"
  token   = var.initial_management_token
}

provider "consul" {
  alias      = "secondary"
  address    = "http://${module.secondary_consul.fqdn}:8500"
  token      = var.initial_management_token
}