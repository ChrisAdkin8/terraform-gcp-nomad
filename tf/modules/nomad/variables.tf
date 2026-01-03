variable "project_id" {
  description = "Default GCP project id"
  type        = string
}

variable "create_dns_record" {
  description = "Flag to denote whether dns records are to be created"
  type        = bool
}

variable "create_nomad_cluster" {
  description = "Flag to denote whether a Nomad cluster is to be created"
  type        = bool
}

variable "datacenter" {
  description = "The name of the Nomad datacenter"
  type        = string
  default     = "dc1"
}

variable "gcs_bucket" {
  description = "Bucket holding license and config files"
  type        = string
}

variable "name_prefix" {
  description = "The prefix to use for all resources"
  type        = string
  default     = "hashicorp"
}

variable "short_prefix" {
  description = "The short prefix to use for all resources"
  type        = string
  default     = null
}

variable "nomad_client_instances" {
  description = "The number of client instances to create"
  type        = number
  default     = 3
}

variable "nomad_server_instances" {
  description = "The number of server instances to create"
  type        = number
  default     = 1
}

variable "region" {
  description = "The GCP region where resources should be created"
  type        = string
  default     = "europe-west1"
}

variable "subnet_self_link" {
  description = "The subnet self link of the GCP subnetwork to use"
  type        = string
  default     = null
}

variable "zone" {
  description = "The GCP zone where resources should be created"
  type        = string
  default     = null
}

variable "base_domain" {
  description = "DNS base domain"
  type        = string
  default     = null
}

variable "dns_managed_zone" {
  description = "The name of the managed zone to use for DNS"
  type        = string
  default     = "doormat-accountid"
}

variable "nomad_client_machine_type" {
  description = "The machine type to use for Nomad clients"
  type        = string
  default     = "e2-standard-4"
}

variable "nomad_client_disk_size" {
  description = "The disk size to use for Nomad clients"
  type        = number
  default     = 20
}

variable "allowed_ingress_cidrs" {
  description = "List of CIDR blocks allowed to access Traefik endpoints. Use your office/VPN IPs."
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.allowed_ingress_cidrs) > 0
    error_message = "You must specify at least one allowed CIDR block for ingress access."
  }
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}