job "gateway" {
  datacenters = ["dc1"]
  type        = "service"

  update {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    auto_revert      = true
  }

  group "gateway" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "5m"
      mode     = "fail"
    }

    network {
      port "ui" {
        to = 12345
      }
 
      port "loki" {
        static = 12346
      }
    }

    task "gateway" {
      driver = "docker"

      config {
        image = "grafana/alloy:v1.11.3"
        ports = ["ui", "loki"]
        args  = [
          "run",
          "--server.http.listen-addr=0.0.0.0:12345",
          "--storage.path=/var/lib/alloy/data",
          "/local/config.alloy",
        ]
      }

      template {
        data = <<EOF
logging {
  level  = "info"
  format = "logfmt"
}

loki.source.api "agents" {
  http {
    listen_address = "0.0.0.0"
    listen_port    = 12346
  }
  
  forward_to = [loki.write.loki_local.receiver]
}

loki.write "loki_local" {
  endpoint {
    url = "http://loki.${host_url_suffix}:8080/loki/api/v1/push"
    
    batch_wait          = "1s"
    batch_size          = "100KiB"
    max_backoff_retries = 10
  }
  
  external_labels = {
    source = "alloy-gateway",
  }
}
EOF
        destination = "local/config.alloy"
        change_mode = "restart"
      }

      resources {
        cpu    = 300
        memory = 512
      }

      service {
        name = "gateway"
        port = "loki"
        
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.gateway.rule=Host(`gateway.${host_url_suffix}`) && PathPrefix(`/loki/api/v1/push`)",
          "traefik.http.routers.gateway.entrypoints=http",
          "traefik.http.services.gateway.loadbalancer.server.port=12346",
        ]

        check {
          type     = "http"
          port     = "ui"
          path     = "/-/ready"
          interval = "10s"
          timeout  = "5s"
        }
      }
    }
  }
}