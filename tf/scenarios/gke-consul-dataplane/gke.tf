module "gke_dataplane" {
  source = "../../modules/gke-consul-dataplane"

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
  gke_num_nodes      = var.gke_num_nodes
  machine_type       = var.gke_machine_type
 
  # Consul features
  enable_service_mesh    = var.enable_service_mesh
  enable_ingress_gateway = var.enable_ingress_gateway
  helm_chart_version     = var.helm_chart_version
  client_log_level       = "trace"

  # Labels
  short_prefix = random_pet.default.id
  labels       = local.datacenter_labels
}
