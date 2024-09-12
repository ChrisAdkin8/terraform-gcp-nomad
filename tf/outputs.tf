output "consul_server_external_ips" {
  value       = module.consul.external_server_ips
  description = "External IP addresses of Nomad server instances"
}

output "consul_server_internal_ips" {
  value       = module.consul.internal_server_ips
  description = "Internal IP addresses of Nomad server instances"
}

output "nomad_server_external_ips" {
  value       = module.nomad.external_server_ips
  description = "External IP addresses of Nomad server instances"
}

output "nomad_server_internal_ips" {
  value       = module.nomad.internal_server_ips
  description = "Internal IP addresses of Nomad server instances"
}

output "nomad_client_internal_ips" {
  value       = module.nomad.internal_client_ips
  description = "External IP addresses of Nomad client instances"
}

output "secondary_consul_server_external_ips" {
  value       = module.secondary_consul.external_server_ips
  description = "External IP addresses of Consul server failover instances"
}

output "secondary_nomad_server_external_ips" {
  value       = module.secondary_nomad.external_server_ips
  description = "External IP addresses of Nomad server failover instances"
}

output "consul_fqdn" {
  value       = module.consul.fqdn
  description = "FQDN of the Consul server"
}

output "nomad_fqdn" {
  value       = module.nomad.fqdn
  description = "FQDN of the Nomad server"
}

output "consul_url" {
  value       = "http://${module.consul.fqdn}:8500"
  description = "URL of the Consul server"
}

output "nomad_url" {
  value       = "http://${module.nomad.fqdn}:4646"
  description = "URL of the Nomad server"
}

output "secondary_consul_url" {
  value       = "http://${module.secondary_consul.fqdn}:8500"
  description = "URL of the Consul server"
}

output "secondary_nomad_url" {
  value       = "http://${module.secondary_nomad.fqdn}:4646"
  description = "URL of the Nomad server"
}

output "nomad_join" {
  value       = <<EOF
gcloud compute ssh ${module.secondary_nomad.names[0]} --zone ${data.google_compute_zones.secondary.names[0]} --tunnel-through-iap -- "nomad server join ${module.nomad.internal_server_ips[0]}; nomad server members"
EOF
  description = "Nomad join command"
}

output "env_vars" {
  value = <<EOF
export CONSUL_HTTP_ADDR=${module.consul.fqdn}:8500
export NOMAD_ADDR=http://${module.nomad.fqdn}:4646
EOF
  description = "Environment variables for Consul and Nomad"
}