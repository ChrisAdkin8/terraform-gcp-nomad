# GKE Consul Dataplane Module

Terraform module for deploying a Google Kubernetes Engine (GKE) cluster with HashiCorp Consul dataplane integration. This module creates a GKE cluster and configures it to connect to an external Consul control plane for service mesh, service discovery, and DNS capabilities.

## Features

- **GKE Cluster Deployment** - Creates a production-ready GKE cluster with workload identity enabled
- **Consul Service Mesh** - Automatic sidecar injection for mTLS between services
- **Service Discovery** - GKE services automatically registered in Consul catalog
- **Consul DNS** - Kubernetes DNS forwarding for `.consul` domain resolution
- **Ingress Gateway** - External traffic routing via Consul ingress gateway with LoadBalancer
- **Flexible Networking** - Integrates with existing VPC infrastructure via subnet

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         GKE Cluster                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              Consul Namespace                         │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │                                                       │  │
│  │  ┌──────────────────┐      ┌──────────────────┐      │  │
│  │  │ Consul Dataplane │      │ Consul Dataplane │      │  │
│  │  │   (sidecar)      │◀─────│   (sidecar)      │      │  │
│  │  └────────┬─────────┘      └────────┬─────────┘      │  │
│  │           │                         │                │  │
│  │  ┌────────▼─────────┐      ┌────────▼─────────┐      │  │
│  │  │  App Container   │      │  App Container   │      │  │
│  │  └──────────────────┘      └──────────────────┘      │  │
│  │                                                       │  │
│  │  ┌──────────────────────────────────────────┐         │  │
│  │  │       Consul Ingress Gateway             │         │  │
│  │  │       (LoadBalancer: 80/443)             │         │  │
│  │  └────────────────┬─────────────────────────┘         │  │
│  │                   │                                   │  │
│  └───────────────────┼───────────────────────────────────┘  │
│                      │                                      │
└──────────────────────┼──────────────────────────────────────┘
                       │
                       ▼ External Traffic
                    Internet
                       ▲
                       │ gRPC/HTTP API (8500, 8502)
                       │
        ┌──────────────┴──────────────┐
        │  External Consul Servers    │
        │  (Control Plane)             │
        └─────────────────────────────┘
```

## Usage

### Basic Example

```hcl
module "gke_dataplane" {
  source = "../../modules/gke-consule-dataplane"

  # GKE Configuration
  project_id       = "my-gcp-project"
  region           = "europe-west2"
  cluster_name     = "my-gke-cluster"
  subnet_self_link = module.network.subnet_self_link

  # Consul Integration
  consul_address    = "consul-dc1.example.com"
  consul_token      = var.consul_acl_token
  consul_datacenter = "dc1"

  # Features
  enable_service_mesh    = true
  enable_ingress_gateway = true

  # Labeling
  labels = {
    environment = "production"
    team        = "platform"
  }
}
```

### Integration with Consul Module

```hcl
# Network foundation
module "network" {
  source = "../../modules/network"
  # ... network config ...
}

# Consul control plane
module "consul" {
  source           = "../../modules/consul"
  subnet_self_link = module.network.subnet_self_link
  # ... consul config ...
}

# GKE with Consul dataplane
module "gke_dataplane" {
  source = "../../modules/gke-consule-dataplane"

  project_id       = var.project_id
  region           = var.region
  cluster_name     = "my-cluster"
  subnet_self_link = module.network.subnet_self_link

  # Connect to Consul control plane
  consul_address    = module.consul.fqdn
  consul_token      = var.initial_management_token
  consul_datacenter = var.datacenter

