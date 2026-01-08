# Consul Ingress Gateway Configuration for AI Agents
#
# This file configures the Consul ingress gateway to route external traffic
# to the orchestrator agent. The ingress gateway provides:
#
# - External LoadBalancer with public IP
# - HTTP traffic routing to orchestrator-agent service
# - Entry point for users to interact with the AI agent system
#
# Security note: Only the orchestrator is exposed externally. Worker agents
# are not accessible from outside the cluster, enforcing the hierarchical
# communication pattern.

# ============================================================================
# INGRESS GATEWAY CONFIGURATION
# ============================================================================

resource "consul_config_entry" "ingress_gateway" {
  count = var.enable_ingress_gateway ? 1 : 0

  kind = "ingress-gateway"
  name = "ingress-gateway"

  config_json = jsonencode({
    Listeners = [
      {
        Port     = 8080
        Protocol = "http"
        Services = [
          {
            Name  = "orchestrator-agent"
            Hosts = ["*"]
          }
        ]
      }
    ]
  })

  depends_on = [
    consul_config_entry.orchestrator_defaults,
    kubernetes_service.orchestrator
  ]
}

# ============================================================================
# SERVICE ROUTER (Optional)
# ============================================================================
#
# The service router provides advanced traffic management capabilities.
# This configuration demonstrates path-based routing and can be extended
# with header-based routing, query parameter matching, etc.

resource "consul_config_entry" "orchestrator_router" {
  count = var.enable_ingress_gateway ? 1 : 0

  kind = "service-router"
  name = "orchestrator-agent"

  config_json = jsonencode({
    Routes = [
      {
        Match = {
          HTTP = {
            PathPrefix = "/"
          }
        }
        Destination = {
          Service = "orchestrator-agent"
        }
      }
    ]
  })

  depends_on = [consul_config_entry.ingress_gateway]
}

# ============================================================================
# NOTES ON INGRESS CONFIGURATION
# ============================================================================
#
# The ingress gateway configuration above creates an HTTP listener on port 8080
# that routes all traffic to the orchestrator-agent service.
#
# How to access:
#   1. Get the external IP:
#      terraform output ingress_gateway_ip
#
#   2. Test health endpoint:
#      curl http://<ingress-ip>:8080/health
#
#   3. Delegate task to workers:
#      curl -X POST http://<ingress-ip>:8080/analyze \
#        -H "Content-Type: application/json" \
#        -d '{"task": "Analyze data"}'
#
# Security considerations:
#   - Only orchestrator is exposed via ingress gateway
#   - Worker agents remain internal to the cluster
#   - All external requests must go through orchestrator
#   - Orchestrator enforces business logic and guardrails
#
# Advanced routing (examples for extension):
#   - Path-based:  /v1/* → orchestrator-v1, /v2/* → orchestrator-v2
#   - Header-based: X-Version: beta → orchestrator-beta
#   - Weighted:    90% → orchestrator-stable, 10% → orchestrator-canary
#
# To implement advanced routing, modify the service router configuration above.
