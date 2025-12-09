resource "local_file" "smoke_test" {
  filename = "${path.module}/smoke_test.sh"
  content  = templatefile("${path.module}/templates/smoke_test.sh.tpl", {
    host_url_suffix = "traefik-${var.data_center}.${local.project_id}.${var.base_domain}"
  })
}