variable "project_id" {
  description = "Default GCP project id"
  type        = string
}

variable "create_consul_cluster" {
  description = "Flag to determine whether consul cluster should be created"
  type        = bool
  default     = true
}

variable "consul_server_instances" {
  description = "The number of server instances to create"
  type        = number
  default     = 1
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

variable "dns_managed_zone" {
  description = "The name of the managed zone to use for DNS"
  type        = string
  default     = "doormat-accountid"
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}