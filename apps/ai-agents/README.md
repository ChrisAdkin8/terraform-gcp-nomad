# AI Agent Applications

This directory contains the application code for the hierarchical AI agent orchestration demo. The agents are simple Flask-based microservices that demonstrate service mesh communication patterns with Consul.

## Architecture

```
┌─────────────────────────────────────────────┐
│         Orchestrator Agent                  │
│  - Receives external requests               │
│  - Delegates to specialized workers         │
│  - Aggregates results                       │
└────────────┬────────────────────────────────┘
             │
    ┌────────┼────────┬────────────┬──────────┐
    │        │        │            │          │
    ▼        ▼        ▼            ▼          ▼
┌─────────┐ ┌─────┐ ┌──────────┐ ┌──────────┐
│Research │ │Code │ │  Data    │ │ Analysis │
│ Agent   │ │Agent│ │  Agent   │ │  Agent   │
└─────────┘ └─────┘ └──────────┘ └──────────┘
```

## Components

### Orchestrator Agent

**Location:** `orchestrator/`

The orchestrator is the entry point for external requests. It:
- Receives task requests via HTTP POST
- Delegates work to specialized worker agents
- Calls workers via Consul service discovery DNS
- Aggregates results from all workers
- Returns consolidated response

**Endpoints:**
- `GET /` - API information
- `GET /health` - Health check
- `POST /analyze` - Main task delegation endpoint
- `POST /test-worker` - Test connectivity to specific worker

### Worker Agents

**Location:** `worker/`

Workers are specialized agents that process specific types of tasks. There are 4 worker types:
1. **Research Agent** - Information gathering and research
2. **Code Agent** - Code generation and analysis
3. **Data Agent** - Data processing and transformation
4. **Analysis Agent** - Analytical tasks and insights

All workers share the same codebase but are differentiated by the `AGENT_TYPE` environment variable.

**Endpoints:**
- `GET /` - Worker information
- `GET /health` - Health check
- `POST /process` - Process task from orchestrator
- `POST /test-peer-call` - Test worker-to-worker calls (should be blocked)

## Building Images

### Prerequisites

- Docker installed and running
- `gcloud` CLI configured with authentication
- GCP project with Container Registry or Artifact Registry enabled

### Build Script

```bash
# Make the build script executable (if not already)
chmod +x build.sh

# Build and push images
./build.sh <your-gcp-project-id> [image-tag]

# Examples:
./build.sh my-project latest
./build.sh my-project v1.0.0
```

This will:
1. Enable required GCP APIs
2. Configure Docker authentication
3. Build orchestrator image: `gcr.io/<project>/orchestrator-agent:<tag>`
4. Build worker image: `gcr.io/<project>/worker-agent:<tag>`
5. Push both images to Google Container Registry

## Local Development

### Running Locally with Docker

**Orchestrator:**
```bash
cd orchestrator
docker build -t orchestrator-agent .
docker run -p 8080:8080 \
  -e AGENT_TYPE=orchestrator \
  -e WORKER_SERVICES=research-agent,code-agent,data-agent,analysis-agent \
  orchestrator-agent
```

**Worker:**
```bash
cd worker
docker build -t worker-agent .
docker run -p 8081:8080 \
  -e AGENT_TYPE=research \
  worker-agent
```

### Running with Python

**Prerequisites:**
- Python 3.11+
- pip

**Orchestrator:**
```bash
cd orchestrator
pip install -r requirements.txt
export AGENT_TYPE=orchestrator
export WORKER_SERVICES=research-agent,code-agent,data-agent,analysis-agent
python app.py
```

**Worker:**
```bash
cd worker
pip install -r requirements.txt
export AGENT_TYPE=research
python app.py
```

## Testing Locally

### Test Orchestrator Health
```bash
curl http://localhost:8080/health
```

### Test Task Delegation
```bash
curl -X POST http://localhost:8080/analyze \
  -H "Content-Type: application/json" \
  -d '{"task": "Analyze Q4 performance data"}'
```

### Test Worker Health
```bash
curl http://localhost:8081/health
```

