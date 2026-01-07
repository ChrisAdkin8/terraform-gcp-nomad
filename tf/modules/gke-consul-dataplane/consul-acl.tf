# Consul ACL auth method for Kubernetes authentication
resource "consul_acl_auth_method" "gke" {
  name = "consul-k8s-component-auth-method"
  type = "kubernetes"

  description = "Auth method for GKE Cluster"

  config_json = jsonencode({
    # Host: Dynamically set to the GKE Public Endpoint
    Host = "https://${google_container_cluster.primary.endpoint}"

    # CA Certificate: Base64 decode the GKE output to get the raw PEM string
    CACert = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)

    # Service Account JWT: Use the Long-Lived Token we created
    ServiceAccountJWT = kubernetes_secret.consul_auth_method.data["token"]
  })
  /*
  depends_on = [  
    google_compute_firewall.temp_tf_consul_access
  ]
  */
}

# Binding rule for Catalog Sync
resource "consul_acl_binding_rule" "sync_catalog" {
  auth_method = consul_acl_auth_method.gke.name
  description = "Bind sync-catalog SA to Consul Service"

  bind_type = "service"
  bind_name = "consul-sync-catalog"

  # Selector MUST match the ServiceAccount name in K8s
  selector = "serviceaccount.name == \"consul-sync-catalog\""
}

# Binding rule for Client Agents
resource "consul_acl_binding_rule" "consul_client" {
  auth_method = consul_acl_auth_method.gke.name
  description = "Bind consul-client SA to client role"

  bind_type = "role"
  bind_name = "consul-client" # Ensure this ACL Role exists on Consul Server

  selector = "serviceaccount.name == \"consul-client\""
}

# Binding rule for Connect Injector
resource "consul_acl_binding_rule" "connect_injector" {
  auth_method = consul_acl_auth_method.gke.name
  description = "Bind connect-injector SA to service"

  bind_type = "service"
  bind_name = "consul-connect-injector"

  selector = "serviceaccount.name == \"consul-connect-injector\""
}
