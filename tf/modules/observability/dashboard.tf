resource "null_resource" "grafana_dashboard" {
  provisioner "local-exec" {
    command = <<-EOF
      echo "---------------------------------------------------"
      echo "Grafana URL: $GRAFANA_URL"
      echo "---------------------------------------------------"
      for i in $(seq 1 30); do
        if curl -sf -u "$GRAFANA_AUTH" $GRAFANA_URL/api/health > /dev/null 2>&1; then
          echo "Grafana is ready"
          break
        fi
        echo "Waiting for Grafana... attempt $i/30"
        sleep 10
      done

      curl -X POST \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_AUTH" \
        -d "{\"dashboard\": $(cat ${path.module}/nomad-logs-dashboard.json), \"overwrite\": true}" \
        "$GRAFANA_URL/api/dashboards/db"
    EOF

    environment = {
      GRAFANA_URL  = "http://grafana.traefik-${var.data_center}.${var.project_id}.${var.base_domain}:8080"
      GRAFANA_AUTH = "admin:${random_password.grafana_admin.result}"
    }
  }

  depends_on = [
    random_password.grafana_admin,
    nomad_job.grafana
  ]
}