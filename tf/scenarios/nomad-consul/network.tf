module "network" {
  source = "../../modules/network"
  
  project_id       = var.project_id
  name_prefix      = local.name_prefix
  mgmt_cidr        = local.mgmt_cidr
  region           = var.region
  secondary_region = var.secondary_region
  short_prefix     = random_pet.default.id
}