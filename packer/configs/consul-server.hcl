datacenter              = "__DATACENTER__"

data_dir                = "/opt/consul/data"

advertise_addr          = "{{ GetInterfaceIP \"eth0\" }}"
bind_addr               = "0.0.0.0"
client_addr             = "0.0.0.0"

log_level               = "INFO"
log_file                = "/var/log/"
log_rotate_duration     = "24h"
log_rotate_max_files    = 5

server                  = true

bootstrap_expect        = 1
retry_join              = ["provider=gce tag_value=consul-server zone_pattern=__REGION__.*"]

license_path            = "/etc/consul.d/license.hclic"

ports {
  grpc = 8502  
}

ui_config {
    enabled             = true
}

telemetry {
    prometheus_retention_time   = "480h"
    disable_hostname            = true
}

connect {
  enabled = false
}

acl {
  enabled                  = true
  default_policy           = "deny"
  enable_token_persistence = true

  tokens {
    initial_management = "74e8e49c-2d83-13f3-b626-45f03bc4f8ca"
    agent              = "74e8e49c-2d83-13f3-b626-45f03bc4f8ca"
  }
}