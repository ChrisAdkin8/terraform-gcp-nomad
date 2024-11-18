module "secondary_nomad" {
  source = "./modules/nomad"

  create_nomad_cluster   = var.create_secondary_nomad_cluster
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

  depends_on = [
    module.network,
    module.secondary_consul
  ]
}

module "nomad" {
  source = "./modules/nomad"

  create_nomad_cluster   = var.create_nomad_cluster
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

  depends_on = [
    module.network,
    module.consul
  ]
}

module "jobs" {
  source     = "./modules/jobs"

  nomad_addr = "http://${module.nomad.fqdn}:4646"

  depends_on = [
     module.nomad
    ,null_resource.wait_for_nomad_api
  ]
}

resource "null_resource" "wait_for_nomad_api" {
  count = var.create_nomad_cluster ? 1 : 0

  provisioner "local-exec" {
    command = "while ! nomad server members 2>&1; do echo 'waiting for nomad api...'; sleep 10; done"
    #command = "while ! nomad server members > /dev/null 2>&1; do echo 'waiting for nomad api...'; sleep 10; done"    command = "while ! nomad server members > /dev/null 2>&1; do echo 'waiting for nomad api...'; sleep 10; done"
    environment = {
      NOMAD_ADDR = local.nomad_url
    }
  }
  depends_on = [module.nomad, module.secondary_nomad]
}

resource "null_resource" "wait_for_secondary_nomad_api" {
  count = var.create_secondary_nomad_cluster ? 1 : 0

  provisioner "local-exec" {
    command = <<EOF
while ! nomad server members 2>&1; do echo 'waiting for nomad api...'; sleep 10; done
#gcloud compute ssh ${try(module.secondary_nomad.names[0], "")} --zone ${data.google_compute_zones.secondary.names[0]} --tunnel-through-iap -- "nomad server join ${module.nomad.internal_server_ips[0]}; nomad server members"
nomad server join ${module.nomad.internal_server_ips[0]}
nomad server members
EOF
    environment = {
      NOMAD_ADDR = local.secondary_nomad_url
    }
  }
  depends_on = [module.nomad, module.secondary_nomad, null_resource.wait_for_nomad_api]
}