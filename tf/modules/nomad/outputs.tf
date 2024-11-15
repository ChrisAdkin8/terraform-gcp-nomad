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
  description = "External IP addresses of Nomad server instances"
}

output "fqdn" {
  value       = var.create_nomad_cluster ? trimsuffix(try(google_dns_record_set.default[0].name, ""), ".") : null
  description = "FQDN of the Nomad server"
}

output "load_balancer_ip" {
  description = "The public IP address of the load balancer."
  value       = google_compute_global_address.lb_ip_address.address
}