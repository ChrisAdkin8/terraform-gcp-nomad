variable "project_id" {
  description = "project id"
}

variable "region" {
  default     = "europe-west2"
  description = "GCP region to deploy GKE cluster to"
}

variable "cluster_name" { }

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
