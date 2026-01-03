locals {
  subnets = {
    primary = {
      name   = "${var.name_prefix}-snet"
      cidr   = var.subnet_cidr
      region = var.region
    }
    secondary = {
      name   = "${var.name_prefix}-secondary-snet"
      cidr   = var.secondary_subnet_cidr
      region = var.secondary_region
    }
  }

  subnet_log_config = {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0
    metadata             = "INCLUDE_ALL_METADATA"
  }

  nat_log_config = {
    enable = true
    filter = "ERRORS_ONLY"
  }

  regions = {
    primary = {
      region = var.region
      cidr   = var.subnet_cidr
      name   = var.name_prefix
    }
    secondary = {
      region = var.secondary_region
      cidr   = var.secondary_subnet_cidr
      name   = "${var.name_prefix}-secondary"
    }
  }

  firewall_rules = {
    iap_ssh = {
      direction     = "INGRESS"
      source_ranges = data.google_netblock_ip_ranges.iap.cidr_blocks
      target_tags   = ["consul-server", "nomad-server", "nomad-client"]
      rules         = [{ protocol = "tcp", ports = ["22"] }]
      description   = "Allow SSH via IAP"
    }
    
    consul_mgmt = {
      direction     = "INGRESS"
      source_ranges = var.firewall_config.mgmt_cidr != null ? [var.firewall_config.mgmt_cidr] : []
      target_tags   = ["consul-server"]
      rules         = [{ protocol = "tcp", ports = ["8500"] }]
      description   = "Consul UI/API access from management CIDR"
    }
    
    nomad_mgmt = {
      direction     = "INGRESS"
      source_ranges = var.firewall_config.mgmt_cidr != null ? [var.firewall_config.mgmt_cidr] : []
      target_tags   = ["nomad-server"]
      rules         = [{ protocol = "tcp", ports = ["4646"] }]
      description   = "Nomad UI/API access from management CIDR"
    }
    
    cluster_internal = {
      direction   = "INGRESS"
      source_tags = ["nomad-server", "nomad-client", "consul-server"]
      target_tags = ["nomad-server", "consul-server"]
      rules = [
        { protocol = "icmp", ports = null },
        { protocol = "tcp", ports = ["4646", "4647", "4648", "8300", "8301", "8302", "8500", "8501", "8502", "8503", "8600"] },
        { protocol = "udp", ports = ["4648", "8301", "8302", "8600"] }
      ]
      description = "Internal cluster communication"
    }
    
    nomad_client_internal = {
      direction   = "INGRESS"
      source_tags = ["nomad-server", "nomad-client"]
      target_tags = ["nomad-client"]
      rules = [
        { protocol = "icmp", ports = null },
        { protocol = "tcp", ports = ["4647", "8301", "3100", "3000", "9090", "12344", "12345", "12346"] }
      ]
      description = "Nomad client communication and observability"
    }
    
    lb_health_checks = {
      direction     = "INGRESS"
      source_ranges = data.google_netblock_ip_ranges.health_checkers.cidr_blocks
      target_tags   = ["nomad-client"]
      rules         = [{ protocol = "tcp", ports = var.firewall_config.traefik_ports }]
      description   = "GCP load balancer health checks"
    }
    
    traefik_ingress = {
      direction     = "INGRESS"
      source_ranges = var.firewall_config.allowed_ingress_cidrs
      target_tags   = ["nomad-client"]
      rules         = [{ protocol = "tcp", ports = var.firewall_config.traefik_ports }]
      description   = "External access to Traefik"
    }
  }
}