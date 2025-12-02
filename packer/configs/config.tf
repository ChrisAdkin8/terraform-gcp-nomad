locals {
  bootstrap_token = uuid()
}

data "external" "gcloud_project" {
  program = ["bash", "-c", "echo {\\\"project\\\": \\\"$(gcloud config get-value project)\\\"}"]
}

resource "local_file" "consul_server_config" {
  filename = "${path.module}/consul-server.hcl"
  content  = templatefile("${path.module}/consul-server.hcl.tmpl", {
    initial_management_token = local.bootstrap_token
    agent_token              = local.bootstrap_token
  })
}
resource "local_file" "consul_client_config" {
  filename = "${path.module}/consul-client.hcl"
  content  = templatefile("${path.module}/consul-client.hcl.tmpl", {
    agent_token              = local.bootstrap_token
  })
}

resource "local_file" "nomad_client_config" {
  filename = "${path.module}/nomad-client.hcl"
  content  = templatefile("${path.module}/nomad-client.hcl.tmpl", {
    initial_management_token = local.bootstrap_token
  })
}
resource "local_file" "nomad_server_config" {
  filename = "${path.module}/nomad-server.hcl"
  content  = templatefile("${path.module}/nomad-server.hcl.tmpl", {
    initial_management_token = local.bootstrap_token
  })
}

resource "local_file" "tfvars" {
  filename = "${path.module}/terraform.tfvars"
  content  = templatefile("${path.module}/terraform.tfvars.tmpl", {
    project_id      = data.external.gcloud_project.result.project
    bootstrap_token = local.bootstrap_token
  })

  provisioner "local-exec" {
    command = <<EOT
      rm -rf ../../tf/terraform.tfvars
      mv terraform.tfvars ../../tf/.
    EOT
  }
} 

resource "local_file" "pkvars" {
  filename = "${path.module}/variables.pkrvars.hcl"
  content  = templatefile("${path.module}/variables.pkvars.hcl.tmpl", {
    project_id      = data.external.gcloud_project.result.project
  })

  provisioner "local-exec" {
    command = <<EOT
      rm -rf ../variables.pkrvars.hcl
      mv variables.pkrvars.hcl ../.
    EOT
  }
} 