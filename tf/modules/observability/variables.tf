variable "nomad_addr" { }

variable "consul_token" {
    description = "Consul token to given Traefik access to the Consul Catalog"
    type        = string
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

variable "bigquery_dataset_name" {
  description = "BigQuery dataset name for Loki logs"
  type        = string
  default     = "loki_logs"
}

variable "log_retention_days" {
  description = "Number of days to retain logs in BigQuery"
  type        = number
  default     = 90
}