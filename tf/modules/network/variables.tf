variable "project_id" {
  description = "Default GCP project id"
  type        = string
}

variable "name_prefix" {
  description = "The prefix to use for all resources"
  type        = string
  default     = "hashicorp"
}

variable "mgmt_cidr" {
  description = "The CIDR range for management access"
  type        = string
  default     = null
}

variable "region" {
  description = "The GCP region where resources should be created"
  type        = string
  default     = "europe-west1"
}

variable "secondary_region" {
  description = "The GCP region where resources should be created"
  type        = string
  default     = "europe-west2"
}

variable "short_prefix" {
  description = "The short prefix to use for all resources"
  type        = string
  default     = null
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
  default     = "10.128.64.0/24"
}

variable "secondary_subnet_cidr" {
  description = "The CIDR range for the subnet"
  type        = string
  default     = "10.128.128.0/24"
}

variable "firewall_config" {
  description = "Firewall configuration"
  type = object({
    mgmt_cidr             = string
    allowed_ingress_cidrs = list(string)
    enable_traefik_rules  = bool
    traefik_ports         = list(string)
  })
  default = {
    mgmt_cidr             = null
    allowed_ingress_cidrs = []
    enable_traefik_rules  = true
    traefik_ports         = ["8080", "8081"]
  }
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "proxy_subnet_cidr" {
  description = "The CIDR range for the primary region proxy-only subnet"
  type        = string
  default     = "10.100.0.0/24"
}

variable "secondary_proxy_subnet_cidr" {
  description = "The CIDR range for the secondary region proxy-only subnet"
  type        = string
  default     = "10.101.0.0/24"
}