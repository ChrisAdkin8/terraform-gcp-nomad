provider "google" {
  region  = var.region
  project = local.project_id

  batching {
    enable_batching = true
    send_after      = "10s"
  }

  request_timeout = "60s"
}

provider "consul" {
  address = local.consul_url
  token   = var.initial_management_token
}

# Kubernetes provider configured after GKE cluster creation
provider "kubernetes" {
  host                   = module.gke_dataplane.kubernetes_cluster_host != "" ? "https://${module.gke_dataplane.kubernetes_cluster_host}" : null
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = module.gke_dataplane.gke_cluster_ca_certificate != "" ? base64decode(module.gke_dataplane.gke_cluster_ca_certificate) : null
}

# Helm provider configured after GKE cluster creation
provider "helm" {
  kubernetes {
    host                   = module.gke_dataplane.kubernetes_cluster_host != "" ? "https://${module.gke_dataplane.kubernetes_cluster_host}" : null
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = module.gke_dataplane.gke_cluster_ca_certificate != "" ? base64decode(module.gke_dataplane.gke_cluster_ca_certificate) : null
  }
}
