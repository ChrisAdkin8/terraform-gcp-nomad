# Allow GKE nodes to communicate with Consul servers
resource "google_compute_firewall" "gke_to_consul" {
  name    = "${var.cluster_name}-to-consul-servers"
  network = data.google_compute_network.provided.name

  allow {
    protocol = "tcp"
    ports    = ["8500", "8502", "8301", "8600"]
  }

  source_ranges = concat(
    [data.google_compute_subnetwork.provided.ip_cidr_range],
    [for range in data.google_compute_subnetwork.provided.secondary_ip_range : range.ip_cidr_range]
  )

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

  source_ranges = var.ingress_gateway_source_ranges
  target_tags   = ["gke-node", "${var.project_id}-gke"]

  description = "Allow external traffic to Consul ingress gateway"
}

resource "google_compute_firewall" "allow_master_to_kubelet" {
  count   = length(data.google_container_cluster.primary.private_cluster_config) > 0 && data.google_container_cluster.primary.private_cluster_config[0].master_ipv4_cidr_block != "" ? 1 : 0
  name    = "${var.cluster_name}-allow-master-to-kubelet"
  network = data.google_compute_network.provided.name

  allow {
    protocol = "tcp"
    ports    = ["10250"]
  }

  source_ranges = [data.google_container_cluster.primary.private_cluster_config[0].master_ipv4_cidr_block]
  target_tags   = ["gke-node", "${var.project_id}-gke"]

  description = "Allow GKE Master to reach Kubelet for logs/exec/metrics"
}

resource "google_compute_firewall" "allow_master_to_consul_webhook" {
  count   = length(data.google_container_cluster.primary.private_cluster_config) > 0 && data.google_container_cluster.primary.private_cluster_config[0].master_ipv4_cidr_block != "" ? 1 : 0
  name    = "${var.cluster_name}-allow-master-to-webhook"
  network = data.google_compute_network.provided.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "9443"]
  }

  source_ranges = [data.google_container_cluster.primary.private_cluster_config[0].master_ipv4_cidr_block]
  target_tags   = ["gke-node", "${var.project_id}-gke"]

  description = "Allow GKE Master to reach Consul Webhooks"
}