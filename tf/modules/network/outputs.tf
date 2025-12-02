output "name" {
  value = google_compute_network.default.name
}

output "subnet_self_link" {
  value = google_compute_subnetwork.default.self_link
}

output "secondary_subnet_self_link" {
  value = google_compute_subnetwork.secondary.self_link
}