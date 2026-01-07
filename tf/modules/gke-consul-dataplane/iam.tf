# ============================================================================
# GCP Service Accounts and IAM
# ============================================================================

# GKE node pool service account
resource "google_service_account" "gke_nodes" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
}

# Grant minimum required permissions for a standard GKE node
resource "google_project_iam_member" "gke_node_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_node_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_node_monitoring_viewer" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Required to pull images from Google Container Registry/Artifact Registry
resource "google_project_iam_member" "gke_node_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# ============================================================================
# Kubernetes Service Accounts and Secrets
# ============================================================================

# Kubernetes service account for Consul auth method
resource "kubernetes_service_account" "consul_auth_method" {
  metadata {
    name      = "consul-auth-method-sa"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }
}

# Long-lived token secret for Consul auth method
resource "kubernetes_secret" "consul_auth_method" {
  metadata {
    name      = "consul-auth-method-token"
    namespace = kubernetes_namespace.consul.metadata[0].name
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.consul_auth_method.metadata[0].name
    }
  }

  type = "kubernetes.io/service-account-token"

  # CRITICAL: Wait for K8s controller to populate the token data
  wait_for_service_account_token = true
}

# ClusterRole granting permission to create tokenreviews
resource "kubernetes_cluster_role" "consul_auth_method" {
  metadata {
    name = "consul-auth-method-tokenreviewer"
  }

  rule {
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
    verbs      = ["create"]
  }
}

# ClusterRoleBinding binding the ClusterRole to consul-auth-method-sa
resource "kubernetes_cluster_role_binding" "consul_auth_method" {
  metadata {
    name = "consul-auth-method-tokenreviewer-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.consul_auth_method.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.consul_auth_method.metadata[0].name
    namespace = kubernetes_namespace.consul.metadata[0].name
  }
}

# ClusterRole granting permission to get serviceaccounts for auth method annotation lookup
resource "kubernetes_cluster_role" "consul_auth_method_serviceaccount_reader" {
  metadata {
    name = "consul-auth-method-sa-reader"
  }

  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["get"]
  }
}

# ClusterRoleBinding for serviceaccount reader permissions
resource "kubernetes_cluster_role_binding" "consul_auth_method_serviceaccount_reader" {
  metadata {
    name = "consul-auth-method-sa-reader-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.consul_auth_method_serviceaccount_reader.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.consul_auth_method.metadata[0].name
    namespace = kubernetes_namespace.consul.metadata[0].name
  }
}