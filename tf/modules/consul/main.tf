locals {
  consul_server_metadata = {
    DATACENTER = var.datacenter
    GCS_BUCKET = var.gcs_bucket
    REGION     = var.region
  }
}

resource "google_compute_instance" "consul_servers" {
  count                   = var.consul_server_instances
  name                    = "${var.name_prefix}-consul-server-${count.index + 1}"
  machine_type            = "e2-medium"
  metadata_startup_script = templatefile("${path.module}/templates/consul-server-startup.sh", local.consul_server_metadata)
  zone                    = var.zone

  tags = ["consul-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.almalinux_consul_server.self_link
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
    automatic_restart = false
    preemptible       = true
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
