resource "nomad_variable" "traefik_consul_token" {
  path = "nomad/jobs/traefik"
  
  items = {
    consul_token = var.consul_token 
  }
}

resource "nomad_job" "traefik" {
  jobspec = templatefile("${path.module}/traefik.nomad.tpl",  {
    dummy = "dummy"
  })

  depends_on = [ nomad_variable.traefik_consul_token ]
}

resource "nomad_job" "loki_gateway" {
  jobspec = templatefile("${path.module}/loki_gateway.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${local.project_id}.${var.dns_zone}"
  })

  depends_on = [ nomad_job.traefik
                ,nomad_variable.loki_gcs
                ,google_storage_bucket.loki
                ,nomad_variable.loki_gcs_key ]
}
resource "nomad_job" "alloy" {
  jobspec = templatefile("${path.module}/alloy.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${local.project_id}.${var.dns_zone}"
  })

  depends_on = [  nomad_job.traefik
                 ,nomad_job.loki_gateway ]
}

resource "nomad_job" "grafana" {
  jobspec = templatefile("${path.module}/grafana.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${local.project_id}.${var.dns_zone}"
  })

  depends_on = [  nomad_job.traefik
                 ,nomad_job.alloy ]
}