variable "project_id" {
  description = "Default GCP project_id"
  type        = string
}
variable "region" {
  description = "The GCP region where resources should be created"
  default     = "europe-west1"
  type        = string
}

variable "zone" {
  description = "The GCP zone where resources should be created"
  default     = null
  type        = string
}

variable "base_domain" {
  description = "DNS base domain"
  default     = null
  type        = string
}

variable "consul_server_instances" {
  description = "The number of server instances to create"
  default     = 1
  type        = number
}

variable "nomad_server_instances" {
  description = "The number of server instances to create"
  default     = 1
  type        = number
}

variable "nomad_client_instances" {
  description = "The number of client instances to create"
  default     = 3
  type        = number
}

variable "secondary_consul_server_instances" {
  description = "The number of server instances to create"
  default     = 1
  type        = number
}

variable "initial_management_token" {
  description = "Seed token for bootstrapping Consul's ACL system"
  type        = string
  sensitive   = true
}

variable "secondary_nomad_server_instances" {
  description = "The number of server instances to create"
  default     = 1
  type        = number
}

variable "secondary_nomad_client_instances" {
  description = "The number of client instances to create"
  default     = 3
  type        = number
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  default     = "10.128.64.0/24"
  type        = string
}

variable "secondary_subnet_cidr" {
  description = "The CIDR range for the subnet"
  default     = "10.128.128.0/24"
  type        = string
}

variable "subnet_self_link" {
  description = "The subnet self link of the GCP subnetwork to use"
  default     = null
}

variable "name_prefix" {
  description = "The prefix to use for all resources"
  default     = "hashicorp"
}

variable "secondary_region" {
  description = "The GCP region where resources should be created"
  default     = "europe-west2"
  type        = string
}

variable "datacenter" {
  description = "The name of the Nomad datacenter"
  default     = "dc1"
  type        = string
}

variable "secondary_datacenter" {
  description = "The name of the Nomad datacenter"
  default     = "dc2"
  type        = string
}

variable "mgmt_cidr" {
  description = "The CIDR range for management access"
  default     = null
}

variable "short_prefix" {
  description = "The short prefix to use for all resources"
  default     = null
  type        = string
}

variable "dns_managed_zone" {
  description = "The name of the managed zone to use for DNS"
  default     = "doormat-accountid"
  type        = string
}

variable "gcs_bucket" {
  description = "The name of the GCS bucket to use for configuration"
  default     = null
  type        = string
}

variable "create_nomad_cluster" {
  description = "Whether to create Nomad resources"
  default     = true
  type        = bool
}

variable "create_consul_cluster" {
  description = "Whether to create Consul resources"
  default     = true
  type        = bool
}

variable "create_secondary_nomad_cluster" {
  description = "Whether to create Nomad resources"
  default     = true
  type        = bool
}

variable "create_secondary_consul_cluster" {
  description = "Whether to create Consul resources"
  default     = true
  type        = bool
}

variable "create_nomad_jobs" {
  description = "Whether to create Nomad jobs"
  default     = true
  type        = bool
}

variable "nomad_client_machine_type" {
  description = "The machine type to use for Nomad clients"
  default     = "e2-standard-4"
  type        = string
}

variable "nomad_client_disk_size" {
  description = "The disk size to use for Nomad clients"
  default     = 20
  type        = number
}

variable "create_dns_record" {
  description = "Flag to determine whether DNS records are created for the traefik API and observability endpoints" 
  type        = bool
  default     = false
}

variable "grafana_admin_password" {
  type        = string
  sensitive   = true
  default     = "admin"
  description = "Grafana admin password"
}

variable "create_dashboard" {
  description = "Whether to create Grafana dashboard (set to true after Grafana is running)"
  type        = bool
  default     = false
}