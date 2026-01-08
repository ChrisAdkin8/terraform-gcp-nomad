# Consul Service Mesh Intentions for AI Agent Hierarchy
#
# This file defines the service mesh security policies that enforce the
# hierarchical agent communication pattern:
#
# ALLOWED:
#   - Orchestrator → All Workers
#   - External → Orchestrator (via ingress gateway)
#
# BLOCKED:
#   - Worker → Worker (lateral movement prevention)
#   - External → Workers (direct access)

# ============================================================================
# SERVICE DEFAULTS
# These must be created before intentions to set the protocol for each service
# ============================================================================

resource "consul_config_entry" "orchestrator_defaults" {
  kind = "service-defaults"
  name = "orchestrator-agent"

  config_json = jsonencode({
    Protocol = "http"
  })

  depends_on = [kubernetes_service.orchestrator]
}

resource "consul_config_entry" "research_agent_defaults" {
  kind = "service-defaults"
  name = "research-agent"

  config_json = jsonencode({
    Protocol = "http"
  })

  depends_on = [kubernetes_service.research_agent]
}

resource "consul_config_entry" "code_agent_defaults" {
  kind = "service-defaults"
  name = "code-agent"

  config_json = jsonencode({
    Protocol = "http"
  })

  depends_on = [kubernetes_service.code_agent]
}

resource "consul_config_entry" "data_agent_defaults" {
  kind = "service-defaults"
  name = "data-agent"

  config_json = jsonencode({
    Protocol = "http"
  })

  depends_on = [kubernetes_service.data_agent]
}

resource "consul_config_entry" "analysis_agent_defaults" {
  kind = "service-defaults"
  name = "analysis-agent"

  config_json = jsonencode({
    Protocol = "http"
  })

  depends_on = [kubernetes_service.analysis_agent]
}

# ============================================================================
# SERVICE INTENTIONS
# Define explicit allow/deny rules for service-to-service communication
# ============================================================================

# Intention: Allow orchestrator → research-agent
resource "consul_config_entry" "intention_orchestrator_to_research" {
  kind = "service-intentions"
  name = "research-agent"

  config_json = jsonencode({
    Sources = [
      {
        Name        = "orchestrator-agent"
        Action      = "allow"
        Description = "Allow orchestrator to call research agent"
      },
      {
        Name        = "*"
        Action      = "deny"
        Description = "Deny all other sources (including other workers)"
      }
    ]
  })

  depends_on = [
    consul_config_entry.orchestrator_defaults,
    consul_config_entry.research_agent_defaults
  ]
}

# Intention: Allow orchestrator → code-agent
resource "consul_config_entry" "intention_orchestrator_to_code" {
  kind = "service-intentions"
  name = "code-agent"

  config_json = jsonencode({
    Sources = [
      {
        Name        = "orchestrator-agent"
        Action      = "allow"
        Description = "Allow orchestrator to call code agent"
      },
      {
        Name        = "*"
        Action      = "deny"
        Description = "Deny all other sources (including other workers)"
      }
    ]
  })

  depends_on = [
    consul_config_entry.orchestrator_defaults,
    consul_config_entry.code_agent_defaults
  ]
}

# Intention: Allow orchestrator → data-agent
resource "consul_config_entry" "intention_orchestrator_to_data" {
  kind = "service-intentions"
  name = "data-agent"

  config_json = jsonencode({
    Sources = [
      {
        Name        = "orchestrator-agent"
        Action      = "allow"
        Description = "Allow orchestrator to call data agent"
      },
      {
        Name        = "*"
        Action      = "deny"
        Description = "Deny all other sources (including other workers)"
      }
    ]
  })

  depends_on = [
    consul_config_entry.orchestrator_defaults,
    consul_config_entry.data_agent_defaults
  ]
}

# Intention: Allow orchestrator → analysis-agent
resource "consul_config_entry" "intention_orchestrator_to_analysis" {
  kind = "service-intentions"
  name = "analysis-agent"

  config_json = jsonencode({
    Sources = [
      {
        Name        = "orchestrator-agent"
        Action      = "allow"
        Description = "Allow orchestrator to call analysis agent"
      },
      {
        Name        = "*"
        Action      = "deny"
        Description = "Deny all other sources (including other workers)"
      }
    ]
  })

  depends_on = [
    consul_config_entry.orchestrator_defaults,
    consul_config_entry.analysis_agent_defaults
  ]
}

# ============================================================================
# NOTES ON SECURITY MODEL
# ============================================================================
#
# The above intentions implement a zero-trust security model where:
#
# 1. Worker-to-Worker calls are BLOCKED
#    - Research agent cannot call code agent
#    - Code agent cannot call data agent
#    - etc.
#    - This prevents lateral movement and ensures all traffic flows
#      through the orchestrator
#
# 2. Only Orchestrator can call Workers
#    - Explicit allow rules grant orchestrator access to each worker
#    - All other sources are denied by default
#
# 3. External → Orchestrator is handled by ingress gateway
#    - See consul-ingress.tf for ingress configuration
#    - Ingress gateway routes external traffic to orchestrator only
#
# 4. Direct External → Worker access is BLOCKED
#    - Workers are not exposed via ingress gateway
#    - Workers can only be reached through orchestrator
#
# To verify intentions are working:
#   kubectl exec -n consul consul-server-0 -- consul intention list
#   kubectl exec -n consul consul-server-0 -- consul intention check orchestrator-agent research-agent
#   kubectl exec -n consul consul-server-0 -- consul intention check research-agent code-agent
#
# The last command should return "Denied" demonstrating that worker-to-worker
# communication is blocked by the service mesh.
