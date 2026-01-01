/*
output "loki_url" {
  description = "Loki push endpoint"
  value       = "http://loki.traefik-${var.data_center}.${var.base_domain}:8080"
}

output "alloy_gateway_url" {
  description = "Alloy gateway endpoint"
  value       = "http://gateway-api.traefik-${var.data_center}.${var.base_domain}:8080"
}
*/
output "grafana_admin_password" {
    description = "Grafana admin password"
    value       = random_password.grafana_admin.result
    sensitive   = true
}