module "observability" {
  source                 = "../../modules/observability"

  project_id             = local.project_id
  nomad_addr             = "http://${module.nomad.fqdn}:4646"
  consul_token           = var.initial_management_token
  data_center            = "dc1" 
  base_domain            = local.base_domain
  region                 = var.region 
  loki_bucket_name       = "loki_bucket"
  log_retention_days     = 90
  nomad_client_sa_email  = module.nomad.nomad_client_sa_email

  depends_on = [
     module.nomad,
     null_resource.nomad_consul_setup
  ]
}