# AI Agents Mesh Module Variables

variable "project_id" {
  description = "GCP project ID where agent images are stored in GCR"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for AI agents"
  type        = string
  default     = "ai-agents"
}

variable "agent_image_tag" {
  description = "Docker image tag for agent containers"
  type        = string
  default     = "latest"
}

variable "orchestrator_replicas" {
  description = "Number of orchestrator agent replicas"
  type        = number
  default     = 2
}

variable "worker_replicas" {
  description = "Number of replicas for each worker agent"
  type        = number
  default     = 1
}

variable "enable_ingress_gateway" {
  description = "Enable Consul ingress gateway configuration for external access to orchestrator"
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to all Kubernetes resources"
  type        = map(string)
  default     = {}
}

variable "consul_http_addr" {
  description = "Consul HTTP API address for health checks (optional)"
  type        = string
  default     = null
}
