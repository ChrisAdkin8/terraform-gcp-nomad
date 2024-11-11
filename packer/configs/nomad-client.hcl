data_dir  = "/opt/nomad/data"

bind_addr = "0.0.0.0" # the default

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
  address             = "127.0.0.1:8500"
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  auto_advertise      = true
  server_auto_join    = true
  client_auto_join    = true
}

host_volume "hv001" {
  path      = "/opt/nomad/hv001"
  read_only = false
}
