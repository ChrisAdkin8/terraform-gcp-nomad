resource "null_resource" "autoscaler" {
  provisioner "local-exec" {
    command = "export NOMAD_ADDR=$NA && nomad job run -detach hashicups.nomad.hcl"
  
    environment = {
        NA = "http://${module.nomad.fqdn}:4646"
    }
  }
  
  depends_on = [ null_resource.autoscaler ]
}