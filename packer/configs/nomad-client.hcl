datacenter            = "__DATACENTER__"
data_dir              = "/opt/nomad/data"
region                = "__REGION__"

bind_addr             = "0.0.0.0"

log_level             = "INFO"
log_file              = "/var/log/"
log_rotate_duration   = "24h"
log_rotate_max_files  = 5

server {
  license_path        = "/etc/nomad.d/license.hclic"
  enabled             = false
}

client {
  enabled             = true

  host_volume "minio" {
    path      = "/opt/minio/data"
    read_only = false
  }

  host_volume "loki" {
    path      = "/opt/loki/data"
    read_only = false
  }

  host_volume "alloy" {
    path      = "/opt/alloy/data"
    read_only = false
  }

  host_volume "grafana" {
    path      = "/opt/grafana/data"
    read_only = false
  }

  servers = [
    "provider=gce tag_value=nomad-server"
  ]
}

plugin "docker" {
  config {
    allow_privileged = true
  }
  docker.volumes.enabled = true
}

plugin "raw_exec" {
  config {
    enabled           = true
  }
}

telemetry {
  prometheus_metrics = true
}

consul {
  token = "42c5ae46-331b-8ea8-c9a4-e6280cef9ba0"
  enabled = true
  service_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }
  task_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }
}