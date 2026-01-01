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
}