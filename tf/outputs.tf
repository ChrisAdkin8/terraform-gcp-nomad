output "cluster_summary" {
  value = join("\n", [
    "### Primary Cluster Endpoints & Details    ###",
    "----------------------------------------------",
    "Nomad Management Console   : http://${module.nomad.fqdn}:4646",
    "Consul Management Console  : http://${module.consul.fqdn}:8500",
    "Traefik Management Console : http://${module.nomad.traefik_ui_ip}:8081",
    "Traefik API                : http://${module.nomad.traefik_api_ip}:8080",
    "Grafana Management Console : http://grafana.traefik-dc1.${local.project_id}.${local.base_domain}:8080",
    "Alloy Gateway API Endpoint : http://gateway-api.traefik-dc1.${local.project_id}.${local.base_domain}:8080",
    "Alloy Gateway UI Endpoint  : http://gateway-ui.traefik-dc1.${local.project_id}.${local.base_domain}:8080",
    "Loki Endpoint              : http://loki.traefik-dc1.${local.project_id}.${local.base_domain}:8080",
    "",
    "Nomad Server External IPs  : ${join(", ", module.nomad.external_server_ips)}",
    "Nomad Server Internal IPs  : ${join(", ", module.nomad.internal_server_ips)}",
    "Consul Server External IPs : ${join(", ", module.consul.external_server_ips)}",
    "Consul Server Internal IPs : ${join(", ", module.consul.internal_server_ips)}",
    "",
    "### Secondary Cluster Endpointds & Details ###",
    "----------------------------------------------",
    var.create_secondary_nomad_cluster  ? "Nomad Management Console  : http://${module.secondary_nomad.fqdn}:4646" : "Nomad Management Console  : (Not created)",
    var.create_secondary_consul_cluster ? "Consul Management Console : http://${module.secondary_consul.fqdn}:8500" : "Consul Management Console  : (Not created)",
    "",    
    "Nomad Server External IPs : ${join(", ", module.secondary_nomad.external_server_ips)}",
    "Consul Server External IPs: ${join(", ", module.secondary_consul.external_server_ips)}",
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

output "dns_managed_zone" {
  value = data.google_compute_zones.default.names[0]
}