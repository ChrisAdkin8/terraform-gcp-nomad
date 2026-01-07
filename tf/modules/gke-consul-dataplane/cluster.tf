# Get latest stable GKE version
data "google_container_engine_versions" "stable" {
  provider = google-beta
  location = var.region
  project  = var.project_id
}

# GKE cluster configuration
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  remove_default_node_pool = true
  min_master_version       = data.google_container_engine_versions.stable.latest_node_version
  initial_node_count       = 1

  network         = data.google_compute_network.provided.name
  subnetwork      = var.subnet_self_link
  resource_labels = var.labels

  # Enable workload identity for Consul dataplane
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

# GKE node pool configuration
resource "google_container_node_pool" "primary_nodes" {
  name               = "${google_container_cluster.primary.name}-node-pool"
  location           = var.region
  cluster            = google_container_cluster.primary.name
  initial_node_count = 1

  node_config {
    image_type   = "UBUNTU_CONTAINERD"
    disk_size_gb = 128

    labels = merge(var.labels, {
      env  = var.project_id
      role = "gke-node"
    })

    service_account = google_service_account.gke_nodes.email
    machine_type    = var.machine_type

    tags = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
