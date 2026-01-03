locals {
  project_id               = var.project_id
  initial_management_token = var.initial_management_token
  mgmt_cidr                = "${chomp(data.http.mgmt_ip.response_body)}/32"
  name_prefix              = format("%s-%s", random_pet.default.id, var.datacenter)
  short_prefix             = format("%s"   , random_pet.default.id)
  secondary_name_prefix    = format("%s-%s", random_pet.default.id, var.secondary_datacenter)
  nomad_url                = "http://${module.nomad.fqdn}:4646"
  secondary_nomad_url      = "http://${module.secondary_nomad.fqdn}:4646"
  consul_url               = "http://${module.consul.fqdn}:8500"
  secondary_consul_url     = "http://${module.secondary_consul.fqdn}:8500"
  base_domain              = data.external.base_domain.result.domain
  folder_id                = 0

  # Common labels applied to all resources
  common_labels = merge({
    project     = var.project_id
    environment = var.environment
    managed_by  = "terraform"
    component   = "hashicorp-cluster"
  }, var.labels)

  # Datacenter-specific labels
  primary_labels = merge(local.common_labels, {
    datacenter = var.datacenter
    region     = var.region
  })

  secondary_labels = merge(local.common_labels, {
    datacenter = var.secondary_datacenter
    region     = var.secondary_region
  })
}