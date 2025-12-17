job "collector" {
  datacenters = ["dc1"]
  type        = "system"

  update {
    max_parallel     = 1
    min_healthy_time = "10s"
    healthy_deadline = "5m"
    auto_revert      = true
    stagger          = "30s"
  }

  group "agent" {
    restart {
      attempts = 3
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      mode = "host"
      port "http" { static = 12344 }
    }

    volume "alloy_data" {
      type            = "host"
      source          = "alloy"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-single-writer"
    }

    task "alloy" {
      driver = "docker"

      config {
        image        = "grafana/alloy:v1.11.3"
        ports        = ["http"]
        network_mode = "host"

        args = [
          "run",
          "--server.http.listen-addr=0.0.0.0:12344",
          "--storage.path=/var/lib/alloy/data",
          "local/config.alloy",
        ]

        mount {
          type     = "bind"
          target   = "/opt/nomad/data/alloc"
          source   = "/opt/nomad/data/alloc"
          readonly = true
        }

        mount {
          type     = "bind"
          target   = "/var/log"
          source   = "/var/log"
          readonly = true
        }

        mount {
          type     = "bind"
          target   = "/host/proc"
          source   = "/proc"
          readonly = true
        }

        mount {
          type     = "bind"
          target   = "/host/sys"
          source   = "/sys"
          readonly = true
        }
      }

      volume_mount {
        volume      = "alloy_data"
        destination = "/var/lib/alloy/data"
        read_only   = false
      }

      template {
        destination = "local/config.alloy"
        change_mode = "restart"
        data        = <<-EOH
// ============================================================================
// LOGGING
// ============================================================================

logging {
  level  = "info"
  format = "logfmt"
}

// ============================================================================
// NOMAD SERVICE DISCOVERY
// ============================================================================

discovery.nomad "local" {
  server           = "http://{{ env "attr.unique.network.ip-address" }}:4646"
  region           = "europe-west1"
  namespace        = "*"
  refresh_interval = "30s"
}

// ============================================================================
// NOMAD LOG DISCOVERY - STDOUT
// ============================================================================

discovery.relabel "nomad_stdout" {
  targets = discovery.nomad.local.targets

  // Keep only allocations running on this node
  rule {
    source_labels = ["__meta_nomad_node_id"]
    regex         = "{{ env "node.unique.id" }}"
    action        = "keep"
  }

  // Extract job name
  rule {
    source_labels = ["__meta_nomad_job"]
    target_label  = "job"
  }

  // Extract namespace
  rule {
    source_labels = ["__meta_nomad_namespace"]
    target_label  = "namespace"
  }

  // Extract datacenter
  rule {
    source_labels = ["__meta_nomad_dc"]
    target_label  = "datacenter"
  }

  // Extract task group
  rule {
    source_labels = ["__meta_nomad_group"]
    target_label  = "task_group"
  }

  // Extract task name
  rule {
    source_labels = ["__meta_nomad_task"]
    target_label  = "task"
  }

  // Extract allocation ID
  rule {
    source_labels = ["__meta_nomad_alloc_id"]
    target_label  = "alloc_id"
  }

  // Set stream label to stdout
  rule {
    replacement  = "stdout"
    target_label = "stream"
  }

  // Construct log file path from allocation metadata
  rule {
    source_labels = ["__meta_nomad_alloc_id", "__meta_nomad_task"]
    separator     = ";"
    regex         = "(.+);(.+)"
    replacement   = "/opt/nomad/data/alloc/$1/alloc/logs/$2.stdout.*"
    target_label  = "__path__"
  }

  // Clean up meta labels
  rule {
    action = "labeldrop"
    regex  = "__meta_nomad_.+"
  }
}

// ============================================================================
// NOMAD LOG DISCOVERY - STDERR
// ============================================================================

discovery.relabel "nomad_stderr" {
  targets = discovery.nomad.local.targets

  // Keep only allocations running on this node
  rule {
    source_labels = ["__meta_nomad_node_id"]
    regex         = "{{ env "node.unique.id" }}"
    action        = "keep"
  }

  // Extract job name
  rule {
    source_labels = ["__meta_nomad_job"]
    target_label  = "job"
  }

  // Extract namespace
  rule {
    source_labels = ["__meta_nomad_namespace"]
    target_label  = "namespace"
  }

  // Extract datacenter
  rule {
    source_labels = ["__meta_nomad_dc"]
    target_label  = "datacenter"
  }

  // Extract task group
  rule {
    source_labels = ["__meta_nomad_group"]
    target_label  = "task_group"
  }

  // Extract task name
  rule {
    source_labels = ["__meta_nomad_task"]
    target_label  = "task"
  }

  // Extract allocation ID
  rule {
    source_labels = ["__meta_nomad_alloc_id"]
    target_label  = "alloc_id"
  }

  // Set stream label to stderr
  rule {
    replacement  = "stderr"
    target_label = "stream"
  }

  // Construct log file path from allocation metadata
  rule {
    source_labels = ["__meta_nomad_alloc_id", "__meta_nomad_task"]
    separator     = ";"
    regex         = "(.+);(.+)"
    replacement   = "/opt/nomad/data/alloc/$1/alloc/logs/$2.stderr.*"
    target_label  = "__path__"
  }

  // Clean up meta labels
  rule {
    action = "labeldrop"
    regex  = "__meta_nomad_.+"
  }
}

// ============================================================================
// TAIL NOMAD LOG FILES
// ============================================================================

loki.source.file "nomad_logs" {
  targets = array.concat(
    discovery.relabel.nomad_stdout.output,
    discovery.relabel.nomad_stderr.output,
  )

  forward_to = [loki.process.add_metadata.receiver]
}

// ============================================================================
// ADD ADDITIONAL METADATA
// ============================================================================

loki.process "add_metadata" {
  stage.static_labels {
    values = {
      node   = "{{ env "node.unique.name" }}",
      source = "nomad",
    }
  }

  forward_to = [loki.write.loki.receiver]
}

// ============================================================================
// FALLBACK: CATCH LOGS FROM TASKS WITHOUT SERVICES
// ============================================================================

local.file_match "nomad_logs_fallback" {
  path_targets = [
    {__path__ = "/opt/nomad/data/alloc/*/alloc/logs/*.stdout.[0-9]*"},
    {__path__ = "/opt/nomad/data/alloc/*/alloc/logs/*.stderr.[0-9]*"},
  ]
  sync_period = "60s"
}

loki.source.file "nomad_logs_fallback" {
  targets    = local.file_match.nomad_logs_fallback.targets
  forward_to = [loki.process.fallback_labels.receiver]
}

loki.process "fallback_labels" {
  // Extract labels from file path for tasks without services
  stage.regex {
    expression = "/opt/nomad/data/alloc/(?P<alloc_id>[^/]+)/alloc/logs/(?P<task>[^.]+)\\.(?P<stream>stdout|stderr)\\."
  }

  stage.labels {
    values = {
      alloc_id = "",
      task     = "",
      stream   = "",
    }
  }

  stage.static_labels {
    values = {
      node   = "{{ env "node.unique.name" }}",
      source = "nomad-fallback",
    }
  }

  forward_to = [loki.write.loki.receiver]
}

// ============================================================================
// SYSTEM LOGS (OPTIONAL)
// ============================================================================

local.file_match "system_logs" {
  path_targets = [
    {__path__ = "/var/log/syslog"},
    {__path__ = "/var/log/messages"},
    {__path__ = "/var/log/nomad*.log"},
    {__path__ = "/var/log/consul*.log"},
  ]
}

loki.source.file "system_logs" {
  targets    = local.file_match.system_logs.targets
  forward_to = [loki.process.system_labels.receiver]
}

loki.process "system_labels" {
  stage.static_labels {
    values = {
      node   = "{{ env "node.unique.name" }}",
      source = "system",
    }
  }

  forward_to = [loki.write.loki.receiver]
}

// ============================================================================
// SEND LOGS TO LOKI
// ============================================================================

loki.write "loki" {
  endpoint {
    url = "http://gateway-api.${host_url_suffix}:8080/loki/api/v1/push"

    batch_wait = "1s"
    batch_size = "100KiB"

    retry_on_http_429 = true
  }

  external_labels = {
    collector_node = "{{ env "node.unique.name" }}",
  }
}
EOH
      }

      resources {
        cpu    = 256
        memory = 256
      }

      service {
        name     = "collector"
        port     = "http"
   
        tags = [
          "monitoring", "alloy", "logs",
          "traefik.enable=true",
          "traefik.http.routers.collector.rule=Host(`collector.${host_url_suffix}`)",
          "traefik.http.routers.collector.entrypoints=http",
          "traefik.http.services.collector.loadbalancer.server.port=12344",
          "traefik.http.middlewares.collector-headers.headers.customrequestheaders.Connection=keep-alive",
          "traefik.http.middlewares.collector-timeout.buffering.maxRequestBodyBytes=0",
          "traefik.http.middlewares.collector-timeout.buffering.memRequestBodyBytes=0",
          "traefik.http.middlewares.collector-timeout.buffering.retryExpression=",
          "traefik.http.routers.collector.middlewares=collector-headers",
          "traefik.http.services.collector.loadbalancer.responseforwarding.flushinterval=100ms",
        ]

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "30s"
          timeout  = "5s"

          check_restart {
            limit           = 3
            grace           = "30s"
            ignore_warnings = false
          }
        }
      }

      kill_timeout = "30s"
      kill_signal  = "SIGINT"
    }
  }
}