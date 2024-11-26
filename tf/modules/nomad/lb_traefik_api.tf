resource "google_compute_health_check" "traefik_api" {
  name                = "${var.name_prefix}-tapi-health-check"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2

  tcp_health_check {
    port = "8080"
  }
}

resource "google_compute_backend_service" "traefik_api" {
  name                  = "${var.name_prefix}-tapi-backend-service"
  health_checks         = [google_compute_health_check.traefik_api.self_link]
  port_name             = "traefikapi"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"

  backend {
    group = google_compute_region_instance_group_manager.nomad_client[0].instance_group
  }
}

resource "google_compute_url_map" "traefik_api" {
  name            = "${var.name_prefix}-tapi-url-map"
  default_service = google_compute_backend_service.traefik_api.self_link
}

resource "google_compute_target_http_proxy" "traefik_api" {
  name    = "${var.name_prefix}-tapi-http-proxy"
  url_map = google_compute_url_map.traefik_api.self_link
}

resource "google_compute_global_forwarding_rule" "traefik_api" {
  name       = "${var.name_prefix}-tapi-forwarding-rule"
  target     = google_compute_target_http_proxy.traefik_api.self_link
  port_range = "8080"
  load_balancing_scheme = "EXTERNAL"
}

resource "google_compute_firewall" "traefik_api" {
  name    = "${var.name_prefix}-traefik-api"
  network = "${var.short_prefix}-vpc"

  allow {
    protocol = "tcp"
    ports = [
      "8080"
    ]
  }
  source_ranges = ["0.0.0.0/0"]
  
  target_tags = [
    "nomad-client"
  ]
}