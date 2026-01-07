# GCP network data sources
data "google_compute_subnetwork" "provided" {
  self_link = var.subnet_self_link
}

data "google_compute_network" "provided" {
  name = regex("([^/]+)$", data.google_compute_subnetwork.provided.network)[0]
}

# GCP client config for authentication
data "google_client_config" "default" {}

# Kubernetes service for ingress gateway LoadBalancer IP
data "kubernetes_service" "ingress_gateway" {
  count = var.enable_ingress_gateway ? 1 : 0
  metadata {
    name      = "consul-ingress-gateway"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }
  depends_on = [helm_release.consul]
}

data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

data "google_container_cluster" "primary" {
  name     = google_container_cluster.primary.name
  location = var.region 
  project  = var.project_id
}