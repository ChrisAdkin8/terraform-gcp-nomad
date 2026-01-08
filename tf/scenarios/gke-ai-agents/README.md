# AI Agent Orchestration with Consul Service Mesh Guardrails

This scenario demonstrates hierarchical AI agent orchestration on Google Kubernetes Engine (GKE) with strict communication policies enforced by HashiCorp Consul service mesh. It showcases how to implement zero-trust networking for AI agent systems with explicit allow/deny rules.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [What Gets Deployed](#what-gets-deployed)
- [Security Model](#security-model)
- [Demo Scenarios](#demo-scenarios)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)
- [Cost Estimate](#cost-estimate)
- [Cleanup](#cleanup)

## Overview

This scenario creates a complete AI agent hierarchy with:
- **1 Orchestrator Agent** - Entry point for external requests, delegates work to specialized workers
- **4 Worker Agents** - Research, Code, Data, and Analysis specialists
- **Consul Service Mesh** - Enforces communication policies with intentions
- **Zero-Trust Security** - Only explicitly allowed communication paths are permitted

### Key Features

✅ **Hierarchical Agent Pattern** - Orchestrator delegates to workers, workers cannot communicate directly
✅ **Service Mesh Security** - Consul intentions enforce zero-trust networking
✅ **Service Discovery** - Agents discover each other via Consul DNS
✅ **External Access Control** - Only orchestrator exposed via ingress gateway
✅ **Observable** - Full visibility into agent communication via Consul UI
✅ **Infrastructure as Code** - Complete deployment with Terraform

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      External User Traffic                       │
│                            (HTTP)                                │
└──────────────────────────┬───────────────────────────────────────┘
                           │
                           ▼
                ┌──────────────────────┐
                │  Consul Ingress      │
                │  Gateway             │
                │  (LoadBalancer)      │
                └──────────┬───────────┘
                           │
                           ▼
                ┌──────────────────────┐
                │  orchestrator-agent  │◄─── Consul Dataplane Sidecar
                │  (2 replicas)        │
                └──────────┬───────────┘
                           │
                ┌──────────┼──────────┬──────────┬──────────┐
                │          │          │          │          │
                ▼          ▼          ▼          ▼          ▼
        ┌───────────┐ ┌────────┐ ┌────────┐ ┌─────────┐
        │ research  │ │  code  │ │  data  │ │analysis │
        │  -agent   │ │ -agent │ │ -agent │ │ -agent  │
        └───────────┘ └────────┘ └────────┘ └─────────┘
              ▲           ▲          ▲          ▲
              │           │          │          │
              └───────────┴──────────┴──────────┘
                Each with Consul Dataplane Sidecar

        Worker-to-Worker Communication: ✗ BLOCKED by Consul Intentions
        Orchestrator-to-Worker:         ✓ ALLOWED by Consul Intentions
        External-to-Worker:             ✗ BLOCKED (not exposed)
```

### Communication Flow

1. **External Request** → Ingress Gateway → Orchestrator
2. **Orchestrator** → Delegates task → Worker Agents (via Consul DNS)
3. **Worker** → Processes task → Returns response to Orchestrator
4. **Orchestrator** → Aggregates results → Returns to user

Worker agents **cannot** call each other directly - this is enforced by Consul service mesh intentions.

## Prerequisites

### Required Tools

- **GCP Account** with billing enabled
- **Terraform** >= 1.5.0 ([Install](https://www.terraform.io/downloads))
- **gcloud CLI** configured with authentication ([Install](https://cloud.google.com/sdk/docs/install))
- **kubectl** for Kubernetes management ([Install](https://kubernetes.io/docs/tasks/tools/))
- **Docker** for building agent images ([Install](https://docs.docker.com/get-docker/))

### GCP Project Setup

```bash
# Set your project
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# Enable required APIs
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable dns.googleapis.com

# Authenticate Docker with GCR
gcloud auth configure-docker gcr.io
```

### Required Files

- **Consul License** - Place `consul.hclic` in repository root (if using Enterprise features)
- **Bootstrap Token** - Generate with `uuidgen` or use existing token

## Quick Start

### 1. Build Agent Images

```bash
# Navigate to applications directory
cd apps/ai-agents

# Build and push images to GCR
./build.sh your-gcp-project-id latest

# Verify images were pushed
gcloud container images list --project=your-gcp-project-id
```

### 2. Configure Terraform

```bash
# Navigate to scenario directory
cd ../../tf/scenarios/gke-ai-agents

# Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Minimum required configuration:**

```hcl
project_id               = "your-gcp-project-id"
region                   = "europe-west2"
initial_management_token = "your-consul-bootstrap-token"  # Generate with: uuidgen
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy (takes ~10-15 minutes)
terraform apply

# View deployment summary
terraform output cluster_summary
```

### 4. Configure kubectl

```bash
# Get cluster credentials
gcloud container clusters get-credentials $(terraform output -raw gke_cluster_name) \
  --region $(terraform output -raw gke_cluster_region)

# Verify connection
kubectl get nodes
kubectl get pods -n consul
kubectl get pods -n ai-agents
```

### 5. Test the System

```bash
# Get orchestrator URL
ORCHESTRATOR_URL=$(terraform output -raw orchestrator_url)

# Health check
curl $ORCHESTRATOR_URL/health

# Delegate task to workers
curl -X POST $ORCHESTRATOR_URL/analyze \
  -H "Content-Type: application/json" \
  -d '{"task": "Analyze Q4 2025 performance metrics"}'
```

## What Gets Deployed

### GCP Resources

| Resource | Description | Default |
|----------|-------------|---------|
| VPC Network | Isolated network for all resources | 10.128.64.0/24 |
| GCS Bucket | Stores Consul configs and licenses | Auto-generated name |
| Consul Servers | Control plane for service mesh | 1 instance (e2-medium) |
| GKE Cluster | Kubernetes cluster with workload identity | 3 nodes (e2-standard-4) |
| Load Balancer | External access to ingress gateway | Regional LB |
| Firewall Rules | Consul access, ingress gateway access | Managed by Terraform |

### Kubernetes Resources

| Namespace | Resources | Description |
|-----------|-----------|-------------|
| `consul` | Helm release, dataplane pods, ingress gateway | Consul service mesh components |
| `ai-agents` | 5 deployments, 5 services | Orchestrator + 4 workers |

### AI Agents

| Agent | Role | Replicas | Capability |
|-------|------|----------|------------|
| orchestrator-agent | Coordinator | 2 | Receives requests, delegates to workers |
| research-agent | Worker | 1 | Research and information gathering |
| code-agent | Worker | 1 | Code generation and analysis |
| data-agent | Worker | 1 | Data processing and transformation |
| analysis-agent | Worker | 1 | Analytical tasks and insights |

## Security Model

### Allowed Communication Paths

```
✓ External → Ingress Gateway → Orchestrator
✓ Orchestrator → Research Agent
✓ Orchestrator → Code Agent
✓ Orchestrator → Data Agent
✓ Orchestrator → Analysis Agent
✓ Workers → Orchestrator (responses)
```

### Blocked Communication Paths

```
✗ External → Workers (direct access)
✗ Research Agent → Code Agent
✗ Research Agent → Data Agent
✗ Code Agent → Analysis Agent
✗ Worker → Worker (any combination)
```

### How It Works

1. **Service Defaults** - Each agent has `Protocol: http` configured
2. **Service Intentions** - Explicit allow rules for orchestrator → workers
3. **Default Deny** - All other communication is denied by default
4. **mTLS** - Consul dataplane sidecars encrypt all service-to-service traffic
5. **Ingress Gateway** - Only orchestrator is exposed externally

## Demo Scenarios

### Scenario 1: Successful Task Delegation

**Objective:** Demonstrate orchestrator successfully delegating work to all workers.

```bash
ORCHESTRATOR_URL=$(terraform output -raw orchestrator_url)

curl -X POST $ORCHESTRATOR_URL/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "task": "Analyze company growth trends for Q4 2025",
    "timeout": 10
  }' | jq
```

**Expected Output:**
```json
{
  "orchestrator": "orchestrator",
  "status": "completed",
  "task": "Analyze company growth trends for Q4 2025",
  "workers_succeeded": 4,
  "workers_failed": 0,
  "results": {
    "research-agent": {
      "agent": "research",
      "result": "Research findings for 'Analyze...'...",
      "status": "completed"
    },
    "code-agent": { "..." },
    "data-agent": { "..." },
    "analysis-agent": { "..." }
  }
}
```

### Scenario 2: Blocked Worker-to-Worker Communication

**Objective:** Demonstrate that worker agents cannot call each other directly.

```bash
# Deploy test pod with research-agent identity
kubectl run test-caller --rm -it \
  --image=curlimages/curl \
  --namespace=ai-agents \
  --annotations="consul.hashicorp.com/connect-inject=true" \
  --labels="app=research-agent" \
  -- sh

# Inside the pod, attempt to call code-agent
curl http://code-agent.service.consul:8080/health --max-time 5
```

**Expected Behavior:**
- Connection times out or is refused
- This demonstrates Consul intentions blocking lateral movement
- Worker agents can only be called by the orchestrator

**Exit the test pod:**
```bash
exit
```

### Scenario 3: View Service Mesh in Consul UI

**Objective:** Visualize the service mesh topology and intentions.

```bash
# Get Consul UI URL
terraform output consul_ui_url

# Open in browser
open $(terraform output -raw consul_ui_url)
```

**In Consul UI:**
1. Navigate to **Services** → See all registered agents
2. Click **orchestrator-agent** → View upstreams and downstreams
3. Navigate to **Intentions** → See allow/deny rules
4. Navigate to **Topology** → Visualize service dependencies

### Scenario 4: Test Individual Worker

**Objective:** Verify orchestrator can call a specific worker.

```bash
ORCHESTRATOR_URL=$(terraform output -raw orchestrator_url)

curl -X POST $ORCHESTRATOR_URL/test-worker \
  -H "Content-Type: application/json" \
  -d '{"worker": "research-agent"}' | jq
```

**Expected Output:**
```json
{
  "status": "success",
  "worker": "research-agent",
  "response": {
    "status": "healthy",
    "agent": "research",
    "capability": "Performs research and information gathering tasks"
  }
}
```

### Scenario 5: Verify Intentions via CLI

**Objective:** Inspect Consul intentions from command line.

```bash
# List all intentions
kubectl exec -n consul consul-server-0 -- \
  consul intention list

# Check specific intention (should be "allowed")
kubectl exec -n consul consul-server-0 -- \
  consul intention check orchestrator-agent research-agent

# Check worker-to-worker (should be "denied")
kubectl exec -n consul consul-server-0 -- \
  consul intention check research-agent code-agent
```

## Configuration

### Variable Reference

See [variables.tf](./variables.tf) for complete list. Key variables:

```hcl
# Minimum required
project_id               = "your-project"
initial_management_token = "bootstrap-token"

# Recommended for production
consul_server_instances  = 3          # HA cluster
gke_num_nodes            = 3          # Multi-AZ
orchestrator_replicas    = 2          # Load balancing
environment              = "prod"

# Cost optimization for dev/testing
consul_server_instances  = 1
gke_num_nodes            = 1
gke_machine_type         = "e2-medium"
orchestrator_replicas    = 1
worker_replicas          = 1
```

### Feature Flags

```hcl
create_consul_cluster  = true   # false = use existing Consul
create_gke_cluster     = true   # false = use existing GKE
deploy_agents          = true   # false = infrastructure only
enable_service_mesh    = true   # Required for intentions
enable_ingress_gateway = true   # Required for external access
```

## Troubleshooting

### Agents Not Starting

**Symptom:** Pods stuck in `ImagePullBackOff` or `ErrImagePull`

**Solution:**
```bash
# Verify images exist in GCR
gcloud container images list --project=your-project-id

# Check GKE node pool has permission to pull images
# (Workload Identity should be configured automatically by module)

# Rebuild and push images
cd apps/ai-agents
./build.sh your-project-id latest
```

### Orchestrator Cannot Reach Workers

**Symptom:** `curl $ORCHESTRATOR_URL/analyze` returns errors for workers

**Possible Causes:**
1. **DNS not working** - Consul DNS not properly configured
   ```bash
   kubectl exec -n ai-agents deployment/orchestrator-agent -- \
     nslookup research-agent.service.consul
   ```

2. **Intentions not applied** - Service mesh intentions missing
   ```bash
   kubectl exec -n consul consul-server-0 -- \
     consul intention list
   ```

3. **Sidecar not injected** - Pods missing Consul dataplane sidecar
   ```bash
   kubectl get pod -n ai-agents -l app=research-agent -o jsonpath='{.items[0].spec.containers[*].name}'
   # Should show: research consul-dataplane
   ```

### Worker-to-Worker Calls Succeeding (Should Be Blocked)

**Symptom:** Test in Scenario 2 succeeds when it should fail

**Solution:**
```bash
# Verify intentions are created
terraform state list | grep consul_config_entry

# Re-apply intentions
terraform apply -target=consul_config_entry.intention_orchestrator_to_research

# Check intention in Consul
kubectl exec -n consul consul-server-0 -- \
  consul intention check research-agent code-agent
# Should output: "Denied"
```

### Ingress Gateway IP Pending

**Symptom:** `terraform output ingress_gateway_ip` shows null

**Solution:**
```bash
# Check LoadBalancer service status
kubectl get svc -n consul consul-ingress-gateway

# If "pending", check GCP quotas
gcloud compute project-info describe --project=your-project-id

# Wait a few minutes for GCP to provision LoadBalancer
terraform refresh
terraform output ingress_gateway_ip
```

### Consul UI Not Accessible

**Symptom:** Cannot access Consul UI at the URL from outputs

**Solution:**
```bash
# Check Consul server is running
kubectl get pods -n consul -l component=server

# Verify firewall rule allows your IP
# (Automatically created for your current IP during deployment)

# Get your current IP
curl https://ipv4.icanhazip.com

# If IP changed, update firewall rule or use port-forward
kubectl port-forward -n consul svc/consul-ui 8500:443
# Then access: http://localhost:8500
```

## Cost Estimate

Approximate monthly costs (default configuration, europe-west2 region):

| Component | Resource | Specs | Monthly Cost (USD) |
|-----------|----------|-------|-------------------|
| Consul Servers | 1x e2-medium | 2 vCPU, 4 GB | ~$25 |
| GKE Control Plane | Managed | GKE Standard | ~$75 |
| GKE Nodes | 3x e2-standard-4 | 4 vCPU, 16 GB each | ~$180 |
| Load Balancer | Regional LB | Forwarding rules + traffic | ~$20 |
| GCS Storage | Standard | <1 GB | ~$1 |
| Networking | Egress traffic | Varies | ~$10 |
| **Total** | | | **~$311/month** |

### Cost Optimization Tips

**Development/Testing (Minimal):**
```hcl
consul_server_instances = 1
gke_num_nodes           = 1
gke_machine_type        = "e2-medium"
orchestrator_replicas   = 1
worker_replicas         = 1
```
**Estimated cost:** ~$100/month

**Production (HA):**
```hcl
consul_server_instances = 3     # Quorum
gke_num_nodes           = 5     # Multi-AZ + redundancy
gke_machine_type        = "e2-standard-8"
orchestrator_replicas   = 3
worker_replicas         = 2
```
**Estimated cost:** ~$800/month

**Additional savings:**
- Use Preemptible nodes for non-prod environments
- Enable GKE Autopilot for automatic scaling
- Use Spot VMs for Consul servers in dev
- Schedule cluster shutdown during non-business hours

## Cleanup

### Destroy All Resources

```bash
cd tf/scenarios/gke-ai-agents

# Destroy infrastructure
terraform destroy

# Verify all resources deleted
gcloud compute instances list --project=your-project-id
gcloud container clusters list --project=your-project-id
```

### Delete Container Images

```bash
# List images
gcloud container images list --project=your-project-id

# Delete agent images
gcloud container images delete gcr.io/your-project-id/orchestrator-agent:latest --quiet
gcloud container images delete gcr.io/your-project-id/worker-agent:latest --quiet
```

## Next Steps

### Extend with Real AI Capabilities

1. **Integrate LLM APIs** - Add OpenAI, Anthropic, or other LLM integrations
2. **Add Retrieval** - Implement RAG with vector databases
3. **Enhance Workers** - Specialize agents with domain-specific tools
4. **Add Observability** - Integrate Prometheus, Grafana, Jaeger

See [apps/ai-agents/README.md](../../../apps/ai-agents/README.md) for code extension examples.

### Production Hardening

- [ ] Enable TLS for Consul (mTLS between services)
- [ ] Implement fine-grained ACL policies per agent
- [ ] Add rate limiting per worker type
- [ ] Configure circuit breakers
- [ ] Set up monitoring and alerting
- [ ] Implement secret management (GCP Secret Manager)
- [ ] Enable GKE Binary Authorization
- [ ] Configure Pod Security Policies
- [ ] Set up backup and disaster recovery

### Multi-Region Deployment

- Deploy to multiple GCP regions
- Configure Consul WAN federation
- Implement global load balancing
- Add cross-region failover

## References

- [Consul Service Mesh](https://developer.hashicorp.com/consul/docs/connect)
- [Consul on Kubernetes](https://developer.hashicorp.com/consul/docs/k8s)
- [Consul Intentions](https://developer.hashicorp.com/consul/docs/connect/intentions)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Hierarchical Agent Patterns](https://www.anthropic.com/research/building-effective-agents)

## Support

For issues or questions:
- Review [Troubleshooting](#troubleshooting) section
- Check application logs: `kubectl logs -n ai-agents deployment/orchestrator-agent`
- Inspect Consul logs: `kubectl logs -n consul consul-server-0`
- File an issue in the project repository

## License

This scenario is part of the terraform-gcp-nomad project.
