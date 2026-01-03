# GKE Consul Dataplane Scenario

This scenario deploys a complete Consul service mesh infrastructure consisting of:

1. **Consul Control Plane** - HashiCorp Consul servers for centralized service discovery and configuration
2. **GKE Cluster** - Google Kubernetes Engine cluster with Consul dataplane integration
3. **Networking** - VPC, subnets, firewall rules for secure communication
4. **GCS Storage** - Bucket for Consul configuration and license files

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         GCP Project                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                      VPC Network                           │ │
│  ├────────────────────────────────────────────────────────────┤ │
│  │                                                            │ │
│  │  ┌──────────────────┐  ┌──────────────────┐               │ │
│  │  │  Consul Server   │  │  Consul Server   │               │ │
│  │  │    (node 1)      │  │    (node 2)      │               │ │
│  │  │     :8500        │  │     :8500        │               │ │
│  │  └────────┬─────────┘  └────────┬─────────┘               │ │
│  │           └─────────────────────┼──────────                │ │
│  │                  ┌──────────────┴──────────┐               │ │
│  │                  │  Consul Control Plane   │               │ │
│  │                  └──────────┬──────────────┘               │ │
│  │                             │                              │ │
│  │                             │ gRPC/HTTP                    │ │
│  │                             ▼                              │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │              GKE Cluster (Dataplane)                 │  │ │
│  │  ├──────────────────────────────────────────────────────┤  │ │
│  │  │                                                      │  │ │
│  │  │  ┌────────────┐  ┌────────────┐  ┌────────────┐     │  │ │
│  │  │  │  App Pod   │  │  App Pod   │  │  App Pod   │     │  │ │
│  │  │  │  + Sidecar │  │  + Sidecar │  │  + Sidecar │     │  │ │
│  │  │  └────────────┘  └────────────┘  └────────────┘     │  │ │
│  │  │                                                      │  │ │
│  │  │  ┌────────────────────────────────────────────┐      │  │ │
│  │  │  │     Consul Ingress Gateway                 │      │  │ │
│  │  │  │     (LoadBalancer)                         │      │  │ │
│  │  │  └────────────────┬───────────────────────────┘      │  │ │
│  │  │                   │                                  │  │ │
│  │  └───────────────────┼──────────────────────────────────┘  │ │
│  │                      │                                     │ │
│  └──────────────────────┼─────────────────────────────────────┘ │
│                         │                                       │
│                         ▼                                       │
│                     Internet                                    │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           GCS Bucket (Configs & Licenses)                │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## What Gets Deployed

### Consul Control Plane
- **Consul Servers**: 1-3 instances (configurable)
- **Machine Type**: e2-medium
- **ACL**: Enabled with bootstrap token
- **Service Discovery**: Auto-discovery via GCP tags
- **External Access**: Public IPs for management

### GKE Cluster with Consul Dataplane
- **Kubernetes Version**: 1.29 (configurable)
- **Node Count**: 3 (configurable)
- **Machine Type**: e2-standard-4 (configurable)
- **Workload Identity**: Enabled
- **Consul Features**:
  - Service mesh with automatic sidecar injection
  - Service registration in Consul catalog
  - DNS forwarding for `.consul` domains
  - Ingress gateway with external LoadBalancer

### Networking
- **VPC**: Shared network for Consul and GKE
- **Subnet**: 10.128.64.0/24 (configurable)
- **Firewall Rules**:
  - GKE → Consul (ports 8500, 8502, 8301, 8600)
  - Ingress gateway → Internet (ports 80, 443, 8080, 8443)
  - Management access from your IP

## Prerequisites

- GCP project with required APIs enabled
- Terraform >= 1.5.0
- `gcloud` CLI authenticated
- Consul Enterprise license file (`consul.hclic` in repo root)
- Bootstrap token file (`.bootstrap-token` in repo root)

## Quick Start

### 1. Set Environment Variables

```bash
export TF_VAR_project_id="your-gcp-project-id"
export TF_VAR_initial_management_token="$(cat ../../../.bootstrap-token)"
```

### 2. Create terraform.tfvars (Optional)

```hcl
# terraform.tfvars
project_id     = "your-project-id"
region         = "europe-west2"
datacenter     = "dc1"

# Consul configuration
consul_server_instances = 3  # For HA, use 3

# GKE configuration
gke_cluster_name   = "gke-cluster"
gke_num_nodes      = 3
gke_machine_type   = "e2-standard-4"
kubernetes_version = "1.29"

# Features
enable_service_mesh    = true
enable_ingress_gateway = true

# Environment
environment = "dev"
labels = {
  team = "platform"
  cost_center = "engineering"
}
```

### 3. Deploy

