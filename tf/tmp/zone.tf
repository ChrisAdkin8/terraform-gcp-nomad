data "external" "dns_zone" {
  program = [
    "bash", "-c",
    "zone=$(gcloud dns managed-zones list --format='value(dnsName)' --limit=1 | awk -F. '{print $(NF-4)\".\"$(NF-3)\".\"$(NF-2)\".\"$(NF-1)}'); echo \"{\\\"domain\\\": \\\"$zone\\\"}\""
  ]
}

locals {
  base_domain = data.external.dns_zone.result.domain
}

output "managed_dns_zone" {
  value = local.base_domain
}
