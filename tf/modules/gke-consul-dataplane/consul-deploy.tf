# Consul namespace
resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
    labels = merge(var.labels, {
      name = "consul"
      role = "service-mesh"
    })
  }
  depends_on = [google_container_node_pool.primary_nodes]
}

# Consul bootstrap ACL token secret
resource "kubernetes_secret" "consul_bootstrap_token" {
  metadata {
    name      = "consul-bootstrap-acl-token"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }
  data = {
    token = var.consul_token
  }
  type = "Opaque"
}

# Wait for node pool to be fully operational
resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = <<-EOT
      gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION --project $PROJECT_ID
      kubectl wait --for=condition=Ready nodes --all --timeout=300s
    EOT
  
    environment = {
      CLUSTER_NAME = google_container_cluster.primary.name
      REGION        = var.region
      PROJECT_ID   = var.project_id
    }
  }
  

  depends_on = [google_container_node_pool.primary_nodes]
}

# Consul Helm release
# Consul Helm release
resource "helm_release" "consul" {
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.consul.metadata[0].name

  wait            = true
  wait_for_jobs   = true
  timeout         = 900
  replace         = true
  atomic          = true
  cleanup_on_fail = true

  values = [yamlencode({
    global = {
      enabled    = true
      name       = "consul"
      domain     = "consul"
      datacenter = var.consul_datacenter
      logLevel   = var.global_log_level
      logJSON    = var.global_log_json

      acls = {
        manageSystemACLs = true
        bootstrapToken = {
          secretName = kubernetes_secret.consul_bootstrap_token.metadata[0].name
          secretKey  = "token"
        }
      }

      # ---------------------------------------------------------
      # CHANGE: TLS Disabled
      # ---------------------------------------------------------
      tls = {
        enabled = false  # <--- CHANGE: Disables TLS for the K8s cluster components
      }
    }

    externalServers = {
      enabled = true
      hosts   = [var.consul_internal_address]

      # ---------------------------------------------------------
      # IMPORTANT: The Helm chart only has 'httpsPort', not 'httpPort' or 'useHTTPS'
      # When TLS is disabled, set httpsPort to the HTTP port (8500)
      # This is a known limitation: https://github.com/hashicorp/consul-helm/issues/771
      # ---------------------------------------------------------
      httpsPort = 8500  # Set to HTTP port when TLS is disabled
      grpcPort  = 8502

      # Matches the Host in consul_auth_method
      # Note: This usually remains HTTPS because it points to the GKE API, not Consul
      k8sAuthMethodHost = "https://${google_container_cluster.primary.endpoint}"

      # Use the auth method created by Terraform
      k8sAuthMethodName = "consul-k8s-component-auth-method"

      # ---------------------------------------------------------
      # Skip CA verification (TLS not used for Consul server connections)
      # ---------------------------------------------------------
      useSystemRoots = false
    }

    server = {
      enabled = false
    }

    # Disable traditional Consul clients - using dataplane mode only
    client = {
      enabled = false
    }

    dns = {
      enabled           = true
      enableRedirection = true
    }

    connectInject = merge(
      {
        enabled = var.enable_service_mesh
        default = true
        transparentProxy = {
          defaultEnabled = true
        }
        metrics = {
          defaultEnabled       = true
          enableGatewayMetrics = true
        }
      },
      var.connect_inject_log_level != null ? { logLevel = var.connect_inject_log_level } : {}
    )

    ingressGateways = {
      enabled = var.enable_ingress_gateway
      defaults = {
        replicas = 2
        service = {
          type = "LoadBalancer"
          ports = [
            { port = 80 }, 
            { port = 443 }, # Note: With TLS disabled, this port may not terminate SSL/TLS
            { port = 8080 }, 
            { port = 8443 }
          ]
        }
      }
      gateways = [
        { name = "ingress-gateway" }
      ]
    }

    syncCatalog = {
      enabled   = true
      default   = true
      toConsul  = true
      toK8S     = false
      k8sPrefix = "k8s-"
    }
  })]

  depends_on = [
    kubernetes_namespace.consul,
    kubernetes_secret.consul_bootstrap_token,
    google_container_node_pool.primary_nodes,
    null_resource.wait_for_cluster,
    consul_acl_auth_method.gke,
    kubernetes_cluster_role.consul_auth_method,
    kubernetes_cluster_role_binding.consul_auth_method,
    kubernetes_cluster_role.consul_auth_method_serviceaccount_reader,
    kubernetes_cluster_role_binding.consul_auth_method_serviceaccount_reader,
    kubernetes_service_account.consul_auth_method,
    kubernetes_secret.consul_auth_method
  ]
}