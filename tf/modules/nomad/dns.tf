resource "google_dns_record_set" "default" {
  count = var.create_nomad_cluster ? 1 : 0

  managed_zone = data.google_dns_managed_zone.default.name
  name         = "nomad-${var.datacenter}.${data.google_dns_managed_zone.default.dns_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = [for instance in google_compute_instance.nomad_servers : instance.network_interface[0].access_config[0].nat_ip]
}
resource "google_dns_record_set" "traefik_api" {
  count = var.create_nomad_cluster ? 1 : 0

  managed_zone = data.google_dns_managed_zone.default.name
  name         = "*.traefik-${var.datacenter}.${data.google_dns_managed_zone.default.dns_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = [google_compute_forwarding_rule.traefik_api.ip_address]
}

data "google_client_config" "current" {}

resource "google_dns_record_set" "observability_endpoints" {
  count = var.create_nomad_cluster ? 1 : 0

  managed_zone = data.google_dns_managed_zone.default.name
  name         = "*.traefik-${var.datacenter}.${data.google_client_config.current.project}.${var.base_domain}."
  type         = "A"
  ttl          = 60
  rrdatas      = [google_compute_forwarding_rule.traefik_api.ip_address]
}