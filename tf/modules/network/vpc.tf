#------------------------------------------------------------------------------
# Network
#------------------------------------------------------------------------------
resource "google_compute_network" "default" {
  name                            = "${var.short_prefix}-vpc"
  routing_mode                    = "REGIONAL"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = false
}

resource "google_compute_subnetwork" "default" {
  name                     = "${var.name_prefix}-snet"
  ip_cidr_range            = var.subnet_cidr
  network                  = google_compute_network.default.self_link
  purpose                  = "PRIVATE"
  private_ip_google_access = true
  region                   = var.region
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_router" "default" {
  name    = "${var.name_prefix}-router"
  network = google_compute_network.default.self_link
  region  = var.region
}

resource "google_compute_router_nat" "default" {
  name                               = "${var.name_prefix}-nat"
  region                             = var.region
  router                             = google_compute_router.default.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_subnetwork" "secondary" {
  name                     = "${var.name_prefix}-secondary-snet"
  ip_cidr_range            = var.secondary_subnet_cidr
  network                  = google_compute_network.default.self_link
  purpose                  = "PRIVATE"
  private_ip_google_access = true
  region                   = var.secondary_region
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_router" "secondary" {
  name    = "${var.name_prefix}-secondary-router"
  network = google_compute_network.default.self_link
  region  = var.secondary_region
}

resource "google_compute_router_nat" "secondary" {
  name                               = "${var.name_prefix}-secondary-nat"
  region                             = var.secondary_region
  router                             = google_compute_router.secondary.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
