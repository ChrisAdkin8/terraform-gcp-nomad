locals {
  mgmt_cidr             = "${chomp(data.http.mgmt_ip.response_body)}/32"
  name_prefix           = format("%s-%s", random_pet.default.id, var.datacenter)
  secondary_name_prefix = format("%s-%s", random_pet.default.id, var.secondary_datacenter)

  nomad_url           = "http://${module.nomad.fqdn}:4646"
  secondary_nomad_url = "http://${module.secondary_nomad.fqdn}:4646"
}

resource "random_pet" "default" {
  length = 1
}
