data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

# Create a specific firewall rule for this run
resource "google_compute_firewall" "temp_consul_access" {
  name    = "allow-temp-consul-access"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8500", "80"]
  }

  # Restrict source to ONLY your current IP
  source_ranges = ["${chomp(data.http.myip.response_body)}/32"]
  target_tags   = ["consul-server"]
}