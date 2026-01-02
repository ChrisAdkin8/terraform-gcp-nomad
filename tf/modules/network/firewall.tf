#----------------------------------------------------------------------------------------------
# Firewall Rules
#----------------------------------------------------------------------------------------------
data "google_netblock_ip_ranges" "iap" {
  range_type = "iap-forwarders"
}

data "google_netblock_ip_ranges" "lb" {
  range_type = "health-checkers"
}

resource "google_compute_firewall" "iap_ssh" {
  name          = "${var.name_prefix}-iap-ssh"
  network       = google_compute_network.default.name
  direction     = "INGRESS"
  source_ranges = data.google_netblock_ip_ranges.iap.cidr_blocks
  target_tags   = ["consul-server", "nomad-server", "nomad-client"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "consul_mgmt" {
  name    = "${var.name_prefix}-consul-mgmt-ingress"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["8500"]
  }

  source_ranges = [var.mgmt_cidr]

  target_tags = ["consul-server"]
}

resource "google_compute_firewall" "nomad_mgmt" {
  name    = "${var.name_prefix}-nomad-mgmt-ingress"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["4646"]
  }

  source_ranges = [var.mgmt_cidr]

  target_tags = ["nomad-server"]
}

resource "google_compute_firewall" "nomad_consul" {
  name    = "${var.name_prefix}-nomad-consul-ingress"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [
      "4646",
      "4647",
      "4648",
      "8500",
      "8501",
      "8502",
      "8503",
      "8600",
      "8300",
      "8301",
      "8302",
    ]
  }

  allow {
    protocol = "udp"
    ports = [
      "4648",
      "8301",
      "8302",
      "8600",
    ]
  }

  source_tags = [
    "nomad-server",
    "nomad-client",
    "consul-server",
  ]

  target_tags = [
    "nomad-server",
    "consul-server",
  ]
}

resource "google_compute_firewall" "nomad_client" {
  name    = "${var.name_prefix}-nomad-client-ingress"
  network = google_compute_network.default.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports = [
      "4647",
      "8301",
    ]
  }

  source_tags = [
    "nomad-server",
    "nomad-client",
  ]

  target_tags = [
    "nomad-client",
  ]
}

resource "google_compute_firewall" "allow_observability_internal" {
  name    = "${var.name_prefix}-allow-observability-internal"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["3000", "3100", "12344", "12345", "12346"]
  }

 source_tags = [
    "nomad-server",
    "nomad-client",
  ]

  target_tags = [
    "nomad-client",
  ]

  source_ranges = ["10.128.0.0/16"]
  
  description = "Allow internal observability traffic (Loki, Alloy gateway)"
}

resource "google_compute_firewall" "lb_health_checks" {
  name    = "${var.name_prefix}-lb-health-checks"
  network = google_compute_network.default.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "8081"]
  }

  source_ranges = data.google_netblock_ip_ranges.lb.cidr_blocks
  
  target_tags   = [
    "nomad-client"
  ]
  
  description = "Allow GCP load balancer health checks to Traefik"
}