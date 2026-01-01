output "names" {
  value       = [for instance in google_compute_instance.nomad_servers : instance.name]
  description = "Names of Nomad server instances"
}

output "external_server_ips" {
  value       = [for instance in google_compute_instance.nomad_servers : instance.network_interface[0].access_config[0].nat_ip]
  description = "External IP addresses of Nomad server instances"
}

output "internal_server_ips" {
  value       = [for instance in google_compute_instance.nomad_servers : instance.network_interface[0].network_ip]
  description = "Internal IP addresses of Nomad server instances"
}

output "fqdn" {
  value       = var.create_nomad_cluster ? trimsuffix(try(google_dns_record_set.default[0].name, ""), ".") : null
  description = "FQDN of the Nomad server"
}

output "traefik_ui_ip" {
  description = "The public IP address of the traefik UI."
  value = google_compute_forwarding_rule.traefik_ui.ip_address
}

output "traefik_api_ip" {
  description = "The public IP address of the traefik API."
  value = google_compute_forwarding_rule.traefik_api.ip_address
}

output "nomad_client_sa_email" {
  description = "Email of the Nomad cluster service account"
  value       = google_service_account.default.email
}