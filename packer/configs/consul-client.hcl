datacenter              = "__DATACENTER__"
data_dir                = "/opt/consul/data"

advertise_addr          = "{{ GetInterfaceIP \"eth0\" }}"
bind_addr               = "0.0.0.0"
# Used for HTTP, HTTPS, DNS, and gRPC addresses.
# loopback is not included in GetPrivateInterfaces because it is not routable.
client_addr = "{{ GetPrivateInterfaces | exclude \"type\" \"ipv6\" | join \"address\" \" \" }} {{ GetAllInterfaces | include \"flags\" \"loopback\" | join \"address\" \" \" }}"

log_level               = "INFO"
log_file                = "/var/log/"
log_rotate_duration     = "24h"
log_rotate_max_files    = 5

server                  = false

retry_join              = ["provider=gce tag_value=consul-server zone_pattern=__REGION__.*"]

license_path            = "/etc/consul.d/license.hclic"

telemetry {
    prometheus_retention_time   = "480h"
    disable_hostname            = true
}