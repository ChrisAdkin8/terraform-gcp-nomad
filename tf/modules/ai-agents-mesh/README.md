# AI Agents Mesh Module

This module deploys a hierarchical AI agent orchestration system on Kubernetes with Consul service mesh security guardrails.

## Overview

The module creates:
- **1 Orchestrator Agent** - Receives external requests and delegates to workers
- **4 Worker Agents** - Specialized agents (research, code, data, analysis)
- **Consul Service Mesh Intentions** - Enforces zero-trust communication policies
- **Consul Ingress Gateway Configuration** - Routes external traffic to orchestrator (optional)

## Architecture

```
External Traffic → Ingress Gateway → Orchestrator Agent
                                         ↓ ↓ ↓ ↓
                                   [Research] [Code] [Data] [Analysis]
                                      ✗ ←→ ✗ ←→ ✗ ←→ ✗ (blocked)
```

### Security Model

The module implements a zero-trust security model using Consul service mesh intentions:

- **ALLOWED**: Orchestrator → All Workers
- **ALLOWED**: External → Orchestrator (via ingress gateway)
- **BLOCKED**: Worker → Worker (lateral movement prevention)
- **BLOCKED**: Direct External → Workers

## Prerequisites

Before using this module, you must have:
1. A GKE cluster with Consul dataplane deployed (use `gke-consul-dataplane` module)
2. Consul server cluster with ACL enabled
3. Kubernetes and Consul providers configured
4. Agent Docker images pushed to GCR (see `apps/ai-agents/build.sh`)

## Usage

### Basic Example

```hcl
module "ai_agents" {
  source = "../../modules/ai-agents-mesh"

  project_id           = var.project_id
  agent_image_tag      = var.agent_image_tag
  orchestrator_replicas = 2
  worker_replicas       = 1
  enable_ingress_gateway = true

  labels = {
    environment = "production"
    team        = "ai-platform"
  }
}
```

### Complete Example with GKE and Consul

```hcl
# Deploy Consul servers
module "consul" {
  source = "../../modules/consul"
  # ... consul configuration
}

# Deploy GKE with Consul dataplane
module "gke_dataplane" {
  source = "../../modules/gke-consul-dataplane"

  project_id             = var.project_id
  cluster_name           = "ai-agents-cluster"
  consul_server_addresses = module.consul.external_server_ips
  # ... other configuration
}

# Deploy AI agents with service mesh
module "ai_agents" {
  source = "../../modules/ai-agents-mesh"

  project_id            = var.project_id
  namespace             = "ai-agents"
  agent_image_tag       = "v1.0.0"
  orchestrator_replicas = 2
  worker_replicas       = 1
  enable_ingress_gateway = true

  labels = {
    environment = "production"
    team        = "ai-platform"
    managed_by  = "terraform"
  }

  depends_on = [module.gke_dataplane]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `project_id` | GCP project ID where agent images are stored in GCR | `string` | n/a | yes |
| `namespace` | Kubernetes namespace for AI agents | `string` | `"ai-agents"` | no |
| `agent_image_tag` | Docker image tag for agent containers | `string` | `"latest"` | no |
| `orchestrator_replicas` | Number of orchestrator agent replicas | `number` | `2` | no |
| `worker_replicas` | Number of replicas for each worker agent | `number` | `1` | no |
| `enable_ingress_gateway` | Enable Consul ingress gateway configuration for external access | `bool` | `true` | no |
| `labels` | Labels to apply to all Kubernetes resources | `map(string)` | `{}` | no |
| `consul_http_addr` | Consul HTTP API address for health checks (optional) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| `namespace` | The Kubernetes namespace where AI agents are deployed |
| `orchestrator_service_name` | Name of the orchestrator Kubernetes service |
| `worker_service_names` | Map of worker agent service names |
| `service_endpoints` | Consul service endpoints for all agents |

## Features

### Hierarchical Agent Communication

The orchestrator agent:
- Receives tasks via HTTP API
- Discovers workers via Consul DNS (`{worker}.service.consul`)
- Delegates tasks to specialized workers
- Aggregates results from all workers
- Returns combined response to client

Worker agents:
- Process tasks from orchestrator
- Return specialized results
- Cannot communicate with other workers (blocked by service mesh)

### Zero-Trust Service Mesh

Consul service mesh intentions enforce strict communication policies:

1. **Service Defaults**: All agents configured with `protocol = http`
2. **Service Intentions**:
   - Orchestrator → Research Agent: ALLOW
   - Orchestrator → Code Agent: ALLOW
   - Orchestrator → Data Agent: ALLOW
   - Orchestrator → Analysis Agent: ALLOW
   - All other sources → Workers: DENY

3. **Ingress Gateway** (if enabled):
   - Routes external traffic to orchestrator on port 8080
   - Workers are not exposed externally
   - Service router provides advanced routing capabilities

### mTLS Between Services

All agent-to-agent communication is automatically encrypted using mTLS provided by Consul service mesh sidecars.

## Agent Applications

The module requires pre-built Docker images for orchestrator and worker agents:

- **Orchestrator**: `gcr.io/{project-id}/orchestrator-agent:{tag}`
- **Workers**: `gcr.io/{project-id}/worker-agent:{tag}`

To build the images:

```bash
cd apps/ai-agents
./build.sh YOUR_PROJECT_ID v1.0.0
```

See `apps/ai-agents/README.md` for application documentation and extension examples.

## Testing Service Mesh Intentions

After deploying the module, verify intentions are working:

```bash
# Get cluster credentials
gcloud container clusters get-credentials CLUSTER_NAME --region REGION

