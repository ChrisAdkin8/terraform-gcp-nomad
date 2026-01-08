module "network" {
  source = "../../modules/network"

  project_id       = local.project_id
  name_prefix      = local.name_prefix
  mgmt_cidr        = local.mgmt_cidr
  region           = var.region
  secondary_region = var.region
  short_prefix     = random_pet.default.id
  labels           = local.common_labels
}
