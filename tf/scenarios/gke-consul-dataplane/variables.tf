variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resource deployment"
  type        = string
  default     = "europe-west2"
}

variable "zone" {
  description = "GCP zone for resource deployment"
  type        = string
  default     = null
}

variable "datacenter" {
  description = "Consul datacenter name"
  type        = string
  default     = "dc1"
}

variable "initial_management_token" {
  description = "Seed token for bootstrapping Consul's ACL system"
  type        = string
  sensitive   = true
}

variable "consul_server_instances" {
  description = "Number of Consul server instances to create"
  type        = number
  default     = 1
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.128.64.0/24"
}

variable "gke_cluster_name" {
  description = "Name for the GKE cluster"
  type        = string
  default     = "gke-cluster"
}

variable "gke_num_nodes" {
  description = "Number of GKE nodes"
  type        = number
  default     = 3
}

variable "gke_machine_type" {
  description = "Machine type for GKE node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the GKE cluster"
  type        = string
  default     = "1.29"
}

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

variable "helm_chart_version" {
  description = "Consul Helm chart version"
  type        = string
  default     = "1.9.2"
}

variable "create_consul_cluster" {
  description = "Whether to create Consul control plane"
  type        = bool
  default     = true
}

variable "create_gke_cluster" {
  description = "Whether to create GKE cluster with Consul dataplane"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}