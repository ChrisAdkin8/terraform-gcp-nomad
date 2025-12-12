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
    initial_management = "42c5ae46-331b-8ea8-c9a4-e6280cef9ba0"
    agent              = "42c5ae46-331b-8ea8-c9a4-e6280cef9ba0"
  }
}