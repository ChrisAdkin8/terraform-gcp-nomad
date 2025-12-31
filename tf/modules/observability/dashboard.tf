resource "null_resource" "wait_for_grafana" {
  provisioner "local-exec" {
    command = <<-EOF
      for i in $(seq 1 30); do
        if curl -sf -u admin:admin ${local.grafana_url}/api/health > /dev/null 2>&1; then
          echo "Grafana is ready"
          exit 0
        fi
        echo "Waiting for Grafana... attempt $i/30"
        sleep 10
      done
      echo "Grafana failed to become ready"
      exit 1
    EOF
  }
  
  depends_on = [ nomad_job.grafana ]
}

resource "grafana_dashboard" "from_json" {
  config_json = file("${path.module}/dashboards/nomad-logs-dashboard.json")
  folder      = local.folder_id
  overwrite   = true

  depends_on = [ null_resource.wait_for_grafana ]
}