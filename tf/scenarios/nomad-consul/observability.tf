# The module gained a count; keep existing deployments' state (and the Loki
# bucket, which has force_destroy) instead of destroying and recreating it.
moved {
  from = module.observability
  to   = module.observability[0]
}

module "observability" {
  source = "../../modules/observability"
  count  = var.create_nomad_jobs ? 1 : 0

  providers = {
    nomad = nomad.with_acl_token
  }

  project_id            = local.project_id
  nomad_addr            = "http://${module.nomad.fqdn}:4646"
  consul_token          = var.initial_management_token
  datacenter            = var.datacenter
  base_domain           = local.base_domain
  region                = var.region
  loki_bucket_name      = "loki_bucket"
  log_retention_days    = 90
  nomad_client_sa_email = module.nomad.nomad_client_sa_email
  labels                = local.primary_labels

  depends_on = [
    module.nomad,
    null_resource.nomad_consul_setup,
    data.external.nomad_acl_bootstrap_token
  ]
}