Using Task (recommended):
```bash
# From repo root
task apply SCENARIO=gke-consul-dataplane

# Or use shortcut
task gke-dataplane
```

Using Terraform directly:
```bash
cd tf/scenarios/gke-consul-dataplane

# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply
```

### 4. Access Your Infrastructure

```bash
# View outputs
terraform output

# Configure kubectl
gcloud container clusters get-credentials <cluster-name> --region <region>

# Check Consul dataplane pods
kubectl get pods -n consul

# Access Consul UI
open http://<consul-fqdn>:8500
```

## Configuration

### Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `project_id` | GCP project ID | *required* |
| `region` | GCP region | `europe-west2` |
| `datacenter` | Consul datacenter name | `dc1` |
| `initial_management_token` | Consul ACL bootstrap token | *required* |
| `consul_server_instances` | Number of Consul servers | `1` |
| `gke_cluster_name` | GKE cluster name | `gke-cluster` |
| `gke_num_nodes` | Number of GKE nodes | `3` |
| `gke_machine_type` | GKE node machine type | `e2-standard-4` |
| `kubernetes_version` | Kubernetes version | `1.29` |
| `enable_service_mesh` | Enable service mesh | `true` |
| `enable_ingress_gateway` | Deploy ingress gateway | `true` |
| `helm_chart_version` | Consul Helm chart version | `1.3.0` |
| `create_consul_cluster` | Create Consul control plane | `true` |
| `create_gke_cluster` | Create GKE cluster | `true` |
| `environment` | Environment name | `dev` |
| `labels` | Additional resource labels | `{}` |

### Feature Flags

Disable components for testing or cost savings:

```hcl
# Consul only (no GKE)
create_gke_cluster = false

# GKE only (existing Consul)
create_consul_cluster = false

# Service discovery without service mesh
enable_service_mesh = false
enable_ingress_gateway = false
```

## Testing Service Mesh

### 1. Deploy a Test Application

```yaml
# test-app.yaml
apiVersion: v1
kind: Pod
metadata:
  name: web
  annotations:
    consul.hashicorp.com/connect-inject: "true"
spec:
  containers:
  - name: web
    image: nginx:latest
    ports:
    - containerPort: 80
```

```bash
kubectl apply -f test-app.yaml
```

### 2. Verify Sidecar Injection

```bash
kubectl get pod web -o jsonpath='{.spec.containers[*].name}'
# Should show: web consul-dataplane
```

### 3. Check Service in Consul

```bash
export CONSUL_HTTP_ADDR=http://<consul-fqdn>:8500
export CONSUL_HTTP_TOKEN=<bootstrap-token>

consul catalog services | grep k8s-
```

## Troubleshooting

### Consul Dataplane Not Starting

```bash
# Check Helm release
kubectl get pods -n consul

# View logs
kubectl logs -n consul <dataplane-pod> -c consul-dataplane

# Check Consul connectivity
kubectl exec -n consul <pod> -- consul members
```

### Service Not Registered in Consul

```bash
# Verify annotations
kubectl get pod <pod-name> -o yaml | grep consul.hashicorp.com

# Check sync catalog pod
kubectl logs -n consul -l app=consul,component=sync-catalog
```

### Ingress Gateway Not Accessible

```bash
# Check service
kubectl get svc -n consul consul-ingress-gateway

# View gateway logs
kubectl logs -n consul -l component=ingress-gateway
```

## Cost Estimate

Approximate monthly cost (default configuration):

| Component | Instances | Type | Monthly Cost (USD) |
|-----------|-----------|------|-------------------|
| Consul Servers | 1 | e2-medium | ~$25 |
| GKE Control Plane | 1 | Managed | ~$75 |
| GKE Nodes | 3 | e2-standard-4 | ~$180 |
| Load Balancer | 1 | Regional | ~$20 |
| GCS Storage | 1 | Standard | ~$5 |
| **Total** | | | **~$305/month** |

**Cost Optimization:**
- Use 1 Consul server for dev (HA requires 3)
- Reduce GKE nodes to 1-2
- Use smaller machine types (e2-medium)
- Use preemptible nodes for non-prod

## Cleanup

```bash
# Using Task
task destroy SCENARIO=gke-consul-dataplane

# Using Terraform
cd tf/scenarios/gke-consul-dataplane
terraform destroy
```

## Next Steps

- Deploy sample applications with service mesh
- Configure Consul intentions for service-to-service access control
- Set up monitoring and observability
- Enable TLS for production deployments
- Configure Consul WAN federation for multi-region

## References

- [Consul on Kubernetes](https://developer.hashicorp.com/consul/docs/k8s)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Consul Service Mesh](https://developer.hashicorp.com/consul/docs/connect)
