locals {
  project_id               = var.project_id
  initial_management_token = var.initial_management_token
  mgmt_cidr                = "${chomp(data.http.mgmt_ip.response_body)}/32"
  name_prefix              = format("%s-%s", random_pet.default.id, var.datacenter)
  consul_url               = "http://${module.consul.fqdn}:8500"
  base_domain              = data.external.base_domain.result.domain

  # Common labels applied to all resources
  common_labels = merge({
    project     = var.project_id
    environment = var.environment
    managed_by  = "terraform"
    component   = "ai-agents-gke"
    scenario    = "hierarchical-agents"
  }, var.labels)

  # Datacenter-specific labels
  datacenter_labels = merge(local.common_labels, {
    datacenter = var.datacenter
    region     = var.region
  })
}
