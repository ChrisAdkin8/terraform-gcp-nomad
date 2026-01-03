output "cluster_summary" {
  value = join("\n", [
    "### Consul Control Plane ###",
    "-----------------------------",
    var.create_consul_cluster ? "Consul Management Console  : http://${module.consul.fqdn}:8500" : "Consul Management Console  : (Not created)",
    var.create_consul_cluster ? "Consul Server External IPs : ${join(", ", module.consul.external_server_ips)}" : "Consul Server External IPs : (Not created)",
    var.create_consul_cluster ? "Consul Server Internal IPs : ${join(", ", module.consul.internal_server_ips)}" : "Consul Server Internal IPs : (Not created)",
    "",
    "### GKE Cluster with Consul Dataplane ###",
    "------------------------------------------",
    "GKE Cluster Name           : ${module.gke_dataplane.kubernetes_cluster_name}",
    "GKE Cluster Host           : ${module.gke_dataplane.kubernetes_cluster_host}",
    "Consul Namespace           : ${module.gke_dataplane.consul_namespace}",
    var.enable_ingress_gateway ? "Ingress Gateway IP         : ${module.gke_dataplane.consul_ingress_gateway_ip != null ? module.gke_dataplane.consul_ingress_gateway_ip : "Pending..."}" : "Ingress Gateway IP         : (Disabled)",
    "",
    "### Access Commands ###",
    "----------------------",
    var.create_consul_cluster ? "export CONSUL_HTTP_ADDR=http://${module.consul.fqdn}:8500" : "",
    var.create_consul_cluster ? "export CONSUL_HTTP_TOKEN=<see sensitive output>" : "",
    "gcloud container clusters get-credentials ${module.gke_dataplane.kubernetes_cluster_name} --region ${var.region} --project ${var.project_id}",
    "kubectl get pods -n ${module.gke_dataplane.consul_namespace}",
    "",
    "### Sensitive Information ###",
    "-----------------------------",
    "Consul ACL Bootstrap Token: (See separate sensitive output for security)"
  ])
}

output "consul_acl_bootstrap_token" {
  value     = var.initial_management_token
  sensitive = true
}

output "consul_fqdn" {
  value       = var.create_consul_cluster ? module.consul.fqdn : null
  description = "Consul server FQDN"
}

output "consul_external_ips" {
  value       = var.create_consul_cluster ? module.consul.external_server_ips : []
  description = "Consul server external IPs"
}

output "gke_cluster_name" {
  value       = module.gke_dataplane.kubernetes_cluster_name
  description = "GKE cluster name"
}

output "gke_cluster_endpoint" {
  value       = module.gke_dataplane.kubernetes_cluster_host
  description = "GKE cluster endpoint"
}

output "consul_ingress_gateway_ip" {
  value       = var.enable_ingress_gateway ? module.gke_dataplane.consul_ingress_gateway_ip : null
  description = "External IP of Consul ingress gateway"
}
