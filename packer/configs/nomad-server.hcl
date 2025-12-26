datacenter            = "__DATACENTER__"
data_dir              = "/opt/nomad/data"
region                = "__REGION__"

bind_addr             = "0.0.0.0"

log_level             = "TRACE"
log_file              = "/var/log/"
log_rotate_duration   = "24h"
log_rotate_max_files  = 5

server {
  license_path        = "/etc/nomad.d/license.hclic"
  enabled             = true
  bootstrap_expect    = 1

  retry_join = [
    "provider=gce tag_value=nomad-server"
  ]
}

client {
  enabled             = false
}

telemetry {
  prometheus_metrics = true
}

consul {
  token = "d9a9063c-b184-656e-4c04-43237dcdf434"
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