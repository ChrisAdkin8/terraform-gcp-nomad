variable "project_id" {
  description = "The ID of the GCP project to use"
}

variable "region" {
  description = "The GCP region where resources should be created"
  default     = "europe-west1"
}

variable "zone" {
  description = "The GCP zone where resources should be created"
  default     = null
}

variable "consul_server_instances" {
  description = "The number of server instances to create"
  default     = 1
}

variable "nomad_server_instances" {
  description = "The number of server instances to create"
  default     = 1
}

variable "nomad_client_instances" {
  description = "The number of client instances to create"
  default     = 3
}

variable "secondary_consul_server_instances" {
  description = "The number of server instances to create"
  default     = 1
}

variable "secondary_nomad_server_instances" {
  description = "The number of server instances to create"
  default     = 1
}

variable "secondary_nomad_client_instances" {
  description = "The number of client instances to create"
  default     = 3
}

variable "subnet_cidr" {
  description = "The CIDR range for the subnet"
  default     = "10.128.64.0/24"
}

variable "secondary_subnet_cidr" {
  description = "The CIDR range for the subnet"
  default     = "10.128.128.0/24"
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
}

variable "datacenter" {
  description = "The name of the Nomad datacenter"
  default     = "dc1"
}

variable "secondary_datacenter" {
  description = "The name of the Nomad datacenter"
  default     = "dc2"
}

variable "mgmt_cidr" {
  description = "The CIDR range for management access"
  default     = null
}

variable "short_prefix" {
  description = "The short prefix to use for all resources"
  default     = null
}

variable "dns_managed_zone" {
  description = "The name of the managed zone to use for DNS"
  default     = "doormat-accountid"
}

variable "gcs_bucket" {
  description = "The name of the GCS bucket to use for configuration"
  default     = null
}

variable "create_nomad_cluster" {
  description = "Whether to create Nomad resources"
  default     = true
}

variable "create_consul_cluster" {
  description = "Whether to create Consul resources"
  default     = true
}

variable "create_secondary_nomad_cluster" {
  description = "Whether to create Nomad resources"
  default     = true
}

variable "create_secondary_consul_cluster" {
  description = "Whether to create Consul resources"
  default     = true
}

variable "create_nomad_jobs" {
  description = "Whether to create Nomad jobs"
  default     = true
}

variable "nomad_client_machine_type" {
  description = "The machine type to use for Nomad clients"
  default     = "e2-medium"
}

variable "nomad_client_disk_size" {
  description = "The disk size to use for Nomad clients"
  default     = 20
}