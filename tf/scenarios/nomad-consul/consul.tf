module "consul" {
  source = "../../modules/consul"

  project_id               = var.project_id
  create_consul_cluster    = var.create_consul_cluster
  consul_server_instances  = var.consul_server_instances
  datacenter               = var.datacenter
  gcs_bucket               = google_storage_bucket.default.name
  name_prefix              = local.name_prefix
  region                   = var.region
  subnet_self_link         = module.network.subnet_self_link
  zone                     = data.google_compute_zones.default.names[0]

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

  depends_on = [ 
    module.consul,
    module.secondary_consul
  ]
}

resource "consul_acl_policy" "nomad_agent" {
  provider = consul.primary
  name     = "primary-nomad-agent"
  rules    = <<EOF
agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "write"
}

service_prefix "" {
  policy = "write"
}

EOF

  depends_on = [ data.http.consul_status ]
}

module "secondary_consul" {
  source = "../../modules/consul"

  project_id               = var.project_id
  create_consul_cluster    = var.create_secondary_consul_cluster
  consul_server_instances  = var.secondary_consul_server_instances
  datacenter               = var.secondary_datacenter
  gcs_bucket               = google_storage_bucket.default.name
  name_prefix              = local.secondary_name_prefix
  region                   = var.secondary_region
  subnet_self_link         = module.network.secondary_subnet_self_link
  zone                     = data.google_compute_zones.secondary.names[0]

  depends_on = [
    module.network,
    google_storage_bucket_object.config,
    google_storage_bucket_object.license
  ]
}

data "http" "secondary_consul_status" {
  url = "${local.secondary_consul_url}/v1/status/leader"

  request_headers = {
    "X-Consul-Token" = var.initial_management_token
  }

  retry {
    attempts     = 10
    min_delay_ms = 1024 
  }

  depends_on = [
    module.consul,
    module.secondary_consul
  ]
}

resource "consul_acl_policy" "secondary_nomad_agent" {
  provider = consul.secondary
  name     = "secondary-nomad-agent"
  rules    = <<EOF
agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "write"
}

service_prefix "" {
  policy = "write"
}

EOF

  depends_on = [
    data.http.secondary_consul_status
  ]
}