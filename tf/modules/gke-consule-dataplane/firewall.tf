# Allow GKE nodes to communicate with Consul servers
resource "google_compute_firewall" "gke_to_consul" {
  name    = "${var.cluster_name}-to-consul-servers"
  network = data.google_compute_network.provided.name

  allow {
    protocol = "tcp"
    ports    = ["8500", "8502", "8301", "8600"]
  }

  source_tags = ["gke-node", "${var.project_id}-gke"]
  target_tags = ["consul-server"]

  description = "Allow GKE nodes to communicate with Consul servers"
}

# Allow external access to ingress gateway (conditionally created)
resource "google_compute_firewall" "ingress_gateway_external" {
  count   = var.enable_ingress_gateway ? 1 : 0
  name    = "${var.cluster_name}-ingress-gateway-external"
  network = data.google_compute_network.provided.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["gke-node", "${var.project_id}-gke"]

  description = "Allow external traffic to Consul ingress gateway"
}
