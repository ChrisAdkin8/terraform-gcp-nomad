output "external_server_ips" {
  value       = [for instance in google_compute_instance.consul_servers : instance.network_interface[0].access_config[0].nat_ip]
  description = "External IP addresses of Nomad server instances"
}

output "internal_server_ips" {
  value       = [for instance in google_compute_instance.consul_servers : instance.network_interface[0].network_ip]
  description = "Internal IP addresses of Nomad server instances"
}

output "fqdn" {
  value       = var.create_consul_cluster ? trimsuffix(try(google_dns_record_set.default[0].name, ""), ".") : null
  description = "FQDN of the Consul server"
}
