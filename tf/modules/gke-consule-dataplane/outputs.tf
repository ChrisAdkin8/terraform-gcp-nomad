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

# Consul Integration Outputs
output "consul_ingress_gateway_ip" {
  value = var.enable_ingress_gateway ? (
    try(data.kubernetes_service.ingress_gateway[0].status[0].load_balancer[0].ingress[0].ip, null)
  ) : null
  description = "External IP of Consul ingress gateway LoadBalancer"
}

output "consul_namespace" {
  value       = kubernetes_namespace.consul.metadata[0].name
  description = "Kubernetes namespace where Consul is deployed"
}

output "gke_cluster_ca_certificate" {
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  description = "Base64 encoded CA certificate for GKE cluster"
  sensitive   = true
}
