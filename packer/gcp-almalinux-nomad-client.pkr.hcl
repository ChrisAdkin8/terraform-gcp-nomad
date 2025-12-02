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

source "googlecompute" "almalinux-nomad-client" {
  project_id          = var.gcp_project_id
  region              = var.gcp_region
  zone                = var.gcp_zone
  source_image_family = var.image_family
  machine_type        = "e2-medium"
  image_name          = "almalinux-nomad-client-{{timestamp}}"
  image_family        = "almalinux-nomad-client"
  disk_size           = 20
  disk_type           = "pd-standard"
  ssh_username        = "packer"
  tags                = ["nomad-client"]
}

build {
  sources = ["source.googlecompute.almalinux-nomad-client"]

  provisioner "file" {
    source = "./packer/configs/nomad-client.hcl"
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

  provisioner "shell" {
    execute_command = "sudo -E -S bash {{.Path}}"
    script            = "./packer/scripts/provision-nomad-client.sh"
  }
}
