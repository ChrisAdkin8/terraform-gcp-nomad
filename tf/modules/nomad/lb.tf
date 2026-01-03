# =============================================================================
# HEALTH CHECKS
# =============================================================================

resource "google_compute_region_health_check" "traefik_api" {
  name                = "${var.name_prefix}-tapi-health-check"
  region              = var.region
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = 8080
  }
}

resource "google_compute_region_health_check" "traefik_ui" {
  name                = "${var.name_prefix}-tui-health-check"
  region              = var.region
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = 8081
  }
}

# =============================================================================
# BACKEND SERVICES
# =============================================================================

resource "google_compute_region_backend_service" "traefik_api" {
  name                  = "${var.name_prefix}-tapi-backend-service"
  region                = var.region
  health_checks         = [google_compute_region_health_check.traefik_api.self_link]
  port_name             = "traefikapi"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  locality_lb_policy    = "ROUND_ROBIN"

  backend {
    group           = google_compute_region_instance_group_manager.nomad_client[0].instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

resource "google_compute_region_backend_service" "traefik_ui" {
  name                  = "${var.name_prefix}-tui-backend-service"
  region                = var.region
  health_checks         = [google_compute_region_health_check.traefik_ui.self_link]
  port_name             = "traefikui"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  locality_lb_policy    = "ROUND_ROBIN"

  backend {
    group           = google_compute_region_instance_group_manager.nomad_client[0].instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# =============================================================================
# URL MAPS
# =============================================================================

resource "google_compute_region_url_map" "traefik_api" {
  name            = "${var.name_prefix}-tapi-url-map"
  region          = var.region
  default_service = google_compute_region_backend_service.traefik_api.self_link
}

resource "google_compute_region_url_map" "traefik_ui" {
  name            = "${var.name_prefix}-tui-url-map"
  region          = var.region
  default_service = google_compute_region_backend_service.traefik_ui.self_link
}

# =============================================================================
# HTTP PROXIES
# =============================================================================

resource "google_compute_region_target_http_proxy" "traefik_api" {
  name    = "${var.name_prefix}-tapi-http-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.traefik_api.self_link
}

resource "google_compute_region_target_http_proxy" "traefik_ui" {
  name    = "${var.name_prefix}-tui-http-proxy"
  region  = var.region
  url_map = google_compute_region_url_map.traefik_ui.self_link
}

# =============================================================================
# FORWARDING RULES (Regional - supports custom ports)
# =============================================================================

resource "google_compute_forwarding_rule" "traefik_api" {
  name                  = "${var.name_prefix}-tapi-forwarding-rule"
  region                = var.region
  network               = "${var.short_prefix}-vpc"
  target                = google_compute_region_target_http_proxy.traefik_api.self_link
  port_range            = "8080"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "STANDARD"
  ip_protocol           = "TCP"
  labels                = merge(var.labels, { service = "traefik-api" })
}

resource "google_compute_forwarding_rule" "traefik_ui" {
  name                  = "${var.name_prefix}-tui-forwarding-rule"
  region                = var.region
  network               = "${var.short_prefix}-vpc"
  target                = google_compute_region_target_http_proxy.traefik_ui.self_link
  port_range            = "8081"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network_tier          = "STANDARD"
  ip_protocol           = "TCP"
  labels                = merge(var.labels, { service = "traefik-ui" })
}

# =============================================================================
# FIREWALL RULES
# =============================================================================

data "google_compute_subnetworks" "proxy" {
  filter = "purpose=REGIONAL_MANAGED_PROXY"
  region = var.region
}