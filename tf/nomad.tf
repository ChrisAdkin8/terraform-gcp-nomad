module "secondary_nomad" {
  source = "./modules/nomad"

  create_nomad_cluster   = var.create_secondary_nomad_cluster
  create_dns_record      = false   
  datacenter             = var.secondary_datacenter
  gcs_bucket             = google_storage_bucket.default.name
  name_prefix            = local.secondary_name_prefix
  short_prefix           = random_pet.default.id
  nomad_client_instances = var.secondary_nomad_client_instances
  nomad_server_instances = var.secondary_nomad_server_instances
  project_id             = var.project_id
  region                 = var.secondary_region
  subnet_self_link       = module.network.secondary_subnet_self_link
  zone                   = data.google_compute_zones.secondary.names[0]
  base_domain            = local.base_domain  

  depends_on = [
    consul_acl_policy.secondary_nomad_agent,
    module.network ]
}

module "nomad" {
  source = "./modules/nomad"

  create_nomad_cluster   = var.create_nomad_cluster
  create_dns_record      = true 
  datacenter             = var.datacenter
  gcs_bucket             = google_storage_bucket.default.name
  name_prefix            = local.name_prefix
  short_prefix           = random_pet.default.id
  nomad_client_instances = var.nomad_client_instances
  nomad_server_instances = var.nomad_server_instances
  project_id             = var.project_id
  region                 = var.region
  subnet_self_link       = module.network.subnet_self_link
  zone                   = data.google_compute_zones.default.names[0]
  base_domain            = local.base_domain  

  depends_on = [
    consul_acl_policy.nomad_agent,
    module.network ]
}

module "observability" {
  source                = "./modules/observability"
  nomad_addr            = "http://${module.nomad.fqdn}:4646"
  consul_token          = var.initial_management_token
  data_center           = "dc1" 
  base_domain           = local.base_domain
  region                = var.region 
  loki_bucket_name      = "loki_bucket"
  bigquery_dataset_name = "loki_logs"
  log_retention_days    = 90

  depends_on = [
     module.nomad
    ,null_resource.nomad_consul_setup
  ]
}

resource "random_uuid" "nomad_bootstrap" {}

resource "null_resource" "nomad_consul_setup" {
  count = var.create_nomad_cluster ? 1 : 0  

  provisioner "local-exec" {
    command = <<-EOF
      while ! nomad server members 2>&1; do
        echo 'waiting for primary nomad cluster api...'
        sleep 10
      done

      nomad setup consul -y \
      --address=http://${module.nomad.fqdn}:4646 \
      --jwks-url=http://${module.nomad.internal_server_ips[0]}:4646/.well-known/jwks.json \
      --token=${random_uuid.nomad_bootstrap.result}
    EOF

    environment = {
      NOMAD_ADDR        = local.nomad_url
      CONSUL_HTTP_ADDR  = local.consul_url
      CONSUL_HTTP_TOKEN = var.initial_management_token 
    }
  }

  depends_on = [
    module.nomad,
    module.secondary_nomad,
  ]
}

resource "null_resource" "secondary_nomad_consul_setup" {
  count = var.create_secondary_nomad_cluster ? 1 : 0  

  provisioner "local-exec" {
    command = <<-EOF
      while ! nomad server members 2>&1; do
        echo 'waiting for secondary nomad cluster api...'
        sleep 10
      done

      nomad setup consul -y \
      --address=http://${module.secondary_nomad.fqdn}:4646 \
      --jwks-url=http://${module.secondary_nomad.internal_server_ips[0]}:4646/.well-known/jwks.json \
      --token=${random_uuid.nomad_bootstrap.result}
    EOF

    environment = {
      NOMAD_ADDR        = local.secondary_nomad_url
      CONSUL_HTTP_ADDR  = local.secondary_consul_url
      CONSUL_HTTP_TOKEN = var.initial_management_token 
    }
  }

  depends_on = [
    module.nomad,
    module.secondary_nomad,
    null_resource.nomad_consul_setup
  ]
}