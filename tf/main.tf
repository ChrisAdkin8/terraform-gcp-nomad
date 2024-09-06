# -------------------Server-------------------
resource "google_compute_instance" "nomad_servers" {
  count         = var.server_instance_count
  name          = "nomad-server-${count.index + 1}"
  machine_type  = "e2-medium"
  zone          = "${var.gcp_region}-a"

  tags          = ["nomad-server"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.almalinux_nomad_server.self_link
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Required to give instances external IPs
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# -------------------Client-------------------
resource "google_compute_instance" "nomad_client" {
  count         = var.client_instance_count
  name          = "nomad-client-${count.index + 1}"
  machine_type  = "e2-medium"
  zone          = "${var.gcp_region}-a"

  tags          = ["nomad-client"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.almalinux_nomad_client.self_link
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Required to give instances external IPs
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# -------------------Data-------------------
data "google_compute_image" "almalinux_nomad_server" {
  family  = "almalinux-nomad-server"
  project = var.gcp_project_id
}

data "google_compute_image" "almalinux_nomad_client" {
  family  = "almalinux-nomad-client"
  project = var.gcp_project_id
}