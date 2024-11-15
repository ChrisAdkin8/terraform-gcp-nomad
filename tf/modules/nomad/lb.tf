# Health Check
resource "google_compute_health_check" "default" {
  name = "http-health-check"

  http_health_check {
    port = 80
  }

  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 3
  unhealthy_threshold = 3
}

# Backend Service
resource "google_compute_backend_service" "backend_service" {
  name                            = "backend-service"
  health_checks                   = [google_compute_health_check.default.id]
  load_balancing_scheme           = "EXTERNAL"
  protocol                        = "HTTP"
  timeout_sec                     = 10
  port_name                       = "http"
  enable_cdn                      = false

  backend {
    group                        = google_compute_region_instance_group_manager.nomad_client.instance_group
    balancing_mode               = "UTILIZATION"
    max_utilization              = 0.8
  }
}

# URL Map
resource "google_compute_url_map" "url_map" {
  name            = "url-map"
  default_service = google_compute_backend_service.backend_service.id
}

# HTTP Target Proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  name   = "http-proxy"
  url_map = google_compute_url_map.url_map.id
}

# Global Forwarding Rule for the HTTP Load Balancer
resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name                  = "http-forwarding-rule"
  target                = google_compute_target_http_proxy.http_proxy.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
}

# Reserve a static external IP address for the Load Balancer
resource "google_compute_global_address" "lb_ip_address" {
  name = "lb-ip-address"
}

# Attach the reserved IP to the forwarding rule
resource "google_compute_global_forwarding_rule" "http_forwarding_rule_with_ip" {
  name                  = "http-forwarding-rule"
  target                = google_compute_target_http_proxy.http_proxy.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.lb_ip_address.address
}