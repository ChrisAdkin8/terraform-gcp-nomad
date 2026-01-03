variable "project_id" {
  description = "project id"
}

variable "region" {
  default     = "europe-west2"
  description = "GCP region to deploy GKE cluster to"
}

variable "cluster_name" {}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

variable "machine_type" {
  default     = "e2-standard-8"
  description = "Machine type for Kubernetes node pool"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the GKE cluster"
  type        = string
  default     = "1.22.12-gke.2300"
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

# Consul Configuration
variable "consul_address" {
  description = "Address of external Consul server (FQDN or IP)"
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
  default     = "1.3.0"
}
