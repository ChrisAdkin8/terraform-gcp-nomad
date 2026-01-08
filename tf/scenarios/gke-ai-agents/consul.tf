module "consul" {
  source = "../../modules/consul"

  project_id              = local.project_id
  create_consul_cluster   = var.create_consul_cluster
  consul_server_instances = var.consul_server_instances
  datacenter              = var.datacenter
  gcs_bucket              = google_storage_bucket.default.name
  name_prefix             = local.name_prefix
  region                  = var.region
  subnet_self_link        = module.network.subnet_self_link
  zone                    = data.google_compute_zones.default.names[0]
  labels                  = local.datacenter_labels

  depends_on = [
    module.network,
    google_storage_bucket_object.config,
    google_storage_bucket_object.license
  ]
}

data "http" "consul_status" {
  url = "${local.consul_url}/v1/status/leader"

  request_headers = {
    "X-Consul-Token" = var.initial_management_token
  }

  retry {
    attempts     = 10
    min_delay_ms = 1024
  }

  depends_on = [module.consul]
}
