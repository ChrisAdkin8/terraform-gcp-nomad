data_dir              = "/opt/nomad/data"

bind_addr             = "0.0.0.0" # the default

log_level             = "INFO"
log_file              = "/var/log/"
log_rotate_duration   = "24h"
log_rotate_max_files  = 5

server {
  license_path        = "/etc/nomad.d/license.hclic"
  enabled             = true
  bootstrap_expect    = 3
}

client {
  enabled             = false
}

telemetry {
  prometheus_metrics = true
}

consul {
  address             = "127.0.0.1:8500"
  server_service_name = "nomad"
  auto_advertise      = true
  server_auto_join    = true
}