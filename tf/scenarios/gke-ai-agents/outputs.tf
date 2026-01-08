output "cluster_summary" {
  value = join("\n", [
    "╔════════════════════════════════════════════════════════════╗",
    "║       AI Agent Orchestration with Consul Service Mesh     ║",
    "╚════════════════════════════════════════════════════════════╝",
    "",
    "### Consul Control Plane ###",
    "-----------------------------",
    var.create_consul_cluster ? "Consul UI                  : http://${module.consul.fqdn}:8500" : "Consul UI                  : (Not created)",
    var.create_consul_cluster ? "Consul Server IPs          : ${join(", ", module.consul.external_server_ips)}" : "Consul Server IPs          : (Not created)",
    "",
    "### GKE Cluster ###",
    "-------------------",
    "GKE Cluster Name           : ${local.gke_dataplane.kubernetes_cluster_name}",
    "GKE Region                 : ${var.region}",
    "Kubernetes Version         : ${var.kubernetes_version}",
    "Consul Namespace           : ${local.gke_dataplane.consul_namespace}",
    var.enable_ingress_gateway ? "Ingress Gateway IP         : ${local.gke_dataplane.consul_ingress_gateway_ip != null ? local.gke_dataplane.consul_ingress_gateway_ip : "Pending..."}" : "Ingress Gateway IP         : (Disabled)",
    "",
    "### AI Agents ###",
    "-----------------",
    var.deploy_agents ? "Orchestrator URL           : http://${local.gke_dataplane.consul_ingress_gateway_ip != null ? local.gke_dataplane.consul_ingress_gateway_ip : "<pending>"}:8080" : "Agents                     : (Not deployed)",
    var.deploy_agents ? "Agent Namespace            : ai-agents" : "",
    var.deploy_agents ? "Worker Agents              : research-agent, code-agent, data-agent, analysis-agent" : "",
    "",
    "### Quick Start Commands ###",
    "----------------------------",
    "# Get cluster credentials:",
    "gcloud container clusters get-credentials ${local.gke_dataplane.kubernetes_cluster_name} --region ${var.region} --project ${var.project_id}",
    "",
    "# View agent pods:",
    "kubectl get pods -n ai-agents",
    "",
    "# Test orchestrator health:",
    var.enable_ingress_gateway ? "curl http://${local.gke_dataplane.consul_ingress_gateway_ip != null ? local.gke_dataplane.consul_ingress_gateway_ip : "<pending>"}:8080/health" : "(Ingress gateway disabled)",
    "",
    "# Delegate task to workers:",
    var.enable_ingress_gateway ? "curl -X POST http://${local.gke_dataplane.consul_ingress_gateway_ip != null ? local.gke_dataplane.consul_ingress_gateway_ip : "<pending>"}:8080/analyze \\" : "",
    var.enable_ingress_gateway ? "  -H \"Content-Type: application/json\" \\" : "",
    var.enable_ingress_gateway ? "  -d '{\"task\": \"Analyze Q4 performance\"}'" : "",
    "",
    "# View Consul service mesh:",
    var.create_consul_cluster ? "open http://${module.consul.fqdn}:8500/ui/dc1/services" : "",
    "",
    "# Check service mesh intentions:",
    "kubectl exec -n consul consul-server-0 -- consul intention list",
    "",
    "### Demo: Test Blocked Worker-to-Worker Calls ###",
    "--------------------------------------------------",
    "# Deploy test pod as research-agent:",
    "kubectl run test-caller --rm -it --image=curlimages/curl \\",
    "  --namespace=ai-agents \\",
    "  --annotations=\"consul.hashicorp.com/connect-inject=true\" \\",
    "  --labels=\"app=research-agent\" \\",
    "  -- sh",
    "",
    "# Inside the pod, try to call another worker (should be blocked):",
    "curl http://code-agent.service.consul:8080/health",
    "",
    "### Documentation ###",
    "--------------------",
    "See README.md for complete demo instructions and troubleshooting.",
    ""
  ])
}

output "orchestrator_url" {
  value = var.enable_ingress_gateway && var.deploy_agents ? (
    local.gke_dataplane.consul_ingress_gateway_ip != null ?
    "http://${local.gke_dataplane.consul_ingress_gateway_ip}:8080" :
    "Pending - Run 'terraform output cluster_summary' after LoadBalancer provisioning"
  ) : "Not available (ingress gateway or agents disabled)"
  description = "URL to access the AI orchestrator agent"
}

output "consul_ui_url" {
  value       = var.create_consul_cluster ? "http://${module.consul.fqdn}:8500" : null
  description = "Consul UI URL"
}

output "consul_acl_bootstrap_token" {
  value     = var.initial_management_token
  sensitive = true
}

output "gke_cluster_name" {
  value       = local.gke_dataplane.kubernetes_cluster_name
  description = "GKE cluster name"
}

output "gke_cluster_region" {
  value       = var.region
  description = "GKE cluster region"
}

output "ingress_gateway_ip" {
  value       = var.enable_ingress_gateway ? local.gke_dataplane.consul_ingress_gateway_ip : null
  description = "External IP of Consul ingress gateway"
}

output "kubectl_config_command" {
  value       = "gcloud container clusters get-credentials ${local.gke_dataplane.kubernetes_cluster_name} --region ${var.region} --project ${var.project_id}"
  description = "Command to configure kubectl for this cluster"
}

output "test_commands" {
  value = var.enable_ingress_gateway && var.deploy_agents ? {
    health_check = "curl http://${local.gke_dataplane.consul_ingress_gateway_ip != null ? local.gke_dataplane.consul_ingress_gateway_ip : "<pending>"}:8080/health"
    analyze_task = "curl -X POST http://${local.gke_dataplane.consul_ingress_gateway_ip != null ? local.gke_dataplane.consul_ingress_gateway_ip : "<pending>"}:8080/analyze -H \"Content-Type: application/json\" -d '{\"task\": \"Analyze data\"}'"
    test_worker  = "curl -X POST http://${local.gke_dataplane.consul_ingress_gateway_ip != null ? local.gke_dataplane.consul_ingress_gateway_ip : "<pending>"}:8080/test-worker -H \"Content-Type: application/json\" -d '{\"worker\": \"research-agent\"}'"
  } : null
  description = "Useful test commands for the AI agent system"
}

output "ai_agents_namespace" {
  value       = var.deploy_agents && var.create_gke_cluster && length(module.ai_agents) > 0 ? module.ai_agents[0].namespace : null
  description = "Kubernetes namespace where AI agents are deployed"
}

output "ai_agents_service_endpoints" {
  value       = var.deploy_agents && var.create_gke_cluster && length(module.ai_agents) > 0 ? module.ai_agents[0].service_endpoints : null
  description = "Consul service endpoints for all AI agents"
}
