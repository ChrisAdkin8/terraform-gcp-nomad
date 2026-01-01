data "google_compute_image" "almalinux_nomad_server" {
  family  = "almalinux-nomad-server"
  project = local.project_id
}

data "google_compute_image" "almalinux_nomad_client" {
  family  = "almalinux-nomad-client"
  project = local.project_id
}

data "google_compute_zones" "default" {
  region = var.region
  status = "UP"
}

data "google_dns_managed_zone" "default" {
  name = var.dns_managed_zone
}

data "google_client_config" "current" {
}

data "google_netblock_ip_ranges" "health_checkers" {
  range_type = "health-checkers"
}