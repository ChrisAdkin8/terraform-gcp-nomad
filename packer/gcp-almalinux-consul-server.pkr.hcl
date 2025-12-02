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

variable "image_family" {
  type    = string
  default = "almalinux-8"
}

source "googlecompute" "almalinux-consul-server" {
  project_id          = var.gcp_project_id
  region              = var.gcp_region
  zone                = var.gcp_zone
  source_image_family = var.image_family
  machine_type        = "e2-medium"
  image_name          = "almalinux-consul-server-{{timestamp}}"
  image_family        = "almalinux-consul-server"
  disk_size           = 20
  disk_type           = "pd-standard"
  ssh_username        = "packer"
  tags                = ["consul-server"]
}

build {
  sources = ["source.googlecompute.almalinux-consul-server"]

  provisioner "file" {
    source = "./packer/configs/consul-server.hcl"
    destination = "/tmp/consul.hcl"
  }

  provisioner "file" {
    source = "./consul.hclic"
    destination = "/tmp/consul.hclic"
  }

  provisioner "shell" {
    script            = "./packer/scripts/provision-consul.sh"
  }
}
