resource "google_compute_health_check" "default" {
  name                = "${var.cluster_prefix}-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_backend_service" "default" {
  name                  = "${var.cluster_prefix}-backend-service"
  health_checks         = [google_compute_health_check.default.self_link]
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_region_instance_group_manager.nomad_client[0].instance_group
  }
}

resource "google_compute_url_map" "default" {
  name            = "${var.cluster_prefix}-url-map"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_http_proxy" "default" {
  name    = "${var.cluster_prefix}-http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.cluster_prefix}-forwarding-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
  load_balancing_scheme = "EXTERNAL"
}