  depends_on = [module.network, module.consul]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | ~> 6.0 |
| kubernetes | ~> 2.25 |
| helm | ~> 2.12 |

## Providers

| Name | Version |
|------|---------|
| google | ~> 6.0 |
| kubernetes | ~> 2.25 |
| helm | ~> 2.12 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP project ID | `string` | n/a | yes |
| region | GCP region to deploy GKE cluster to | `string` | `"europe-west2"` | no |
| cluster_name | Name for the GKE cluster | `string` | n/a | yes |
| subnet_self_link | Self-link of the GCP subnet to deploy GKE cluster into | `string` | n/a | yes |
| consul_address | Address of external Consul server (FQDN or IP) | `string` | n/a | yes |
| consul_token | ACL token for connecting to Consul | `string` | n/a | yes |
| consul_datacenter | Consul datacenter name | `string` | `"dc1"` | no |
| gke_num_nodes | Number of GKE nodes | `number` | `1` | no |
| machine_type | Machine type for Kubernetes node pool | `string` | `"e2-standard-8"` | no |
| kubernetes_version | Kubernetes version for the GKE cluster | `string` | `"1.22.12-gke.2300"` | no |
| enable_service_mesh | Enable Consul service mesh with sidecar injection | `bool` | `true` | no |
| enable_ingress_gateway | Deploy Consul ingress gateway | `bool` | `true` | no |
| helm_chart_version | Consul Helm chart version | `string` | `"1.3.0"` | no |
| labels | Labels to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| region | GCloud Region |
| project_id | GCloud Project ID |
| kubernetes_cluster_name | GKE Cluster Name |
| kubernetes_cluster_host | GKE Cluster Host |
| consul_ingress_gateway_ip | External IP of Consul ingress gateway LoadBalancer |
| consul_namespace | Kubernetes namespace where Consul is deployed |
| gke_cluster_ca_certificate | Base64 encoded CA certificate for GKE cluster (sensitive) |

## Features

### Service Mesh / Consul Connect

When `enable_service_mesh = true` (default), the module:

- Deploys Consul dataplane containers as sidecars to application pods
- Enables automatic mTLS between services
- Provides service-to-service authentication and encryption
- Integrates with Consul intentions for access control

**Example deployment with sidecar:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  annotations:
    consul.hashicorp.com/connect-inject: "true"
spec:
  containers:
  - name: my-app
    image: my-app:latest
    ports:
    - containerPort: 8080
```

The Consul dataplane sidecar is automatically injected.

### Service Discovery

The module configures Consul catalog sync to:

- Register all Kubernetes services in the Consul catalog
- Prefix GKE services with `k8s-` in Consul
- Enable Nomad workloads to discover GKE services
- Allow GKE services to discover Consul-registered services

**Query GKE services from Consul:**

```bash
consul catalog services | grep k8s-
```

### Consul DNS

Kubernetes DNS is configured to forward `.consul` domain queries to Consul servers:

```bash
# From within a pod
nslookup my-service.service.consul
nslookup my-service.service.dc1.consul
```

### Ingress Gateway

When `enable_ingress_gateway = true` (default), the module deploys a Consul ingress gateway with:

- LoadBalancer service type (GCP assigns external IP)
- Ports: 80, 443, 8080, 8443
- 2 replicas for high availability

**Access the gateway IP:**

```bash
terraform output consul_ingress_gateway_ip
```

## Networking

### Firewall Rules

The module creates the following firewall rules:

| Rule | Ports | Source | Target | Purpose |
|------|-------|--------|--------|---------|
| `<cluster>-to-consul-servers` | 8500, 8502, 8301, 8600 | GKE nodes | Consul servers | Dataplane→Consul communication |
| `<cluster>-ingress-gateway-external` | 80, 443, 8080, 8443 | 0.0.0.0/0 | GKE nodes | External traffic to ingress gateway |

### Required Network Tags

Ensure your Consul servers have the `consul-server` tag for firewall rules to work correctly.

## Security Considerations

### Current Configuration

- **TLS:** Disabled (matches Consul server configuration without TLS)
- **ACL:** Uses external token management
- **Workload Identity:** Enabled on GKE cluster
- **Service Account:** Dedicated Portworx service account with minimal permissions

### Production Recommendations

For production deployments:

1. **Enable TLS** on Consul servers and update module configuration
2. **Use fine-grained ACL policies** instead of management token
3. **Restrict ingress gateway source ranges** instead of `0.0.0.0/0`
4. **Enable GKE cluster security features:**
   - Binary authorization
   - Pod security policies
   - Network policies
5. **Use Secret Manager** for Consul token storage

## Troubleshooting

### Verify Helm Deployment

```bash
kubectl config use-context <cluster-name>
helm list -n consul
```

### Check Consul Dataplane Pods

```bash
kubectl get pods -n consul
kubectl logs -n consul <pod-name> -c consul-dataplane
```

### Test Consul Connectivity

```bash
kubectl exec -n consul <pod-name> -- consul members
kubectl exec -n consul <pod-name> -- consul catalog services
```

### Verify Service Mesh Injection

```bash
# Deploy test app
kubectl apply -f test-app.yaml

# Check for dataplane sidecar
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].name}'
# Should show: my-app consul-dataplane
```

### Check DNS Resolution

```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Inside the pod:
nslookup consul.service.consul
```

## Examples

### Minimal Configuration

```hcl
module "gke_dataplane" {
  source = "../../modules/gke-consule-dataplane"

  project_id       = "my-project"
  cluster_name     = "gke-cluster"
  subnet_self_link = "projects/my-project/regions/us-central1/subnetworks/my-subnet"

  consul_address = "10.128.64.2"
  consul_token   = "c02f2cc9-aff4-473e-9069-8018b48ac76f"
}
```

### Service Discovery Only (No Service Mesh)

```hcl
module "gke_dataplane" {
  source = "../../modules/gke-consule-dataplane"

  project_id       = "my-project"
  cluster_name     = "gke-cluster"
  subnet_self_link = module.network.subnet_self_link

  consul_address    = module.consul.fqdn
  consul_token      = var.consul_token
  consul_datacenter = "dc1"

  # Disable service mesh
  enable_service_mesh    = false
  enable_ingress_gateway = false
}
```

### Custom Helm Chart Version

```hcl
module "gke_dataplane" {
  source = "../../modules/gke-consule-dataplane"

  project_id       = "my-project"
  cluster_name     = "gke-cluster"
  subnet_self_link = module.network.subnet_self_link

  consul_address    = module.consul.fqdn
  consul_token      = var.consul_token
  helm_chart_version = "1.4.0"
}
```

## Resources Created

The module creates the following GCP and Kubernetes resources:

### GCP Resources

- GKE Cluster with workload identity
- GKE Node Pool (e2-standard-8 by default)
- Service Account for Portworx
- IAM bindings for service accounts
- Firewall rules for Consul connectivity
- Firewall rules for ingress gateway (optional)

### Kubernetes Resources

- Namespace: `consul`
- Secret: Consul ACL token
- Helm Release: Consul dataplane
- Service: Ingress gateway LoadBalancer (optional)

## References

- [Consul on Kubernetes](https://developer.hashicorp.com/consul/docs/k8s)
- [Consul Dataplane](https://developer.hashicorp.com/consul/docs/architecture/control-plane/dataplane)
- [Consul Helm Chart](https://developer.hashicorp.com/consul/docs/k8s/helm)
- [GKE Documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)

## License

This module is part of the terraform-gcp-nomad project. See the main project LICENSE for details.
