resource "grafana_dashboard" "from_json" {
  config_json = file("${path.module}/dashboards/nomad-logs-dashboard.json")
  folder      = local.folder_id
  overwrite   = true

  depends_on = [ nomad_job.grafana ]
}