resource "nomad_job" "prometheus" {
  jobspec = templatefile("${path.module}/prometheus.nomad.tpl",  {
    dummy = "dummy"
  })
}

resource "nomad_job" "autoscaler" {
  jobspec = templatefile("${path.module}/autoscaler.nomad.tpl",  {
    nomad_address = var.nomad_addr
  })
}

resource "nomad_job" "hashicups" {
  jobspec = templatefile("${path.module}/hashicups.nomad.tpl",  {
    dummy = "dummy"
  })
}
resource "nomad_job" "traefik" {
  jobspec = templatefile("${path.module}/traefik.nomad.tpl",  {
    dummy = "dummy"
  })
}
resource "nomad_job" "minio" {
  jobspec = templatefile("${path.module}/minio.nomad.tpl",  {
    dummy = "dummy"
  })
}