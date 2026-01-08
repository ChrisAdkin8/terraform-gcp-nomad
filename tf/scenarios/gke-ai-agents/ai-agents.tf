# AI Agents Mesh Module Deployment
#
# This file calls the ai-agents-mesh module to deploy the hierarchical
# AI agent orchestration system on the GKE cluster with Consul service mesh.

module "ai_agents" {
  count  = var.deploy_agents && var.create_gke_cluster ? 1 : 0
  source = "../../modules/ai-agents-mesh"

  # GCP Configuration
  project_id = var.project_id

  # Agent Configuration
  namespace             = "ai-agents"
  agent_image_tag       = var.agent_image_tag
  orchestrator_replicas = var.orchestrator_replicas
  worker_replicas       = var.worker_replicas

  # Service Mesh Configuration
  enable_ingress_gateway = var.enable_ingress_gateway

  # Resource Labels
  labels = local.common_labels

  # Ensure GKE cluster and Consul are ready before deploying agents
  depends_on = [
    module.gke_dataplane,
    data.http.consul_status
  ]
}
