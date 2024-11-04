# resource "google_compute_instance_group" "nomad_server" {
#     count = ! var.create_nomad_cluster ? 0 : var.nomad_server_instances
#
#     name               = "${var.name_prefix}-nomad-server-${count.index + 1}"
#     zone               = var.zone
#     instances = [google_compute_instance.nomad_server[count.index].self_link]
# }
#
# resource "google_compute_region_group_manager" "nomad_server" {
#   count = var.create_nomad_cluster ? 1 : 0
#
#   name               = "${var.name_prefix}-nomad-client"
#   base_instance_name = "${var.name_prefix}-nomad-client"
#   region             = var.region
#   target_size        = var.nomad_client_instances
#   target_pools       = google_compute_target_pool.nomad_client[*].id
#
#   version {
#     name              = "${var.name_prefix}-nomad-client"
#     instance_template = google_compute_instance_template.nomad_client[0].id
#   }
# }
