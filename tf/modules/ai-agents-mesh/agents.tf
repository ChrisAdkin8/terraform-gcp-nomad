# AI Agents Namespace
resource "kubernetes_namespace" "ai_agents" {
  metadata {
    name = var.namespace
    labels = merge(var.labels, {
      name                                  = var.namespace
      role                                  = "ai-agent-system"
      "consul.hashicorp.com/connect-inject" = "true"
    })
  }
}

# ============================================================================
# ORCHESTRATOR AGENT
# ============================================================================

resource "kubernetes_deployment" "orchestrator" {
  metadata {
    name      = "orchestrator-agent"
    namespace = kubernetes_namespace.ai_agents.metadata[0].name
    labels = merge(var.labels, {
      app  = "orchestrator-agent"
      role = "orchestrator"
    })
  }

  spec {
    replicas = var.orchestrator_replicas

    selector {
      match_labels = {
        app = "orchestrator-agent"
      }
    }

    template {
      metadata {
        labels = {
          app  = "orchestrator-agent"
          role = "orchestrator"
        }
        annotations = {
          "consul.hashicorp.com/connect-inject" = "true"
          "consul.hashicorp.com/service-port"   = "8080"
        }
      }

      spec {
        container {
          name  = "orchestrator"
          image = "gcr.io/${var.project_id}/orchestrator-agent:${var.agent_image_tag}"

          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          env {
            name  = "AGENT_TYPE"
            value = "orchestrator"
          }

          env {
            name  = "WORKER_SERVICES"
            value = "research-agent,code-agent,data-agent,analysis-agent"
          }

          env {
            name  = "CONSUL_DOMAIN"
            value = "service.consul"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.ai_agents]
}

resource "kubernetes_service" "orchestrator" {
  metadata {
    name      = "orchestrator-agent"
    namespace = kubernetes_namespace.ai_agents.metadata[0].name
    labels = merge(var.labels, {
      app = "orchestrator-agent"
    })
  }

  spec {
    selector = {
      app = "orchestrator-agent"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.orchestrator]
}

# ============================================================================
# RESEARCH AGENT
# ============================================================================

resource "kubernetes_deployment" "research_agent" {
  metadata {
    name      = "research-agent"
    namespace = kubernetes_namespace.ai_agents.metadata[0].name
    labels = merge(var.labels, {
      app  = "research-agent"
      role = "worker"
    })
  }

  spec {
    replicas = var.worker_replicas

    selector {
      match_labels = {
        app = "research-agent"
      }
    }

    template {
      metadata {
        labels = {
          app  = "research-agent"
          role = "worker"
        }
        annotations = {
          "consul.hashicorp.com/connect-inject" = "true"
          "consul.hashicorp.com/service-port"   = "8080"
        }
      }

      spec {
        container {
          name  = "research"
          image = "gcr.io/${var.project_id}/worker-agent:${var.agent_image_tag}"

          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          env {
            name  = "AGENT_TYPE"
            value = "research"
          }

          env {
            name  = "CONSUL_DOMAIN"
            value = "service.consul"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.ai_agents]
}

resource "kubernetes_service" "research_agent" {
  metadata {
    name      = "research-agent"
    namespace = kubernetes_namespace.ai_agents.metadata[0].name
    labels = merge(var.labels, {
      app = "research-agent"
    })
  }

  spec {
    selector = {
      app = "research-agent"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.research_agent]
}

# ============================================================================
# CODE AGENT
# ============================================================================

resource "kubernetes_deployment" "code_agent" {
  metadata {
    name      = "code-agent"
    namespace = kubernetes_namespace.ai_agents.metadata[0].name
    labels = merge(var.labels, {
      app  = "code-agent"
      role = "worker"
    })
  }

  spec {
    replicas = var.worker_replicas

    selector {
      match_labels = {
        app = "code-agent"
      }
    }

    template {
      metadata {
        labels = {
          app  = "code-agent"
          role = "worker"
        }
        annotations = {
          "consul.hashicorp.com/connect-inject" = "true"
          "consul.hashicorp.com/service-port"   = "8080"
        }
      }

      spec {
        container {
          name  = "code"
          image = "gcr.io/${var.project_id}/worker-agent:${var.agent_image_tag}"

          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          env {
            name  = "AGENT_TYPE"
            value = "code"
          }

          env {
            name  = "CONSUL_DOMAIN"
            value = "service.consul"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.ai_agents]
}

resource "kubernetes_service" "code_agent" {
  metadata {
    name      = "code-agent"
    namespace = kubernetes_namespace.ai_agents.metadata[0].name
    labels = merge(var.labels, {
      app = "code-agent"
    })
  }

  spec {
    selector = {
      app = "code-agent"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.code_agent]
}

# ============================================================================
# DATA AGENT
# ============================================================================

resource "kubernetes_deployment" "data_agent" {
  metadata {
    name      = "data-agent"
    namespace = kubernetes_namespace.ai_agents.metadata[0].name
    labels = merge(var.labels, {
      app  = "data-agent"
      role = "worker"
    })
  }

  spec {
    replicas = var.worker_replicas

    selector {
      match_labels = {
        app = "data-agent"
      }
    }

    template {
      metadata {
        labels = {
          app  = "data-agent"
          role = "worker"
        }
        annotations = {
          "consul.hashicorp.com/connect-inject" = "true"
          "consul.hashicorp.com/service-port"   = "8080"
        }
      }

      spec {
        container {
          name  = "data"
          image = "gcr.io/${var.project_id}/worker-agent:${var.agent_image_tag}"

          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          env {
            name  = "AGENT_TYPE"
            value = "data"
          }

          env {
            name  = "CONSUL_DOMAIN"
            value = "service.consul"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.ai_agents]
}

resource "kubernetes_service" "data_agent" {
  metadata {
    name      = "data-agent"
    namespace = kubernetes_namespace.ai_agents.metadata[0].name
    labels = merge(var.labels, {
      app = "data-agent"
    })
  }

  spec {
    selector = {
      app = "data-agent"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.data_agent]
}

# ============================================================================
# ANALYSIS AGENT
# ============================================================================

resource "kubernetes_deployment" "analysis_agent" {
  metadata {
    name      = "analysis-agent"
    namespace = kubernetes_namespace.ai_agents.metadata[0].name
    labels = merge(var.labels, {
      app  = "analysis-agent"
      role = "worker"
    })
  }

  spec {
    replicas = var.worker_replicas

    selector {
      match_labels = {
        app = "analysis-agent"
      }
    }

    template {
      metadata {
        labels = {
          app  = "analysis-agent"
          role = "worker"
        }
        annotations = {
          "consul.hashicorp.com/connect-inject" = "true"
          "consul.hashicorp.com/service-port"   = "8080"
        }
      }

      spec {
        container {
          name  = "analysis"
          image = "gcr.io/${var.project_id}/worker-agent:${var.agent_image_tag}"

          port {
            container_port = 8080
            name           = "http"
            protocol       = "TCP"
          }

          env {
            name  = "AGENT_TYPE"
            value = "analysis"
          }

          env {
            name  = "CONSUL_DOMAIN"
            value = "service.consul"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.ai_agents]
}

resource "kubernetes_service" "analysis_agent" {
  metadata {
    name      = "analysis-agent"
    namespace = kubernetes_namespace.ai_agents.metadata[0].name
    labels = merge(var.labels, {
      app = "analysis-agent"
    })
  }

  spec {
    selector = {
      app = "analysis-agent"
    }

    port {
      name        = "http"
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }

  depends_on = [kubernetes_deployment.analysis_agent]
}
