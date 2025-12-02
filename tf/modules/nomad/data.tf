data "google_compute_image" "almalinux_nomad_server" {
  family  = "almalinux-nomad-server"
  project = var.project_id
}

data "google_compute_image" "almalinux_nomad_client" {
  family  = "almalinux-nomad-client"
  project = var.project_id
}

data "google_compute_zones" "default" {
  region = var.region
  status = "UP"
}

data "google_dns_managed_zone" "default" {
  name = var.dns_managed_zone
}