# #----------------------------------------------------------------------------------------------
# # Firewall Rules
# #----------------------------------------------------------------------------------------------
# data "google_netblock_ip_ranges" "iap" {
#   range_type = "iap-forwarders"
# }
#
# resource "google_compute_firewall" "iap_ssh" {
#   name          = "${local.name_prefix}-iap-ssh"
#   network       = google_compute_network.default.name
#   direction     = "INGRESS"
#   source_ranges = data.google_netblock_ip_ranges.iap.cidr_blocks
#   target_tags   = ["consul-server", "nomad-server", "nomad-client"]
#
#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }
# }
#
# resource "google_compute_firewall" "consul_mgmt" {
#   name    = "${local.name_prefix}-consul-mgmt-ingress"
#   network = google_compute_network.default.name
#
#   allow {
#     protocol = "tcp"
#     ports    = ["8500"]
#   }
#
#   source_ranges = [local.mgmt_cidr]
#
#   target_tags = ["consul-server"]
# }
#
# # resource "google_compute_firewall" "consul_server" {
# #   name    = "${local.name_prefix}-consul-server-ingress"
# #   network = google_compute_network.default.name
# #
# #   allow {
# #     protocol = "tcp"
# #     ports    = ["8500", "8301"]
# #   }
# #
# #   source_ranges = [google_compute_subnetwork.default.ip_cidr_range]
# #
# #   target_tags = ["consul-server"]
# # }
#
#
# resource "google_compute_firewall" "nomad_mgmt" {
#   name    = "${local.name_prefix}-nomad-mgmt-ingress"
#   network = google_compute_network.default.name
#
#   allow {
#     protocol = "tcp"
#     ports    = ["4646"]
#   }
#
#   source_ranges = [local.mgmt_cidr]
#
#   target_tags = ["nomad-server"]
# }
#
# # resource "google_compute_firewall" "nomad_server" {
# #   name    = "${local.name_prefix}-nomad-server-ingress"
# #   network = google_compute_network.default.name
# #
# #   allow {
# #     protocol = "tcp"
# #     ports    = ["4646"]
# #   }
# #
# #   source_ranges = [google_compute_subnetwork.default.ip_cidr_range]
# #
# #   target_tags = ["nomad-server"]
# # }
#
# resource "google_compute_firewall" "nomad_consul" {
#   name    = "${local.name_prefix}-nomad-consul-ingress"
#   network = google_compute_network.default.name
#
#   allow {
#     protocol = "icmp"
#   }
#
#   allow {
#     protocol = "tcp"
#     ports = [
#       "4646",
#       "4647",
#       "4648",
#       "8500",
#       "8501",
#       "8502",
#       "8503",
#       "8600",
#       "8300",
#       "8301",
#       "8302",
#     ]
#   }
#
#   allow {
#     protocol = "udp"
#     ports = [
#       "4648",
#       "8301",
#       "8302",
#       "8600",
#     ]
#   }
#
#   source_tags = [
#     "nomad-server",
#     "nomad-client",
#     "consul-server",
#   ]
#
#   target_tags = [
#     "nomad-server",
#     "consul-server",
#   ]
# }
#
# resource "google_compute_firewall" "nomad_client" {
#   name    = "${local.name_prefix}-nomad-client-ingress"
#   network = google_compute_network.default.name
#
#   allow {
#     protocol = "icmp"
#   }
#
#   allow {
#     protocol = "tcp"
#     ports = [
#       "4647",
#       "8301",
#     ]
#   }
#
#   source_tags = [
#     "nomad-server",
#     "nomad-client",
#   ]
#
#   target_tags = [
#     "nomad-client",
#   ]
# }