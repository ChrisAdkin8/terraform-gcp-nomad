# GKE cluster outputs
output "region" {
  value       = var.region
  description = "GCloud Region"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

output "kubernetes_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.primary.endpoint
  description = "GKE Cluster Host"
}

output "gke_cluster_ca_certificate" {
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  description = "Base64 encoded CA certificate for GKE cluster"
  sensitive   = true
}

# Consul integration outputs
output "consul_namespace" {
  value       = kubernetes_namespace.consul.metadata[0].name
  description = "Kubernetes namespace where Consul is deployed"
}

output "consul_public_url" {
  value       = "https://${var.consul_address}:8501"
  description = "The external URL for the Consul Cluster"
}

output "consul_ingress_gateway_ip" {
  value = var.enable_ingress_gateway ? (
    try(data.kubernetes_service.ingress_gateway[0].status[0].load_balancer[0].ingress[0].ip, "Pending")
  ) : "Disabled"
  description = "External IP of Consul ingress gateway LoadBalancer"
}