# List all intentions
kubectl exec -n consul consul-server-0 -- consul intention list

# Check orchestrator → worker (should be ALLOWED)
kubectl exec -n consul consul-server-0 -- consul intention check orchestrator-agent research-agent

# Check worker → worker (should be DENIED)
kubectl exec -n consul consul-server-0 -- consul intention check research-agent code-agent

# Test from a pod (should be blocked)
kubectl run test-caller --rm -it --image=curlimages/curl \
  --namespace=ai-agents \
  --annotations="consul.hashicorp.com/connect-inject=true" \
  --labels="app=research-agent" \
  -- sh

# Inside the pod, try calling another worker:
curl http://code-agent.service.consul:8080/health  # Should fail
```

## Resources Created

The module creates the following resources:

### Kubernetes Resources
- 1 namespace (`ai-agents` by default)
- 5 deployments (1 orchestrator + 4 workers)
- 5 services (ClusterIP)

### Consul Resources
- 5 service-defaults config entries (protocol configuration)
- 4 service-intentions config entries (security policies)
- 1 ingress-gateway config entry (external access, if enabled)
- 1 service-router config entry (traffic routing, if enabled)

## Limitations

- Agent images must be pre-built and pushed to GCR
- Module requires existing GKE cluster with Consul dataplane
- Ingress gateway configuration assumes gateway is deployed by `gke-consul-dataplane` module
- Worker types (research, code, data, analysis) are fixed

## Extension Examples

### Adding a New Worker Type

To add a fifth worker (e.g., "security-agent"):

1. Add deployment and service in `agents.tf`
2. Add service-defaults in `intentions.tf`
3. Add service-intention allowing orchestrator → security-agent
4. Update orchestrator's `WORKER_SERVICES` environment variable

### Customizing Resource Limits

Override resource requests/limits by editing `agents.tf`:

```hcl
resources {
  requests = {
    cpu    = "200m"
    memory = "256Mi"
  }
  limits = {
    cpu    = "1000m"
    memory = "1Gi"
  }
}
```

### Adding Real AI Capabilities

The demo applications use mock responses. To integrate with real LLMs:

1. Update `apps/ai-agents/worker/app.py` to call OpenAI/Anthropic APIs
2. Add API keys as Kubernetes secrets
3. Mount secrets in worker deployments
4. Rebuild and push images

See `apps/ai-agents/README.md` for detailed integration examples.

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl get pods -n ai-agents

# View pod logs
kubectl logs -n ai-agents deployment/orchestrator-agent
kubectl logs -n ai-agents deployment/research-agent

# Check sidecar injection
kubectl describe pod -n ai-agents PODNAME | grep consul
```

### Intentions not working

```bash
# Verify intentions exist in Consul
kubectl exec -n consul consul-server-0 -- consul intention list

# Check service registration
kubectl exec -n consul consul-server-0 -- consul catalog services

# Verify service mesh is enabled
kubectl get pods -n ai-agents -o jsonpath='{.items[*].spec.containers[*].name}'
# Should show both app container and envoy-sidecar
```

### Cannot access orchestrator via ingress

```bash
# Get ingress gateway IP
kubectl get svc -n consul ingress-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Check ingress gateway config
kubectl exec -n consul consul-server-0 -- consul config read -kind ingress-gateway -name ingress-gateway

# Test from within cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://orchestrator-agent.ai-agents.svc.cluster.local:8080/health
```

## Security Considerations

1. **Public Ingress**: By default, the ingress gateway is exposed to `0.0.0.0/0`. In production, restrict to specific CIDR ranges using firewall rules.

2. **API Keys**: Store LLM API keys in Kubernetes secrets, not environment variables or code.

3. **RBAC**: Apply Kubernetes RBAC policies to restrict access to the `ai-agents` namespace.

4. **Network Policies**: Consider adding Kubernetes NetworkPolicies as an additional security layer beyond Consul intentions.

5. **Audit Logging**: Enable Consul audit logging to track intention checks and service-to-service calls.

## License

This module is part of the terraform-gcp-nomad project.
