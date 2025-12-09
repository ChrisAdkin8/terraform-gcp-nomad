resource "nomad_variable" "traefik_consul_token" {
  path = "nomad/jobs/traefik"
  
  items = {
    consul_token = var.consul_token 
  }
}

resource "nomad_job" "traefik" {
  jobspec = templatefile("${path.module}/templates/traefik.nomad.tpl",  {
    dummy = "dummy"
  })

  depends_on = [ nomad_variable.traefik_consul_token ]
}

resource "nomad_job" "loki" {
  jobspec = templatefile("${path.module}/templates/loki.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${local.project_id}.${var.base_domain}"
  })

  depends_on = [ nomad_job.traefik
                ,nomad_variable.loki_gcs
                ,google_storage_bucket.loki
                ,nomad_variable.loki_gcs_key ]
}

resource "terraform_data" "loki_ready" {
  depends_on = [nomad_job.loki]
}

data "http" "loki_health" {
  url = "http://loki.traefik-${var.data_center}.${local.project_id}.${var.base_domain}:8080/ready"

  retry {
    attempts     = 30
    min_delay_ms = 5000
    max_delay_ms = 10000
  }

  depends_on = [terraform_data.loki_ready]
}

resource "nomad_job" "gateway" {
  jobspec = templatefile("${path.module}/templates/gateway.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${local.project_id}.${var.base_domain}"
  })

  depends_on = [ nomad_job.traefik
                ,data.http.loki_health ]
}

resource "nomad_job" "collector" {
  jobspec = templatefile("${path.module}/templates/collector.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${local.project_id}.${var.base_domain}"
  })

  depends_on = [  nomad_job.traefik
                 ,nomad_job.gateway ]
}

resource "nomad_job" "grafana" {
  jobspec = templatefile("${path.module}/templates/grafana.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${local.project_id}.${var.base_domain}"
  })

  depends_on = [  nomad_job.traefik
                 ,nomad_job.collector ]
}