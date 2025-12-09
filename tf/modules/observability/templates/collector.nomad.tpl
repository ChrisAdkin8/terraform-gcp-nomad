job "collector" {
  datacenters = ["dc1"]
  type        = "system"

  update {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "15s"
    healthy_deadline = "5m"
    auto_revert      = true
    stagger          = "30s"
  }

  group "agent" {
    network {
      port "http" {
        to = 12345
      }
    }

    restart {
      attempts = 3
      delay    = "15s"
      interval = "5m"
      mode     = "fail"
    }

    volume "alloy_data" {
      type            = "host"
      source          = "alloy"
      access_mode     = "single-node-single-writer"
      attachment_mode = "file-system"
    }

    task "alloy" {
      driver = "docker"
      user   = "root"

      config {
        image        = "grafana/alloy:v1.11.3"
        ports        = ["http"]
        network_mode = "host"

        args  = [
          "run",
          "--server.http.listen-addr=0.0.0.0:12345",
          "--storage.path=/var/lib/alloy/data",
          "--disable-reporting=true",
          "/local/config.alloy",
        ]
        
        logging {
          type = "json-file"
          config {
            max-size = "10m"
            max-file = "3"
          }
        }
      }

      volume_mount {
        volume      = "alloy_data"
        destination = "/var/lib/alloy/data"
      }

      template {
        data = <<EOF
logging {
  level  = "info"
  format = "logfmt"
}

local.file_match "nomad_alloc_logs" {
  path_targets = [{
    __path__ = "/opt/nomad/alloc/*/alloc/logs/*.std{out,err}.*",
  }]
  
  sync_period = "30s"
}

discovery.relabel "alloc_logs" {
  targets = local.file_match.nomad_alloc_logs.targets
  
  // Extract allocation ID from path
  rule {
    source_labels = ["__path__"]
    regex         = "/opt/nomad/alloc/([^/]+)/.*"
    target_label  = "alloc_id"
  }
  
  // Extract task name from path
  rule {
    source_labels = ["__path__"]
    regex         = ".*/logs/([^.]+)\\.std.*"
    target_label  = "task"
  }
  
  // Extract log type (stdout/stderr)
  rule {
    source_labels = ["__path__"]
    regex         = ".*\\.(stdout|stderr)\\..*"
    target_label  = "stream"
  }
}

loki.source.file "nomad_allocs" {
  targets    = discovery.relabel.alloc_logs.output
  forward_to = [loki.process.alloc_logs.receiver]
  
  tail_from_end = false
}

loki.process "alloc_logs" {
  forward_to = [loki.write.gateway.receiver]
  
  stage.static_labels {
    values = {
      source     = "nomad-alloc",
      node_name  = env("node.unique.name"),
      datacenter = env("NOMAD_DC"),
      cluster    = "nomad-dc1",
    }
  }
  
  // Parse JSON logs if present
  stage.match {
    selector = "{source=\"nomad-alloc\"}"
    
    stage.json {
      expressions = {
        level     = "level",
        msg       = "msg",
        timestamp = "timestamp",
      }
    }
    
    stage.labels {
      values = {
        level = "",
      }
    }
  }
}

loki.write "gateway" {
  endpoint {
    url = "http://gateway.${host_url_suffix}:8080/loki/api/v1/push"
    
    // Optimized batching
    batch_wait          = "1s"
    batch_size          = "100KiB"

    // Retry configuration
    max_backoff_retries = 10
  }
  
  external_labels = {
    cluster = "nomad-dc1",
  }
}
EOF
        destination = "local/config.alloy"
        change_mode = "restart"
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      service {
        name = "collector"
        port = "http"

        tags = [
          "alloy-agent"
        ]

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "30s"
          timeout  = "5s"
        }
      }
    }
  }
}