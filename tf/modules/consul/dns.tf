resource "google_dns_record_set" "default" {
  count = var.create_consul_cluster ? 1 : 0

  managed_zone = data.google_dns_managed_zone.default.name
  name         = "consul-${var.datacenter}.${data.google_dns_managed_zone.default.dns_name}"
  type         = "A"
  ttl          = 60
  rrdatas      = [for instance in google_compute_instance.consul_servers : instance.network_interface[0].access_config[0].nat_ip]
}