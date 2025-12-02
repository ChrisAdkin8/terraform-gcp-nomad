module "network" {
  source = "./modules/network"

  name_prefix      = local.name_prefix
  mgmt_cidr        = local.mgmt_cidr
  project_id       = var.project_id
  region           = var.region
  secondary_region = var.secondary_region
  short_prefix     = random_pet.default.id
}