resource "nomad_job" "prometheus" {
  count = 0
  jobspec = templatefile("${path.module}/prometheus.nomad.tpl",  {
    dummy = "dummy"
  })
}

resource "nomad_job" "autoscaler" {
  count = 0
  jobspec = templatefile("${path.module}/autoscaler.nomad.tpl",  {
    nomad_address = var.nomad_addr
  })
}

resource "nomad_job" "hashicups" {
  count = 0
  jobspec = templatefile("${path.module}/hashicups.nomad.tpl",  {
    dummy = "dummy"
  })
}
resource "nomad_job" "traefik" {
  jobspec = templatefile("${path.module}/traefik.nomad.tpl",  {
    dummy = "dummy"
  })
}
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "nomad_job" "minio" {
  jobspec = templatefile("${path.module}/minio.nomad.tpl",  {
    minio_root_password = random_password.password.result
  })

  depends_on = [ nomad_job.traefik ]
}