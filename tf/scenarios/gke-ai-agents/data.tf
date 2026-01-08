data "google_client_config" "current" {}

data "google_compute_zones" "default" {
  region  = var.region
  project = local.project_id
  status  = "UP"
}

data "http" "mgmt_ip" {
  url = "https://ipv4.icanhazip.com"
  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Failed to get remote IP"
    }
  }
}

data "external" "base_domain" {
  program = [
    "bash", "-c",
    "zone=$(gcloud dns managed-zones list --format='value(dnsName)' --limit=1 | awk -F. '{print $(NF-4)\".\"$(NF-3)\".\"$(NF-2)\".\"$(NF-1)}'); echo \"{\\\"domain\\\": \\\"$zone\\\"}\""
  ]
}
