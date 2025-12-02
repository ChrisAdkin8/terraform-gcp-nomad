data "google_compute_image" "almalinux_consul_server" {
  family  = "almalinux-consul-server"
  project = var.project_id
}

data "google_dns_managed_zone" "default" {
  name = var.dns_managed_zone
}