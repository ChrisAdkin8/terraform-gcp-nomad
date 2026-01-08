module "gke_dataplane" {
  source = "../../modules/gke-consul-dataplane"

  count = var.create_gke_cluster ? 1 : 0

  project_id         = local.project_id
  region             = var.region
  cluster_name       = "${local.name_prefix}-${var.gke_cluster_name}"
  subnet_self_link   = module.network.subnet_self_link

  # Consul integration
  consul_address          = "${module.consul.external_server_ips[0]}:8500"
  consul_internal_address = module.consul.internal_server_ips[0]
  consul_token            = var.initial_management_token
  consul_datacenter       = var.datacenter

  # GKE configuration
  gke_num_nodes = var.gke_num_nodes
  machine_type  = var.gke_machine_type

  # Consul features
  enable_service_mesh    = var.enable_service_mesh
  enable_ingress_gateway = var.enable_ingress_gateway
  helm_chart_version     = var.helm_chart_version

  # Labels
  short_prefix = random_pet.default.id
  labels       = local.datacenter_labels

  depends_on = [
    module.network,
    module.consul,
    data.http.consul_status
  ]
}

# Use outputs from module even when count is used
locals {
  gke_dataplane = var.create_gke_cluster ? module.gke_dataplane[0] : {
    kubernetes_cluster_name       = ""
    kubernetes_cluster_host       = ""
    consul_namespace              = ""
    consul_ingress_gateway_ip     = null
    gke_cluster_ca_certificate    = ""
  }
}

# Redirect module outputs for easier access
output "gke_module_outputs" {
  value = local.gke_dataplane
}
