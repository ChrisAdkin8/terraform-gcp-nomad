data "google_project" "default" {}

data "google_compute_zones" "default" {
  region = var.region
  status = "UP"
}

data "google_compute_zones" "secondary" {
  region = var.secondary_region
  status = "UP"
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

