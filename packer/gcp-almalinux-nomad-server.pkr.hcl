packer {
  required_plugins {
    googlecompute = {
      source  = "github.com/hashicorp/googlecompute"
      version = "~> 1"
    }
  }
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "europe-west1"
}

variable "gcp_zone" {
  type    = string
  default = "europe-west1-b"
}

variable "nomad_version" {
  type    = string
  default = "1.10.5+ent"
}

variable "image_family" {
  type    = string
  default = "almalinux-8"
}

source "googlecompute" "almalinux-nomad-server" {
  project_id          = var.gcp_project_id
  region              = var.gcp_region
  zone                = var.gcp_zone
  source_image_family = var.image_family
  machine_type        = "e2-medium"
  image_name          = "almalinux-nomad-server-{{timestamp}}"
  image_family        = "almalinux-nomad-server"
  disk_size           = 20
  disk_type           = "pd-standard"
  ssh_username        = "packer"
  tags                = ["nomad-server"]
}

build {
  sources = ["source.googlecompute.almalinux-nomad-server"]

  provisioner "file" {
    source = "./packer/configs/nomad-server.hcl"
    destination = "/tmp/nomad.hcl"
  }

  provisioner "file" {
    source = "./packer/configs/consul-client.hcl"
    destination = "/tmp/consul.hcl"
  }

  provisioner "file" {
    source = "./nomad.hclic"
    destination = "/tmp/nomad.hclic"
  }

  provisioner "file" {
    source = "./consul.hclic"
    destination = "/tmp/consul.hclic"
  }

  provisioner "shell" {
    script            = "./packer/scripts/provision-nomad.sh"

    environment_vars = [
      "NOMAD_VERSION=${var.nomad_version}"
    ]
  }
}
