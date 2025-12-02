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
  token = "9a8977a7-3057-6653-a15e-6ec2928aec8b"
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