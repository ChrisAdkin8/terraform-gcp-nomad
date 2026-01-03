# Create Consul namespace
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

# Create secret for Consul ACL token
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

# Deploy Consul via Helm
resource "helm_release" "consul" {
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version    = var.helm_chart_version
  namespace  = kubernetes_namespace.consul.metadata[0].name

  wait          = true
  wait_for_jobs = true
  timeout       = 600

  values = [yamlencode({
    global = {
      enabled    = true
      name       = "consul"
      domain     = "consul"
      datacenter = var.consul_datacenter

      acls = {
        manageSystemACLs = false
        bootstrapToken = {
          secretName = kubernetes_secret.consul_bootstrap_token.metadata[0].name
          secretKey  = "token"
        }
      }

      tls = {
        enabled = false
      }
    }

    externalServers = {
      enabled           = true
      hosts             = [var.consul_address]
      httpsPort         = 8500
      grpcPort          = 8502
      useSystemRoots    = true
      k8sAuthMethodHost = "https://${google_container_cluster.primary.endpoint}"
    }

    server = {
      enabled = false
    }

    client = {
      enabled = false
    }

    dns = {
      enabled           = true
      enableRedirection = true
    }

    connectInject = {
      enabled = var.enable_service_mesh
      default = true

      metrics = {
        defaultEnabled       = true
        enableGatewayMetrics = true
      }
    }

    ingressGateways = {
      enabled = var.enable_ingress_gateway

      defaults = {
        replicas = 2

        service = {
          type = "LoadBalancer"
          ports = [
            { port = 80 },
            { port = 443 },
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
    google_container_node_pool.primary_nodes
  ]
}

# Data source to get ingress gateway service details
data "kubernetes_service" "ingress_gateway" {
  count = var.enable_ingress_gateway ? 1 : 0

  metadata {
    name      = "consul-ingress-gateway"
    namespace = kubernetes_namespace.consul.metadata[0].name
  }

  depends_on = [helm_release.consul]
}