### Test Worker Processing
```bash
curl -X POST http://localhost:8081/process \
  -H "Content-Type: application/json" \
  -d '{"task": "Research market trends", "from": "orchestrator"}'
```

## Environment Variables

### Orchestrator
- `AGENT_TYPE` - Agent identifier (default: `orchestrator`)
- `WORKER_SERVICES` - Comma-separated list of worker services (default: `research-agent,code-agent,data-agent,analysis-agent`)
- `CONSUL_DOMAIN` - Consul DNS domain (default: `service.consul`)

### Worker
- `AGENT_TYPE` - Worker type: `research`, `code`, `data`, or `analysis` (required)
- `CONSUL_DOMAIN` - Consul DNS domain (default: `service.consul`)

## Dependencies

Both agents use:
- **Flask 3.0.0** - Web framework
- **Werkzeug 3.0.1** - WSGI utility library
- **requests 2.31.0** - HTTP client library

## Integration with Terraform

These container images are deployed to GKE via the Terraform scenario at `tf/scenarios/gke-ai-agents/`.

The Terraform configuration:
1. Creates a GKE cluster with Consul dataplane
2. Deploys the orchestrator (2 replicas)
3. Deploys 4 worker agents (1 replica each)
4. Configures Consul service mesh intentions
5. Sets up ingress gateway for external access

See `tf/scenarios/gke-ai-agents/README.md` for deployment instructions.

## Service Mesh Security

### Allowed Communication
- External → Orchestrator (via Ingress Gateway)
- Orchestrator → All Workers
- Workers → Orchestrator (for responses)

### Blocked Communication
- External → Workers (direct access)
- Worker → Worker (lateral movement)

This security model is enforced by Consul service mesh intentions, demonstrating zero-trust networking for AI agent systems.

## Extending the Agents

### Adding Real AI Capabilities

To integrate with actual LLM services:

1. **Add AI SDK dependencies** (requirements.txt):
   ```
   openai==1.10.0
   anthropic==0.18.0
   langchain==0.1.0
   ```

2. **Modify worker processing** (worker/app.py):
   ```python
   from openai import OpenAI

   client = OpenAI(api_key=os.getenv('OPENAI_API_KEY'))

   def generate_agent_response(task):
       response = client.chat.completions.create(
           model="gpt-4",
           messages=[{"role": "user", "content": task}]
       )
       return response.choices[0].message.content
   ```

3. **Add secrets to Kubernetes**:
   ```bash
   kubectl create secret generic ai-api-keys \
     --from-literal=openai-key=sk-... \
     -n ai-agents
   ```

4. **Update Terraform deployment** (agents.tf):
   ```hcl
   env {
     name = "OPENAI_API_KEY"
     value_from {
       secret_key_ref {
         name = "ai-api-keys"
         key  = "openai-key"
       }
     }
   }
   ```

### Adding New Worker Types

1. **Update orchestrator** WORKER_SERVICES environment variable
2. **Add new Kubernetes deployment** in `tf/scenarios/gke-ai-agents/agents.tf`
3. **Add Consul intention** in `consul-intentions.tf`
4. **Update agent capabilities** in `worker/app.py`

## Troubleshooting

### Connection Refused Errors

If orchestrator cannot reach workers:
1. Check Consul service registration: `consul catalog services`
2. Verify DNS resolution: `nslookup research-agent.service.consul`
3. Check Consul intentions: `consul intention list`
4. View dataplane sidecar logs: `kubectl logs <pod> -c consul-dataplane`

### Image Pull Errors

If Kubernetes cannot pull images:
1. Verify images exist: `gcloud container images list --project=<project-id>`
2. Check GKE node pool service account has `roles/storage.objectViewer`
3. Ensure Workload Identity is configured (handled by Terraform module)

### Service Mesh Issues

If intentions aren't working:
1. Verify sidecar injection: `kubectl get pod <pod> -o jsonpath='{.spec.containers[*].name}'`
2. Check service defaults: `consul config read -kind service-defaults -name orchestrator-agent`
3. Verify intentions: `consul intention get orchestrator-agent research-agent`

## License

This code is part of the terraform-gcp-nomad project.
