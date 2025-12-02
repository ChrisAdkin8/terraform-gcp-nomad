locals {
  nomad_server_metadata = {
    DATACENTER = var.datacenter
    GCS_BUCKET = var.gcs_bucket
    NOMAD_ROLE = "server"
    REGION     = var.region
  }
  nomad_client_metadata = {
    DATACENTER = var.datacenter
    GCS_BUCKET = var.gcs_bucket
    NOMAD_ROLE = "client"
    REGION     = var.region
  }
}

# -------------------Nomad Server-------------------
resource "google_compute_instance" "nomad_servers" {
  count                   = var.create_nomad_cluster ? var.nomad_server_instances : 0
  name                    = "${var.name_prefix}-nomad-server-${count.index + 1}"
  machine_type            = "e2-medium"
  metadata_startup_script = templatefile("${path.module}/templates/nomad-startup.sh", local.nomad_server_metadata)
  zone                    = var.zone

  tags = ["nomad-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.almalinux_nomad_server.self_link
      size  = 20
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link
    access_config {
      // Required to give instances external IPs
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  scheduling {
    automatic_restart = true
    preemptible       = false
  }

  service_account {
    email  = google_service_account.default.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
  lifecycle {
    ignore_changes = [
      boot_disk[0].initialize_params[0].image,
    ]
  }
}
