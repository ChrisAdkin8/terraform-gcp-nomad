# # -------------------Client-------------------
resource "google_compute_instance_template" "nomad_client" {
  count = var.create_nomad_cluster ? 1 : 0

  name_prefix             = "${var.name_prefix}-nomad-client-"
  machine_type            = var.nomad_client_machine_type
  metadata_startup_script = templatefile("${path.module}/templates/nomad-startup.sh", local.nomad_client_metadata)
  tags                    = ["nomad-client"]
  labels                  = merge(var.labels, { role = "nomad-client" })

  disk {
    source_image = data.google_compute_image.almalinux_nomad_client.self_link
    disk_size_gb = var.nomad_client_disk_size
    auto_delete  = true
    boot         = true
    labels       = var.labels
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  scheduling {
    automatic_restart = false
    preemptible       = true
  }

  network_interface {
    subnetwork         = var.subnet_self_link
    subnetwork_project = local.project_id
  }

  service_account {
    email  = google_service_account.default.email
    scopes = [
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      disk[0].source_image,
    ]
  }

  depends_on = [
    google_compute_instance.nomad_servers
  ]
}

resource "google_compute_region_instance_group_manager" "nomad_client" {
  count = var.create_nomad_cluster ? 1 : 0

  name               = "${var.name_prefix}-nomad-client"
  base_instance_name = "${var.name_prefix}-nomad-client"
  region             = var.region
  target_size        = var.nomad_client_instances

  named_port {
    name = "traefikapi"
    port = 8080
  }
  named_port {
    name = "traefikui"
    port = 8081
  } 

  version {
    name              = "${var.name_prefix}-nomad-client"
    instance_template = google_compute_instance_template.nomad_client[0].id
  }
}
