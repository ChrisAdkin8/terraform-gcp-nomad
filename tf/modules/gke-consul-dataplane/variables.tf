# GCP Configuration
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region to deploy GKE cluster to"
  type        = string
  default     = "europe-west2"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "machine_type" {
  description = "Machine type for Kubernetes node pool"
  type        = string
  default     = "e2-standard-8"
}

variable "gke_num_nodes" {
  description = "Number of nodes in Kubernetes node pool"
  type        = number
  default     = 3
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

# Network Configuration
variable "subnet_self_link" {
  description = "The self-link of the GCP subnet to deploy GKE cluster into"
  type        = string
}

variable "ingress_gateway_source_ranges" {
  description = "Source IP CIDR ranges allowed to access the ingress gateway. Use with caution - 0.0.0.0/0 allows public internet access."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Consul Configuration
variable "consul_address" {
  description = "Address of external Consul server for Terraform provider (FQDN or IP with protocol and port)"
  type        = string
}

variable "consul_internal_address" {
  description = "Internal address of Consul server for pods in GKE cluster (FQDN or IP with protocol and port)"
  type        = string
}

variable "consul_token" {
  description = "ACL token for connecting to Consul"
  type        = string
  sensitive   = true
}

variable "consul_datacenter" {
  description = "Consul datacenter name"
  type        = string
  default     = "dc1"
}

# Feature Flags
variable "enable_service_mesh" {
  description = "Enable Consul service mesh with sidecar injection"
  type        = bool
  default     = true
}

variable "enable_ingress_gateway" {
  description = "Deploy Consul ingress gateway"
  type        = bool
  default     = true
}

# Helm Configuration
variable "helm_chart_version" {
  description = "Consul Helm chart version"
  type        = string
  default     = "1.9.2"
}

# Logging Configuration
variable "global_log_level" {
  description = "Global log level for all Consul components. Valid values: trace, debug, info, warn, error"
  type        = string
  default     = "info"

  validation {
    condition     = contains(["trace", "debug", "info", "warn", "error"], var.global_log_level)
    error_message = "The global_log_level must be one of: trace, debug, info, warn, error."
  }
}

variable "global_log_json" {
  description = "Enable JSON formatted logs for all components"
  type        = bool
  default     = false
}

variable "client_log_level" {
  description = "Log level for Consul client (dataplane). If null, uses global_log_level. Valid values: trace, debug, info, warn, error"
  type        = string
  default     = null

  validation {
    condition     = var.client_log_level == null || contains(["trace", "debug", "info", "warn", "error"], var.client_log_level)
    error_message = "The client_log_level must be one of: trace, debug, info, warn, error, or null."
  }
}

variable "connect_inject_log_level" {
  description = "Log level for service mesh sidecar injection. If null, uses global_log_level. Valid values: trace, debug, info, warn, error"
  type        = string
  default     = null

  validation {
    condition     = var.connect_inject_log_level == null || contains(["trace", "debug", "info", "warn", "error"], var.connect_inject_log_level)
    error_message = "The connect_inject_log_level must be one of: trace, debug, info, warn, error, or null."
  }
}

variable "short_prefix" {
  description = "String to prefix resource names with"
  type        = string
}