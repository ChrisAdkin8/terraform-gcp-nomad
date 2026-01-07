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

  log_config {
    aggregation_interval = local.subnet_log_config.aggregation_interval
    flow_sampling        = local.subnet_log_config.flow_sampling
    metadata             = local.subnet_log_config.metadata
  }
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
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.default.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = local.nat_log_config.enable
    filter = local.nat_log_config.filter
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

  log_config {
    aggregation_interval = local.subnet_log_config.aggregation_interval
    flow_sampling        = local.subnet_log_config.flow_sampling
    metadata             = local.subnet_log_config.metadata
  }
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
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.secondary.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = local.nat_log_config.enable
    filter = local.nat_log_config.filter
  }
}
resource "google_compute_subnetwork" "proxy_only" {
  for_each = toset([var.region, var.secondary_region])

  name          = "${var.name_prefix}-proxy-only-${each.key}"
  region        = each.key
  network       = google_compute_network.default.self_link
  ip_cidr_range = each.key == var.region ? var.proxy_subnet_cidr : var.secondary_proxy_subnet_cidr
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
}