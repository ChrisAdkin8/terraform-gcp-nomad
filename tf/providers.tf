variable "initial_management_token" {
  description = "Pre-seeded consul ACL bootstrap token"
  type        = string
  sensitive   = true
}

provider "google" {
  project = var.project_id
  region  = var.region
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

provider "grafana" {
  url  = "http://grafana.traefik-dc1.${local.project_id}.${local.base_domain}:8080"
  auth = "admin:admin" 
}