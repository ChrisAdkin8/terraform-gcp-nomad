resource "nomad_variable" "traefik_consul_token" {
  path = "nomad/jobs/traefik"
  
  items = {
    consul_token = var.consul_token
  }
}

resource "nomad_job" "traefik" {
  jobspec = file("${path.module}/templates/traefik.nomad.tpl")

  depends_on = [
    nomad_variable.traefik_consul_token
  ]
}

resource "nomad_job" "loki" {
  jobspec = templatefile("${path.module}/templates/loki.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${var.project_id}.${var.base_domain}"
  })

  depends_on = [ 
    nomad_job.traefik,
    nomad_variable.loki_gcs,
    google_storage_bucket.loki
  ]
}

resource "terraform_data" "loki_ready" {
  depends_on = [
    nomad_job.loki
  ]
}

resource "null_resource" "wait_for_loki" {
  depends_on = [nomad_job.loki]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for Loki to be healthy..."
      for i in $(seq 1 60); do
        if curl -sf "http://loki.traefik-${var.data_center}.${var.project_id}.${var.base_domain}:8080/ready" > /dev/null 2>&1; then
          echo "Loki is ready!"
          exit 0
        fi
        echo "Attempt $i/60 - Loki not ready, waiting 10s..."
        sleep 10
      done
      echo "Loki failed to become healthy"
      exit 1
    EOT
  }
}

resource "nomad_job" "gateway" {
  jobspec = templatefile("${path.module}/templates/gateway.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${var.project_id}.${var.base_domain}"
  })

  depends_on = [
    null_resource.wait_for_loki,
    nomad_job.traefik
  ]
}

resource "nomad_job" "collector" {
  jobspec = templatefile("${path.module}/templates/collector.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${var.project_id}.${var.base_domain}"
  })

  depends_on = [
    nomad_job.traefik,
    nomad_job.gateway
  ]
}

resource "nomad_variable" "grafana_admin_password" {
  path = "nomad/jobs/grafana"

  items = {
    admin_password = random_password.grafana_admin.result
  }
}

resource "nomad_job" "grafana" {
  jobspec = templatefile("${path.module}/templates/grafana.nomad.tpl",  {
    host_url_suffix = "traefik-${var.data_center}.${var.project_id}.${var.base_domain}"
  })

  depends_on = [
    nomad_job.traefik,
    nomad_job.collector,
    nomad_variable.grafana_admin_password
  ]
}