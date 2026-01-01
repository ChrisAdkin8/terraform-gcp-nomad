job "grafana" {
  datacenters = ["dc1"]
  type        = "service"

  group "monitoring" {
    count = 1

    restart {
      attempts = 3
      delay    = "30s"
      interval = "5m"
      mode     = "fail"
    }

    network {
      port "grafana" {
        static = 3000
      }
    }

    volume "grafana_data" {
      type            = "host"
      source          = "grafana"
      access_mode     = "single-node-single-writer"
      attachment_mode = "file-system"
    }

    task "grafana" {
      driver = "docker"
      user   = "root"

      config {
        image = "grafana/grafana:10.2.3"
        ports = ["grafana"]
        volumes = [
          "local/provisioning:/etc/grafana/provisioning",
        ]
      }

      volume_mount {
        volume      = "grafana_data"
        destination = "/var/lib/grafana"
      }

      env {
        GF_SERVER_HTTP_PORT                    = "3000"
        GF_AUTH_ANONYMOUS_ENABLED              = "false"
        GF_INSTALL_PLUGINS                     = ""
        GF_SERVER_ENABLE_GZIP                  = "true"
        GF_LOG_LEVEL                           = "warn"

        GF_DATABASE_WAL                        = "true"
        GF_DATABASE_CACHE_MODE                 = "shared"
        GF_DATABASE_LOG_QUERIES                = "false"

        GF_DATAPROXY_TIMEOUT                   = "120"
        GF_DATAPROXY_KEEP_ALIVE_SECONDS        = "300"
        GF_DATAPROXY_MAX_IDLE_CONNECTIONS      = "100"
        GF_DATAPROXY_IDLE_CONN_TIMEOUT_SECONDS = "90"

        GF_RENDERING_CONCURRENT_RENDER_LIMIT   = "10"
        GF_DASHBOARDS_MIN_REFRESH_INTERVAL     = "5s"

        GF_ANALYTICS_REPORTING_ENABLED         = "false"
        GF_ANALYTICS_CHECK_FOR_UPDATES         = "false"
        GF_QUERY_HISTORY_ENABLED               = "false"
        GF_LIVE_MAX_CONNECTIONS                = "100"
        GF_ALERTING_ENABLED                    = "false"
        GF_UNIFIED_ALERTING_ENABLED            = "false"
      }

      # Admin password from Nomad variable (secure)
      template {
        data        = <<EOF
{{ with nomadVar "nomad/jobs/grafana" }}
GF_SECURITY_ADMIN_PASSWORD={{ .admin_password }}
{{ end }}
EOF
        destination = "secrets/grafana.env"
        env         = true
      }

      template {
        data = <<EOF
apiVersion: 1
datasources:
  - name: Loki
    type: loki
    uid: loki
    access: proxy
    url: http://loki.${host_url_suffix}:8080
    isDefault: true
    editable: true
    jsonData:
      maxLines: 1000
      timeout: 120
      queryTimeout: "120s"
      httpHeaderName1: "X-Scope-OrgID"
    secureJsonData:
      httpHeaderValue1: "tenant1"
EOF
        destination = "local/provisioning/datasources/datasources.yaml"
        change_mode = "restart"
      }

      template {
        data = <<EOF
apiVersion: 1
providers:
  - name: 'Nomad Dashboards'
    orgId: 1
    folder: 'Nomad'
    folderUid: 'nomad-folder'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF
        destination = "local/provisioning/dashboards/dashboards.yaml"
        change_mode = "restart"
      }

      template {
        data = <<EOF
apiVersion: 1
apps: []
EOF
        destination = "local/provisioning/plugins/plugins.yaml"
        change_mode = "restart"
      }

      template {
        data = <<EOF
notifiers: []
EOF
        destination = "local/provisioning/notifiers/notifiers.yaml"
        change_mode = "restart"
      }

      template {
        data = <<EOF
apiVersion: 1
groups: []
EOF
        destination = "local/provisioning/alerting/alerting.yaml"
        change_mode = "restart"
      }

      resources {
        cpu    = 2000
        memory = 4096
      }

      service {
        name = "grafana"
        port = "grafana"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.grafana.rule=Host(`grafana.${host_url_suffix}`)",
          "traefik.http.routers.grafana.entrypoints=http",
        ]

        check {
          type     = "http"
          path     = "/api/health"
          interval = "10s"
          timeout  = "5s"
        }
      }
    }
  }
}