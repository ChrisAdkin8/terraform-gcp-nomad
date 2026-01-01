variable "project_id" {
  description = "Default GCP project id"
  type        = string
}

variable "nomad_addr" { }

variable "consul_token" {
  description = "Consul token to given Traefik access to the Consul Catalog"
  type        = string
  sensitive   = true
}
variable "data_center" {
  description = "Nomad data center"
  type        = string
}

variable "base_domain" {
  description = "GCP dns zone"
  type        = string
}

variable "region" {
  description = "GCP region to create GCS bucket in"
  type        = string
}

variable "loki_bucket_name" {
  description = "GCS bucket name for Loki storage"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs in BigQuery"
  type        = number
  default     = 90
}

variable "nomad_client_sa_email" {
  description = "Service account email for Nomad clients (for GCS access)"
  type        = string
}