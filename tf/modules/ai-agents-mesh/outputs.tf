# AI Agents Mesh Module Outputs

output "namespace" {
  description = "The Kubernetes namespace where AI agents are deployed"
  value       = kubernetes_namespace.ai_agents.metadata[0].name
}

output "orchestrator_service_name" {
  description = "Name of the orchestrator Kubernetes service"
  value       = kubernetes_service.orchestrator.metadata[0].name
}

output "worker_service_names" {
  description = "Names of all worker agent Kubernetes services"
  value = {
    research = kubernetes_service.research_agent.metadata[0].name
    code     = kubernetes_service.code_agent.metadata[0].name
    data     = kubernetes_service.data_agent.metadata[0].name
    analysis = kubernetes_service.analysis_agent.metadata[0].name
  }
}

output "service_endpoints" {
  description = "Consul service endpoints for all agents"
  value = {
    orchestrator = "orchestrator-agent.service.consul:8080"
    research     = "research-agent.service.consul:8080"
    code         = "code-agent.service.consul:8080"
    data         = "data-agent.service.consul:8080"
    analysis     = "analysis-agent.service.consul:8080"
  }
}
