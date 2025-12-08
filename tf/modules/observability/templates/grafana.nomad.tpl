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
      }
      
      volume_mount {
        volume      = "grafana_data"
        destination = "/var/lib/grafana"
      }
      
      env {
        GF_SERVER_HTTP_PORT                    = "3000"
        GF_AUTH_ANONYMOUS_ENABLED              = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE             = "Admin"
        GF_SECURITY_ADMIN_PASSWORD             = "admin"
        GF_INSTALL_PLUGINS                     = ""
        GF_SERVER_ENABLE_GZIP                  = "true"
        GF_LOG_LEVEL                           = "warn"
        
        # Database optimizations
        GF_DATABASE_WAL                        = "true"
        GF_DATABASE_CACHE_MODE                 = "shared"
        GF_DATABASE_LOG_QUERIES                = "false"
        
        # Connection and proxy settings
        GF_DATAPROXY_TIMEOUT                   = "60"
        GF_DATAPROXY_KEEP_ALIVE_SECONDS        = "300"
        GF_DATAPROXY_MAX_IDLE_CONNECTIONS      = "100"
        GF_DATAPROXY_IDLE_CONN_TIMEOUT_SECONDS = "90"
        
        # Performance settings
        GF_RENDERING_CONCURRENT_RENDER_LIMIT   = "10"
        GF_DASHBOARDS_MIN_REFRESH_INTERVAL     = "5s"
        
        # Disable unnecessary features
        GF_ANALYTICS_REPORTING_ENABLED         = "false"
        GF_ANALYTICS_CHECK_FOR_UPDATES         = "false"
        GF_QUERY_HISTORY_ENABLED               = "false"
        GF_LIVE_MAX_CONNECTIONS                = "100"
        GF_ALERTING_ENABLED                    = "false"
        GF_UNIFIED_ALERTING_ENABLED            = "false"
      }
      
      template {
        data = <<EOF
apiVersion: 1
datasources:
  - name: Loki
    type: loki
    access: proxy
    url: http://loki.${host_url_suffix}:3100
    isDefault: true
    editable: true
    jsonData:
      maxLines: 1000
      timeout: 60
      queryTimeout: "60s"
      httpHeaderName1: "X-Scope-OrgID"
    secureJsonData:
      httpHeaderValue1: "tenant1"
EOF
        destination = "local/provisioning/datasources/datasources.yaml"
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