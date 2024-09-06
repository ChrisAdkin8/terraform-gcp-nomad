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
  default = "europe-west2"
}

variable "gcp_zone" {
  type    = string
  default = "europe-west2-a"
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
  image_name          = "almalinux-nomad-sever-{{timestamp}}"
  image_family        = "almalinux-nomad-server"
  disk_size           = 20
  disk_type           = "pd-standard"
  ssh_username        = "packer"
  tags                = ["nomad-server"]
}

build {
  sources = ["source.googlecompute.almalinux-nomad-server"]

  provisioner "file" {
    source = "./packer/configs/server.hcl"
    destination = "/tmp/nomad.hcl"
  }

  provisioner "file" {
    source = "./nomad.hclic"
    destination = "/tmp/license.hclic"
  }

  provisioner "shell" {
    script            = "./packer/scripts/provision-nomad.sh"
  }
}