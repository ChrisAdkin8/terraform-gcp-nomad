# Terraform GCP Nomad

[![License](https://img.shields.io/badge/License-Proprietary-blue.svg)](LICENCE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-purple.svg)](https://www.terraform.io/)
[![GCP](https://img.shields.io/badge/GCP-Supported-brightgreen.svg)](https://cloud.google.com/)

Deploy production-grade [HashiCorp Nomad](https://www.nomadproject.io/) and [Consul](https://www.consul.io/) clusters on Google Cloud Platform (GCP) with a complete observability stack using Packer and Terraform.

## Table of Contents

- [Disclaimer](#disclaimer)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Task Commands and Scenarios](#task-commands-and-scenarios)
- [Nomad-Consul Scenario](#nomad-consul-scenario)
- [Configuration](#configuration)
- [Module Reference](#module-reference)
- [Accessing the Cluster](#accessing-the-cluster)
- [Observability Stack](#observability-stack)
- [Multi-Datacenter Deployment](#multi-datacenter-deployment)
- [Customization](#customization)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Cleanup](#cleanup)
- [Contributing](#contributing)
- [References](#references)

---

## Disclaimer

> ⚠️ **This repository is designed for demonstration and learning purposes only.**

This deployment has **not** been hardened for production use regarding:

- **Security**: No TLS/mTLS, basic ACL configuration, broad firewall rules
- **High Availability**: Single-zone deployments, no cross-region failover
- **Performance**: Default machine types may not suit production workloads
- **Scalability**: Manual scaling, no autoscaling configured
- **Backup/DR**: No automated backup or disaster recovery procedures

For production deployments, refer to HashiCorp's [Production Reference Architecture](https://developer.hashicorp.com/nomad/tutorials/enterprise/production-reference-architecture-vm-with-consul).

---

## Features

| Feature | Description |
|---------|-------------|
| **Multi-DC Support** | Primary and secondary datacenter deployment |
| **Enterprise Ready** | Supports Nomad and Consul Enterprise licenses |
| **Service Mesh** | Consul-based service discovery and health checking |
| **Observability** | Complete Grafana/Loki/Alloy stack for logging |
| **Ingress** | Traefik reverse proxy with Consul integration |
| **Infrastructure as Code** | Fully automated with Terraform and Packer |
| **GCP Native** | Uses GCS, Cloud NAT, Managed Instance Groups |

---

## Architecture

### Deployment Overview

The deployment creates the following infrastructure:

| Component | Primary DC | Secondary DC |
|-----------|------------|--------------|
| Consul Servers | 1-3 nodes | 1-3 nodes |
| Nomad Servers | 1-3 nodes | 1-3 nodes |
| Nomad Clients | 3+ nodes (MIG) | 3+ nodes (MIG) |
| VPC Network | Shared across DCs ||
| GCS Bucket | Shared (configs + Loki storage) ||

### Architecture Diagram

![Reference Diagram](./docs/reference-diagram.png)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              GCP Project                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                           VPC Network                               │    │
│  ├─────────────────────────────────────────────────────────────────────┤    │
│  │                                                                     │    │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐   │    │
│  │  │  Consul Server   │  │  Consul Server   │  │  Consul Server   │   │    │
│  │  │    (node 1)      │  │    (node 2)      │  │    (node 3)      │   │    │
│  │  │     :8500        │  │     :8500        │  │     :8500        │   │    │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘   │    │
│  │           │                     │                     │             │    │
│  │           └─────────────────────┼─────────────────────┘             │    │
│  │                                 │                                   │    │
│  │                    ┌────────────┴────────────┐                      │    │
│  │                    │   Consul Cluster (Raft) │                      │    │
│  │                    └────────────┬────────────┘                      │    │
│  │                                 │                                   │    │
│  │  ┌──────────────────┐  ┌────────┴─────────┐  ┌──────────────────┐   │    │
│  │  │  Nomad Server    │  │  Nomad Server    │  │  Nomad Server    │   │    │
│  │  │    (node 1)      │  │    (node 2)      │  │    (node 3)      │   │    │
│  │  │     :4646        │  │     :4646        │  │     :4646        │   │    │
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘   │    │
│  │           │                     │                     │             │    │
│  │           └─────────────────────┼─────────────────────┘             │    │
│  │                                 │                                   │    │
│  │                    ┌────────────┴────────────┐                      │    │
│  │                    │   Nomad Cluster (Raft)  │                      │    │
│  │                    └────────────┬────────────┘                      │    │
│  │                                 │                                   │    │
│  │                                 ▼                                   │    │
│  │  ┌───────────────────────────────────────────────────────────────┐  │    │
│  │  │                      Nomad Clients (MIG)                      │  │    │
│  │  ├───────────────────────────────────────────────────────────────┤  │    │
│  │  │                                                               │  │    │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │  │    │
│  │  │  │   Traefik   │  │    Loki     │  │   Grafana           │    │  │    │
│  │  │  │   :80/:443  │  │   :3100     │  │   :3000             │    │  │    │
│  │  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │  │    │
│  │  │                                                               │  │    │
│  │  │  ┌─────────────┐  ┌─────────────────────────────────────┐     │  │    │
│  │  │  │ Alloy GW    │  │           Alloy Collectors          │     │  │    │
│  │  │  │  :12345     │  │                :12344               │     │  │    │
│  │  │  └─────────────┘  └─────────────────────────────────────┘     │  │    │
│  │  │                                                               │  │    │
│  │  └───────────────────────────────────────────────────────────────┘  │    │
│  │                                                                     │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                        GCS Bucket (Loki Storage)                    │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

```
                                    Internet
                                        │
                                        ▼
                    ┌───────────────────────────────────────┐
                    │              Traefik                  │
                    │  grafana.example.com → Grafana :3000  │
                    │  loki.example.com    → Loki    :3100  │
                    │  gateway.example.com → Alloy   :12346 │
                    └───────────────────┬───────────────────┘
                                        │
                ┌───────────────────────┼───────────────────────┐
                │                       │                       │
                ▼                       ▼                       ▼
       ┌────────────────┐      ┌────────────────┐      ┌────────────────┐
       │    Grafana     │      │     Loki       │◀─────│     Alloy      │
       │  (Dashboards)  │─────▶│  (Log Store)   │      │   (Gateway)    │
       │                │ Query│                │      │                │
       └────────────────┘      └───────┬────────┘      └────────────────┘
                                       │                       ▲
                                       │ Store                 │
                                       ▼                       │
                            ┌─────────────────────┐            │
                            │     GCS Bucket      │      Log Push from
                            │  ┌───────┬───────┐  │     Alloy Collectors
                            │  │Chunks │ Index │  │
                            │  └───────┴───────┘  │
                            └─────────────────────┘
```

---

## Prerequisites

### Required Tools

| Tool | Minimum Version | Installation |
|------|-----------------|--------------|
| Google Cloud CLI | Latest | [Install Guide](https://cloud.google.com/sdk/docs/install) |
| Terraform | ≥ 1.5.0 | [Install Guide](https://developer.hashicorp.com/terraform/install) |
| Packer | Latest | [Install Guide](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli) |
| Task | Latest | [Install Guide](https://taskfile.dev/installation/) |
| Nomad CLI | ≥ 1.10.x | [Install Guide](https://developer.hashicorp.com/nomad/install) |
| Consul CLI | ≥ 1.19.x | [Install Guide](https://developer.hashicorp.com/consul/install) |

### Software Versions (Pre-built in Images)

| Component | Version |
|-----------|---------|
| Nomad Enterprise | 1.10.5+ent |
| Consul Enterprise | 1.22.2+ent |
| AlmaLinux | 8.x |
| Google Cloud Ops Agent | Latest |

### GCP Requirements

#### Required APIs

Enable these APIs in your GCP project:

```bash
gcloud services enable \
  compute.googleapis.com \
  storage.googleapis.com \
  dns.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com
```

#### Required IAM Permissions

The deploying user/service account needs:

- `roles/compute.admin`
- `roles/storage.admin`
- `roles/iam.serviceAccountAdmin`
- `roles/iam.serviceAccountUser`
- `roles/dns.admin` (if using DNS features)

#### Required Files

| File | Description | Location |
|------|-------------|----------|
| `nomad.hclic` | Nomad Enterprise license | Repository root |
| `consul.hclic` | Consul Enterprise license | Repository root |

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/ChrisAdkin8/terraform-gcp-nomad.git
cd terraform-gcp-nomad
```

### 2. Authenticate with GCP

```bash
# Authenticate with GCP
gcloud auth login --update-adc

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Verify project
gcloud config get-value project
```

### 3. Add License Files

```bash
cp ~/path/to/nomad.hclic .
cp ~/path/to/consul.hclic .
```

### 4. Create terraform.tfvars file for none default variable values 

Create `tf/terraform.tfvars`:

```hcl
# Optional - Override defaults
region                   = "europe-west1"
secondary_region         = "europe-west2"
datacenter               = "dc1"
secondary_datacenter     = "dc2"

# Cluster sizing
consul_server_instances          = 1  # Use 3 for HA
nomad_server_instances           = 1  # Use 3 for HA
nomad_client_instances           = 3
secondary_consul_server_instances = 1
secondary_nomad_server_instances  = 1
secondary_nomad_client_instances  = 3

# Feature flags
create_nomad_cluster            = true
create_consul_cluster           = true
create_secondary_nomad_cluster  = true
create_secondary_consul_cluster = true
create_nomad_jobs               = true
create_dns_record               = false

# Machine types
nomad_client_machine_type = "e2-standard-4"
nomad_client_disk_size    = 20
```

### 5. Deploy Everything

**One-command deployment:**

```bash
task all
```

**Or step-by-step:**

```bash
# Build VM images
task packer

# Deploy infrastructure
task apply
```

### 6. Access Your Cluster

```bash
# View endpoints
task output
```

---

## Task Commands and Scenarios

This project uses [Task](https://taskfile.dev/) as a task runner to simplify complex workflows. The Taskfile provides a scenario-based deployment system that allows you to deploy different infrastructure configurations.

### Understanding Scenarios

A **scenario** is a specific deployment configuration that combines Terraform modules in different ways. Each scenario lives in its own directory under `tf/scenarios/`.

**Available Scenarios:**
- `nomad-consul` (default) - Full Nomad + Consul + Observability stack
- `gke-consul-dataplane` - GKE cluster with Consul service mesh connected to external Consul control plane
- `consul-only` - Standalone Consul control plane (referenced, not yet implemented)

**Scenario Selection:**
```bash
# Use default scenario (nomad-consul)
task apply

# Use explicit scenario
task apply SCENARIO=nomad-consul

# Use scenario shortcut
task nomad-consul        # Equivalent to: task apply SCENARIO=nomad-consul
task gke-dataplane       # Equivalent to: task apply SCENARIO=gke-consul-dataplane
task consul-only         # Equivalent to: task apply SCENARIO=consul-only
```

### Task Command Reference

#### Main Workflows

| Command | Description | What It Does |
|---------|-------------|--------------|
| `task all` | Complete deployment | Creates token → Builds Packer images → Deploys infrastructure |
| `task redeploy` | Full rebuild | Destroys infrastructure → Deletes images → Runs `task all` |

#### Token Management

The bootstrap token is critical for Consul ACL initialization and must be consistent across all components.

| Command | Description | Use Case |
|---------|-------------|----------|
| `task token:ensure` | Create token if missing | Automatically called by other tasks |
| `task token:show` | Display current token | View the bootstrap token value |
| `task token:rotate` | Generate new token | Requires full rebuild with `task redeploy` |
| `task token:export` | Show export command | For manual CLI operations |

**Token Workflow:**
```
task all
├─> task token:ensure          # Creates .bootstrap-token (UUID format)
├─> task packer
│   ├─> task packer:config     # Injects token into *.hcl.tmpl files
│   └─> task packer:build      # Builds images with token baked in
└─> task apply                 # Passes token via TF_VAR_initial_management_token
```

**Important:** The token is stored in `.bootstrap-token` at the repository root and is gitignored. Rotating the token requires rebuilding all images and redeploying infrastructure.

#### Scenario Shortcuts

Convenience commands that automatically select the correct scenario:

| Command | Scenario | Description |
|---------|----------|-------------|
| `task nomad-consul` | `nomad-consul` | Deploy full stack (Nomad + Consul + Observability) |
| `task gke-dataplane` | `gke-consul-dataplane` | Deploy GKE cluster with Consul service mesh |
| `task consul-only` | `consul-only` | Deploy Consul control plane only |

#### Terraform Operations

All Terraform commands support the `SCENARIO` variable:

| Command | Description | Example |
|---------|-------------|---------|
| `task apply` | Deploy/update infrastructure | `task apply SCENARIO=nomad-consul` |
| `task destroy` | Tear down infrastructure | `task destroy SCENARIO=nomad-consul` |
| `task plan` | Preview Terraform changes | `task plan SCENARIO=nomad-consul` |
| `task output` | Show Terraform outputs | `task output` |

**Behind the scenes:**
- `SCENARIO` defaults to `nomad-consul` if not specified
- Terraform operations run in `tf/scenarios/$SCENARIO/` directory
- Bootstrap token is automatically injected via environment variable

#### Packer Image Building

Packer builds are now **scenario-aware** - only required images are built for each scenario:

| Command | Description | What Gets Built |
|---------|-------------|-----------------|
| `task packer` | Build images for current scenario | Builds only what's needed for `SCENARIO` |
| `task packer SCENARIO=nomad-consul` | Build all images | consul-server, nomad-server, nomad-client |
| `task packer SCENARIO=gke-consul-dataplane` | Build Consul only | consul-server only |
| `task packer:config` | Generate configs from templates | Injects token into `*.hcl` files |
| `task packer:init` | Initialize Packer | Downloads required plugins |

**Scenario Image Requirements:**

| Scenario | Images Built | Reason |
|----------|--------------|--------|
| `nomad-consul` | consul-server<br>nomad-server<br>nomad-client | Full Nomad + Consul stack |
| `gke-consul-dataplane` | consul-server only | GKE uses containers, only Consul VMs needed |
| `consul-only` | consul-server only | Consul control plane only |

**Available Images:**
- `almalinux-nomad-server` - AlmaLinux 8 + Nomad Enterprise 1.10.5+ent
- `almalinux-nomad-client` - AlmaLinux 8 + Nomad Enterprise 1.10.5+ent + Docker
- `almalinux-consul-server` - AlmaLinux 8 + Consul Enterprise 1.22.2+ent

**Note:** This optimization significantly reduces build time for scenarios that don't require all images. For example, deploying `gke-consul-dataplane` now only builds 1 image instead of 3, saving ~10-15 minutes.

#### Utility Commands

| Command | Description | Use Case |
|---------|-------------|----------|
| `task clean` | Delete all custom GCP images | Cleanup before rebuild |
| `task clean:configs` | Remove generated config files | Keeps token file |
| `task clean:all` | Remove configs AND token | Nuclear option - full reset |
| `task list-scenarios` | List available scenarios | View deployment options |
| `task status` | Show environment status | Debug configuration issues |
| `task help` | Display help and workflows | Quick reference |

### How Task Commands Work with Scenarios

The Taskfile uses a dynamic variable system to route commands to the correct Terraform directory:

```yaml
vars:
  SCENARIO: '{{.SCENARIO | default "nomad-consul"}}'
  TF_DIR: 'tf/scenarios/{{.SCENARIO}}'
```

**Example Flow:**

1. **User runs:** `task apply SCENARIO=nomad-consul`
2. **Task sets:** `TF_DIR=tf/scenarios/nomad-consul`
3. **Task executes:**
   ```bash
   cd tf/scenarios/nomad-consul
   export TF_VAR_initial_management_token=$(cat .bootstrap-token)
   terraform init
   terraform apply -auto-approve
   ```

**Scenario-Aware Image Building:**

The `task packer` command now intelligently builds only the images required for your scenario:

```bash
# When deploying gke-consul-dataplane, only builds consul-server
task all SCENARIO=gke-consul-dataplane

# When deploying nomad-consul (default), builds all three images
task all SCENARIO=nomad-consul
```

This optimization significantly reduces build time - for example, `gke-consul-dataplane` builds 1 image instead of 3, saving ~10-15 minutes.

### Common Workflows

**First-time deployment:**
```bash
# Everything in one command (default nomad-consul scenario)
task all

# Or for a specific scenario (e.g., GKE with Consul)
task all SCENARIO=gke-consul-dataplane  # Only builds consul-server image

# Or step-by-step
task token:ensure    # Create bootstrap token
task packer          # Build VM images (scenario-aware)
task apply           # Deploy infrastructure (~10-15 minutes)
```

**Update existing infrastructure:**
```bash
# Preview changes
task plan

# Apply changes
task apply
```

**Rebuild after code changes:**
```bash
# If only Terraform changed
task apply

# If Packer configs changed
task packer          # Rebuild images
task apply           # Redeploy

# If token changed
task redeploy        # Full rebuild
```

**Switch between scenarios:**
```bash
# Deploy nomad-consul
task apply SCENARIO=nomad-consul

# Later, deploy consul-only (in different directory)
task apply SCENARIO=consul-only

# Both deployments can coexist (different tf state files)
```

**Token rotation (requires full rebuild):**
```bash
task token:rotate    # Interactive - generates new token
task redeploy        # Destroys, cleans images, rebuilds everything
```

**Cleanup:**
```bash
# Destroy infrastructure only
task destroy

# Destroy and clean images
task destroy
task clean

# Full cleanup including token
task destroy
task clean:all
```

---

## Nomad-Consul Scenario

The `nomad-consul` scenario is the default and most comprehensive deployment configuration. It creates a complete dual-datacenter HashiCorp stack with integrated observability.

### What It Deploys

The scenario creates a production-like infrastructure across two GCP regions with the following components:

#### Primary Datacenter (DC1) - europe-west1

**Consul Cluster:**
- 1-3 Consul server instances (configurable via `consul_server_instances`)
- Machine type: `e2-medium`
- Auto-discovery using GCP network tags (`consul-server`)
- ACL system initialized with bootstrap token from `.bootstrap-token`
- ACL policies created for Nomad integration
- External IPs for management access
- Service registration and health checking enabled

**Nomad Cluster:**
- **Servers:** 1-3 Nomad server instances (configurable via `nomad_server_instances`)
  - Machine type: `e2-medium`
  - Raft consensus for leader election
  - Integrated with Consul for service discovery

- **Clients:** 3+ Nomad client instances (configurable via `nomad_client_instances`)
  - Deployed as Managed Instance Group (MIG) for auto-scaling
  - Machine type: `e2-standard-4` (configurable via `nomad_client_machine_type`)
  - Preemptible instances enabled for cost savings
  - Docker runtime pre-installed
  - Disk size: 20 GB (configurable via `nomad_client_disk_size`)

**Observability Stack:**

The following components are deployed as Nomad jobs (when `create_nomad_jobs = true`):

- **Traefik** - Reverse proxy and ingress controller
  - Service discovery via Consul
  - HTTP (80), HTTPS (443), API (8080), Dashboard (8081)
  - Regional HTTP load balancers with external IPs
  - Health checks for high availability

- **Loki** - Log aggregation and storage
  - GCS backend for long-term log storage
  - Retention configurable via `log_retention_days`
  - HTTP API on port 3100
  - gRPC API on port 9096

- **Grafana** - Visualization and dashboards
  - Pre-configured Loki data source
  - Default admin password: `admin` (configurable via `grafana_admin_password`)
  - Port 3000
  - Custom dashboards for Nomad/Consul metrics

- **Alloy Gateway** - Centralized log receiver
  - Single instance receiving logs from all collectors
  - Forwards to Loki for storage
  - Port 12346 for log ingestion

- **Alloy Collectors** - Distributed log collection
  - Deployed as Nomad system job (runs on every client)
  - Collects system logs, Docker logs, and application logs
  - Forwards to Alloy Gateway
  - Port 12344 for collector endpoints

#### Secondary Datacenter (DC2) - europe-west2

Mirror configuration of DC1 with the following differences:
- Region: `europe-west2` (vs `europe-west1`)
- Datacenter name: `dc2` (vs `dc1`)
- Separate subnet: `10.128.128.0/24` (vs `10.128.64.0/24`)
- Independent Consul and Nomad clusters (not federated by default)
- Same machine types and scaling configuration

**Note:** Secondary datacenter can be disabled:
```hcl
# terraform.tfvars
create_secondary_nomad_cluster  = false
create_secondary_consul_cluster = false
```

#### Networking Infrastructure

**VPC and Subnets:**
- Single VPC shared across both datacenters
- Primary subnet: `10.128.64.0/24` (europe-west1)
- Secondary subnet: `10.128.128.0/24` (europe-west2)
- Proxy-only subnet DC1: `10.100.0.0/24` (for regional load balancers)
- Proxy-only subnet DC2: `10.101.0.0/24` (for regional load balancers)

**NAT and Routing:**
- Cloud NAT gateways in both regions for outbound internet access
- Cloud Routers for dynamic routing
- No public IPs on Nomad clients (NAT-only egress)

**Load Balancing:**
- Regional HTTP load balancers for Traefik:
  - Traefik API load balancer (port 8080)
  - Traefik UI load balancer (port 8081)
- Health checks configured for `/ping` endpoint
- Backend services targeting Nomad client MIG
- External IP addresses for public access

#### Security Configuration

**Firewall Rules:**
- **IAP SSH Access** - Port 22 from GCP IAP ranges (35.235.240.0/20)
- **Consul Management** - Port 8500 from your public IP (auto-detected)
- **Nomad Management** - Port 4646 from your public IP (auto-detected)
- **Internal Cluster Communication** - All ports between tagged instances
- **Load Balancer Health Checks** - GCP health checker ranges
- **Traefik Ingress** - Ports 80, 443, 8080, 8081 from configured CIDRs
- **Observability** - Ports 3000, 3100, 12344-12346 within VPC

**IAM and Service Accounts:**
- Dedicated service accounts for each component:
  - `consul-server@` - Consul servers with Compute read-only
  - `nomad-server@` - Nomad servers with Compute read-only
  - `nomad-client@` - Nomad clients with GCS read/write for Loki
- Least-privilege IAM scopes
- Workload Identity for GKE integration (future)

**ACL Tokens:**
- Consul ACL system bootstrapped with token from `.bootstrap-token`
- ACL policies created for:
  - Nomad server integration
  - Service registration
  - Health checking
- Token passed to Nomad via startup script

#### Storage

**GCS Bucket:**
- Single bucket created: `<name_prefix>-<project_id>-<datacenter>`
- Versioning disabled
- Uniform bucket-level access enabled
- Contains:
  - Packer configuration files (`*.hcl`)
  - Nomad Enterprise license (`nomad.hclic`)
  - Consul Enterprise license (`consul.hclic`)
  - Loki log chunks and index data (when observability enabled)

**Lifecycle:**
- Loki automatically manages chunk lifecycle
- Retention configured via `log_retention_days` (default: 30 days)
- Manual cleanup required for licenses/configs on destroy

#### Resource Labeling

All resources are tagged with consistent labels for cost tracking and organization:

**Common Labels:**
- `project` - Project identifier
- `environment` - Environment (dev, staging, prod)
- `managed_by` - Set to "terraform"
- `component` - Component name (consul, nomad, network, etc.)

**Datacenter-Specific Labels:**
- `datacenter` - DC identifier (dc1, dc2)
- `region` - GCP region name
- `role` - Role identifier (consul-server, nomad-server, nomad-client)

### Architecture Flow

**Deployment Sequence:**

1. **Network Module**
   - Creates VPC, subnets, NAT, routers
   - Sets up firewall rules
   - Establishes network foundation

2. **Consul Module** (if `create_consul_cluster = true`)
   - Deploys Consul server instances
   - Configures auto-discovery via GCP tags
   - Bootstraps ACL system with token
   - Creates ACL policies for Nomad

3. **Nomad Module** (if `create_nomad_cluster = true`)
   - Deploys Nomad server instances
   - Creates Nomad client MIG with auto-scaling
   - Integrates with Consul for service discovery
   - Sets up load balancers for Traefik

4. **Observability Module** (if `create_nomad_jobs = true`)
   - Waits for Nomad cluster to be healthy
   - Deploys Traefik job
   - Deploys Loki, Grafana, Alloy jobs
   - Configures service mesh integration

5. **Secondary Datacenter** (if enabled)
   - Repeats steps 2-4 in secondary region
   - Creates independent clusters

**Data Flow:**

```
Application Logs
    ↓
Alloy Collectors (system job on each node)
    ↓
Alloy Gateway (aggregation)
    ↓
Loki (log storage)
    ↓
GCS Bucket (long-term storage)
    ↑
Grafana (visualization via Loki API)
```

**Service Discovery Flow:**

```
Nomad Job → Register in Consul → Health Check → Traefik Discovery → Route Traffic
```

### Feature Flags

The scenario supports fine-grained control via feature flags:

| Flag | Default | Description |
|------|---------|-------------|
| `create_nomad_cluster` | `true` | Create primary Nomad cluster (DC1) |
| `create_consul_cluster` | `true` | Create primary Consul cluster (DC1) |
| `create_secondary_nomad_cluster` | `true` | Create secondary Nomad cluster (DC2) |
| `create_secondary_consul_cluster` | `true` | Create secondary Consul cluster (DC2) |
| `create_nomad_jobs` | `true` | Deploy observability stack as Nomad jobs |
| `create_dns_record` | `false` | Create Cloud DNS records (requires DNS zone) |

**Example Configurations:**

```hcl
# Single datacenter only
create_secondary_nomad_cluster  = false
create_secondary_consul_cluster = false

# Infrastructure only (no observability)
create_nomad_jobs = false

# Consul-only deployment
create_nomad_cluster = false
create_nomad_jobs    = false
```

### Accessing the Deployed Scenario

After deployment completes, use `task output` to view endpoints:

```bash
$ task output

# Example output:
consul_fqdn_dc1 = "consul-dc1-server-1.europe-west1-b.c.your-project.internal"
nomad_fqdn_dc1  = "nomad-dc1-server-1.europe-west1-b.c.your-project.internal"
traefik_api_ip  = "34.76.123.45"
traefik_ui_ip   = "34.76.123.46"
```

**Access URLs:**
- Nomad UI: `http://<nomad_fqdn_dc1>:4646`
- Consul UI: `http://<consul_fqdn_dc1>:8500`
- Traefik Dashboard: `http://<traefik_ui_ip>:8081`
- Grafana: `http://grafana.traefik-dc1.<project>.<domain>:8080` (via Traefik)
- Loki: `http://loki.traefik-dc1.<project>.<domain>:8080` (via Traefik)

**CLI Configuration:**

```bash
# Export environment variables
export NOMAD_ADDR="http://<nomad_fqdn_dc1>:4646"
export CONSUL_HTTP_ADDR="http://<consul_fqdn_dc1>:8500"
export CONSUL_HTTP_TOKEN="$(cat .bootstrap-token)"

# Verify connectivity
nomad server members
consul members
```

### Cost Considerations

Approximate monthly costs for default configuration (single datacenter):

| Component | Instances | Type | Monthly Cost (USD) |
|-----------|-----------|------|-------------------|
| Consul Servers | 1 | e2-medium | ~$25 |
| Nomad Servers | 1 | e2-medium | ~$25 |
| Nomad Clients (preemptible) | 3 | e2-standard-4 | ~$60 |
| Load Balancers | 2 | Regional HTTP LB | ~$40 |
| NAT Gateway | 1 | Cloud NAT | ~$45 |
| GCS Storage | 1 | Standard | ~$5-20 (depends on logs) |
| **Total** | | | **~$200-215/month** |

**Cost Optimization:**
- Reduce to 1 server instance for each component in dev (HA requires 3)
- Use smaller machine types for clients (`e2-medium` instead of `e2-standard-4`)
- Disable secondary datacenter
- Reduce Loki retention days
- Use preemptible instances (already enabled for clients)

---

## GKE Consul Dataplane Scenario

The `gke-consul-dataplane` scenario deploys a Google Kubernetes Engine (GKE) cluster with Consul service mesh capabilities, connected to an external Consul control plane.

### What It Deploys

This scenario creates a lightweight but complete Consul service mesh infrastructure:

#### Consul Control Plane
- **Consul Servers:** 1-3 instances (configurable)
- **Machine Type:** e2-medium
- **ACL:** Enabled with bootstrap token authentication
- **Service Discovery:** Automatic peer discovery via GCP tags
- **External Access:** Public IPs for management console

#### GKE Cluster with Consul Dataplane
- **Kubernetes Version:** 1.29 (configurable)
- **Node Count:** 3 nodes (configurable)
- **Machine Type:** e2-standard-4 (configurable)
- **Workload Identity:** Enabled for enhanced security
- **Consul Integration:**
  - Service mesh with automatic sidecar injection
  - mTLS communication between services
  - Service registration in Consul catalog (prefixed with `k8s-`)
  - DNS forwarding for `.consul` domains
  - Ingress gateway with external LoadBalancer (ports 80, 443, 8080, 8443)

#### Network Infrastructure
- **VPC:** Shared network for both Consul servers and GKE
- **Subnet:** 10.128.64.0/24 (configurable)
- **Firewall Rules:**
  - GKE nodes to Consul servers (ports 8500, 8502, 8301, 8600)
  - External access to ingress gateway
  - Management access from your IP

### Quick Deployment

```bash
# Ensure bootstrap token exists
task token:ensure

# Deploy the scenario
task gke-dataplane

# Or with explicit scenario name
task apply SCENARIO=gke-consul-dataplane
```

### Access Your Infrastructure

After deployment:

```bash
# View all endpoints
task output SCENARIO=gke-consul-dataplane

# Configure kubectl
gcloud container clusters get-credentials <cluster-name> --region <region>

# Check Consul dataplane pods
kubectl get pods -n consul

# Access Consul UI
open http://<consul-fqdn>:8500
```

### Testing Service Mesh

Deploy a test application with automatic sidecar injection:

```yaml
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

# Verify sidecar injection
kubectl get pod web -o jsonpath='{.spec.containers[*].name}'
# Should show: web consul-dataplane

# Check service in Consul
export CONSUL_HTTP_ADDR=http://<consul-fqdn>:8500
export CONSUL_HTTP_TOKEN=$(cat .bootstrap-token)
consul catalog services | grep k8s-
```

### Configuration Options

Key variables for the GKE scenario:

| Variable | Default | Description |
|----------|---------|-------------|
| `consul_server_instances` | `1` | Number of Consul servers (use 3 for HA) |
| `gke_cluster_name` | `gke-cluster` | Name for the GKE cluster |
| `gke_num_nodes` | `3` | Number of GKE worker nodes |
| `gke_machine_type` | `e2-standard-4` | Machine type for GKE nodes |
| `kubernetes_version` | `1.29` | Kubernetes version |
| `enable_service_mesh` | `true` | Enable automatic sidecar injection |
| `enable_ingress_gateway` | `true` | Deploy ingress gateway LoadBalancer |
| `helm_chart_version` | `1.3.0` | Consul Helm chart version |

**Example terraform.tfvars:**

```hcl
project_id              = "my-project"
region                  = "europe-west2"
datacenter              = "dc1"
consul_server_instances = 3
gke_num_nodes           = 3
environment             = "production"
```

### Use Cases

This scenario is ideal for:

- **Microservices on Kubernetes:** Deploy containerized applications with service mesh
- **Hybrid Cloud:** Connect Kubernetes workloads to services running on VMs
- **Service Discovery:** Use Consul as a universal service registry
- **Zero Trust Networking:** Implement mTLS between all services
- **Traffic Management:** Use Consul intentions for fine-grained access control

### Cost Considerations

Approximate monthly cost (default configuration):

| Component | Instances | Type | Monthly Cost (USD) |
|-----------|-----------|------|-------------------|
| Consul Servers | 1 | e2-medium | ~$25 |
| GKE Control Plane | 1 | Managed | ~$75 |
| GKE Nodes | 3 | e2-standard-4 | ~$180 |
| Load Balancer | 1 | Regional | ~$20 |
| **Total** | | | **~$300/month** |

For detailed scenario documentation, see `tf/scenarios/gke-consul-dataplane/README.md`.

---

## Configuration

### All Variables Reference

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_id` | string | *required* | GCP project ID |
| `initial_management_token` | string | *required* | Consul ACL bootstrap token |
| `region` | string | `europe-west1` | Primary GCP region |
| `secondary_region` | string | `europe-west2` | Secondary GCP region |
| `zone` | string | `null` | Specific zone (auto-selected if null) |
| `datacenter` | string | `dc1` | Primary datacenter name |
| `secondary_datacenter` | string | `dc2` | Secondary datacenter name |
| `consul_server_instances` | number | `1` | Primary Consul server count |
| `nomad_server_instances` | number | `1` | Primary Nomad server count |
| `nomad_client_instances` | number | `3` | Primary Nomad client count |
| `secondary_consul_server_instances` | number | `1` | Secondary Consul server count |
| `secondary_nomad_server_instances` | number | `1` | Secondary Nomad server count |
| `secondary_nomad_client_instances` | number | `3` | Secondary Nomad client count |
| `subnet_cidr` | string | `10.128.64.0/24` | Primary subnet CIDR |
| `secondary_subnet_cidr` | string | `10.128.128.0/24` | Secondary subnet CIDR |
| `name_prefix` | string | `hashicorp` | Resource naming prefix |
| `nomad_client_machine_type` | string | `e2-standard-4` | Nomad client VM type |
| `nomad_client_disk_size` | number | `20` | Nomad client disk GB |
| `create_nomad_cluster` | bool | `true` | Create primary Nomad cluster |
| `create_consul_cluster` | bool | `true` | Create primary Consul cluster |
| `create_secondary_nomad_cluster` | bool | `true` | Create secondary Nomad cluster |
| `create_secondary_consul_cluster` | bool | `true` | Create secondary Consul cluster |
| `create_nomad_jobs` | bool | `true` | Deploy Nomad jobs |
| `create_dns_record` | bool | `false` | Create DNS records |
| `grafana_admin_password` | string | `admin` | Grafana admin password |
| `environment` | string | `dev` | Environment name (dev, staging, prod) |
| `labels` | map(string) | `{}` | Additional labels to apply to all resources |
| `additional_allowed_cidrs` | list(string) | `[]` | Additional CIDR blocks to allow access |

### Network Configuration

Default CIDR allocations:

| Network | CIDR | Purpose |
|---------|------|---------|
| Primary Subnet | `10.128.64.0/24` | DC1 workloads |
| Secondary Subnet | `10.128.128.0/24` | DC2 workloads |
| Proxy-only (europe-west1) | `10.100.0.0/24` | Regional managed proxy |
| Proxy-only (europe-west2) | `10.101.0.0/24` | Regional managed proxy |

---

## Module Reference

### Project Structure

```
terraform-gcp-nomad/
├── README.md                           # This file
├── CHANGELOG.md                        # Version history
├── OBSERVABILITY.md                    # Observability stack documentation
├── LICENCE                             # License file
├── Taskfile.yml                        # Task runner configuration
│
├── nomad.hclic                         # Nomad Enterprise license (user-provided)
├── consul.hclic                        # Consul Enterprise license (user-provided)
│
├── docs/
│   └── reference-diagram.png           # Architecture diagram
│
├── packer/                             # VM image definitions
│   ├── variables.pkrvars.hcl           # Packer variables
│   ├── gcp-almalinux-nomad-server.pkr.hcl
│   ├── gcp-almalinux-nomad-client.pkr.hcl
│   ├── gcp-almalinux-consul-server.pkr.hcl
│   ├── configs/                        # Configuration templates
│   │   ├── nomad-server.hcl
│   │   ├── nomad-client.hcl
│   │   ├── consul-server.hcl
│   │   └── consul-client.hcl
│   └── scripts/                        # Provisioning scripts
│       ├── provision-nomad.sh
│       └── provision-consul.sh
│
└── tf/                                 # Terraform configurations
    ├── scenarios/                      # Deployment scenarios
    │   ├── nomad-consul/               # Full stack scenario
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   ├── providers.tf
    │   │   ├── versions.tf
    │   │   ├── locals.tf
    │   │   ├── data.tf
    │   │   ├── network.tf
    │   │   ├── consul.tf
    │   │   ├── nomad.tf
    │   │   ├── gcs.tf
    │   │   └── observability.tf
    │   │
    │   └── gke-consul-dataplane/       # GKE + Consul scenario
    │       ├── README.md
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── outputs.tf
    │       ├── providers.tf
    │       ├── versions.tf
    │       ├── locals.tf
    │       ├── data.tf
    │       ├── network.tf
    │       ├── consul.tf
    │       ├── gcs.tf
    │       ├── gke.tf
    │       └── terraform.tfvars.example
    │
    └── modules/                        # Reusable modules
        ├── network/                    # VPC, subnets, firewall
        │   ├── main.tf
        │   ├── firewall.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── locals.tf
        │
        ├── consul/                     # Consul cluster
        │   ├── main.tf
        │   ├── iam.tf
        │   ├── dns.tf
        │   ├── data.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── templates/
        │       └── consul-server-startup.sh
        │
        ├── nomad/                      # Nomad cluster
        │   ├── main.tf
        │   ├── mig.tf
        │   ├── lb.tf
        │   ├── iam.tf
        │   ├── dns.tf
        │   ├── data.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── templates/
        │       ├── nomad-startup.sh
        │       └── secondary-nomad-server-startup.sh
        │
        ├── observability/              # Grafana/Loki/Alloy stack
        │   ├── main.tf
        │   ├── dashboard.tf
        │   ├── gcs.tf
        │   ├── iam.tf
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── templates/
        │       ├── traefik.nomad.tpl
        │       ├── loki.nomad.tpl
        │       ├── grafana.nomad.tpl
        │       ├── gateway.nomad.tpl
        │       ├── collector.nomad.tpl
        │       └── prometheus.nomad.tpl
        │
        └── gke-consul-dataplane/       # GKE with Consul dataplane
            ├── README.md
            ├── cluster.tf              # GKE cluster configuration
            ├── consul-acl.tf           # Consul ACL auth method
            ├── consul-deploy.tf        # Helm release and secrets
            ├── data.tf                 # Data sources
            ├── firewall.tf             # Firewall rules
            ├── iam.tf                  # Service accounts
            ├── providers.tf
            ├── variables.tf
            ├── outputs.tf
            └── versions.tf
```

### Module: `network`

Creates the VPC infrastructure including subnets, NAT, routers, and firewall rules.

**Inputs:**
- `name_prefix`, `short_prefix` - Naming conventions
- `region`, `secondary_region` - GCP regions
- `subnet_cidr`, `secondary_subnet_cidr` - Network ranges
- `proxy_subnet_cidr`, `secondary_proxy_subnet_cidr` - Proxy-only subnet ranges
- `mgmt_cidr` - Management access CIDR
- `firewall_config` - Firewall rule configuration
- `labels` - Resource labels

**Outputs:**
- `subnet_self_link`, `secondary_subnet_self_link`
- `network_self_link`
- `health_checker_ranges`

**Recent Enhancements:**
- Cloud NAT now uses explicit subnet configuration (`LIST_OF_SUBNETWORKS`) for better control and security
- Each NAT gateway is configured with specific subnets rather than all subnets automatically

### Module: `consul`

Deploys Consul server cluster with IAM and optional DNS.

**Inputs:**
- `project_id`, `region`, `zone`
- `consul_server_instances` - Number of servers
- `datacenter` - Consul datacenter name
- `gcs_bucket` - Config/license storage
- `subnet_self_link` - Subnet for instances
- `labels` - Resource labels

**Outputs:**
- `fqdn` - DNS name for cluster
- `external_server_ips`, `internal_server_ips`

### Module: `nomad`

Deploys Nomad servers and client MIG with load balancers.

**Inputs:**
- `project_id`, `region`, `zone`
- `nomad_server_instances`, `nomad_client_instances`
- `datacenter` - Nomad datacenter name
- `nomad_client_machine_type`, `nomad_client_disk_size`
- `subnet_self_link` - Subnet for instances
- `allowed_ingress_cidrs` - CIDRs for Traefik access
- `labels` - Resource labels

**Outputs:**
- `fqdn` - DNS name for cluster
- `traefik_api_ip`, `traefik_ui_ip`
- `external_server_ips`, `internal_server_ips`
- `nomad_client_sa_email` - Service account for clients

### Module: `observability`

Deploys the Grafana-based observability stack as Nomad jobs.

**Inputs:**
- `project_id`, `region`, `datacenter`
- `nomad_addr` - Nomad API address
- `consul_token` - Consul ACL token
- `loki_bucket_name`, `log_retention_days`
- `nomad_client_sa_email` - Service account for GCS access
- `labels` - Resource labels

**Outputs:**
- `grafana_admin_password`

### Module: `gke-consul-dataplane`

Deploys a GKE cluster with Consul dataplane for service mesh integration with external Consul control plane.

**Inputs:**
- `project_id`, `region`, `cluster_name`
- `subnet_self_link` - Subnet for GKE cluster
- `consul_address` - External Consul server address (with port, e.g., "1.2.3.4:8500")
- `consul_internal_address` - Internal IP for direct Consul connectivity
- `consul_token` - ACL token for Consul authentication
- `consul_datacenter` - Consul datacenter name
- `enable_service_mesh` - Enable automatic sidecar injection
- `enable_ingress_gateway` - Deploy Consul ingress gateway
- `helm_chart_version` - Consul Helm chart version (default: 1.5.0)
- `global_log_level`, `client_log_level`, `connect_inject_log_level` - Logging configuration
- `global_log_json` - Enable JSON log format
- `kubernetes_version`, `machine_type`, `gke_num_nodes`
- `labels` - Resource labels

**Outputs:**
- `kubernetes_cluster_name`, `kubernetes_cluster_host`
- `consul_ingress_gateway_ip` - External IP of ingress gateway
- `consul_namespace` - Kubernetes namespace for Consul
- `gke_cluster_ca_certificate` - Cluster CA certificate (sensitive)

**Features:**
- Service mesh with automatic mTLS between services
- GKE services registered in Consul catalog
- Consul DNS for `.consul` domain resolution
- Ingress gateway with external LoadBalancer
- Firewall rules for GKE-to-Consul connectivity
- Configurable logging for debugging (global and component-specific)

**File Organization:**
- `cluster.tf` - GKE cluster and node pool configuration
- `consul-acl.tf` - Consul ACL authentication method and binding rules
- `consul-deploy.tf` - Kubernetes namespace, secrets, and Helm chart deployment
- `iam.tf` - GCP and Kubernetes service account management
- `firewall.tf` - Network security rules for Consul connectivity
- `data.tf` - Data source queries for cluster and network information

---

## Accessing the Cluster

### Endpoints

After deployment, `task output` displays:

| Service | Port | URL Pattern |
|---------|------|-------------|
| Nomad UI | 4646 | `http://<nomad-fqdn>:4646` |
| Consul UI | 8500 | `http://<consul-fqdn>:8500` |
| Traefik Dashboard | 8081 | `http://<traefik-ui-ip>:8081` |
| Grafana | 8080 | `http://grafana.traefik-dc1.<project>.<domain>:8080` |
| Loki | 8080 | `http://loki.traefik-dc1.<project>.<domain>:8080` |

### CLI Access

```bash
# Set environment variables
export NOMAD_ADDR="http://<nomad-fqdn>:4646"
export CONSUL_HTTP_ADDR="http://<consul-fqdn>:8500"
export CONSUL_HTTP_TOKEN="<your-acl-token>"

# Verify connectivity
nomad server members
consul members
```

### SSH Access

SSH is enabled via IAP (Identity-Aware Proxy):

```bash
gcloud compute ssh <instance-name> --zone=<zone> --tunnel-through-iap
```

---

## Observability Stack

The deployment includes a complete logging pipeline:

| Component | Role |
|-----------|------|
| **Alloy Collectors** | System job on each node collecting logs |
| **Alloy Gateway** | Centralized log receiver |
| **Loki** | Log aggregation and storage |
| **Grafana** | Visualization and dashboards |
| **GCS** | Long-term log storage backend |

For detailed observability documentation, see [OBSERVABILITY.md](OBSERVABILITY.md).

### Quick Verification

```bash
# Push test log
curl -X POST \
  -H "Content-Type: application/json" \
  "http://gateway-api.traefik-dc1.<project>.<domain>:8080/loki/api/v1/push" \
  -d '{
    "streams": [{
      "stream": { "job": "test", "source": "curl" },
      "values": [[ "'$(date +%s)000000000'", "Test log message" ]]
    }]
  }'

# Query logs
curl -G \
  --data-urlencode 'query={job="test"}' \
  "http://loki.traefik-dc1.<project>.<domain>:8080/loki/api/v1/query"
```

---

## Multi-Datacenter Deployment

This repo supports dual-datacenter deployments by default:

| Setting | Primary (DC1) | Secondary (DC2) |
|---------|---------------|-----------------|
| Region | `europe-west1` | `europe-west2` |
| Datacenter | `dc1` | `dc2` |
| Subnet | `10.128.64.0/24` | `10.128.128.0/24` |

### Disable Secondary DC

```hcl
# In terraform.tfvars
create_secondary_nomad_cluster  = false
create_secondary_consul_cluster = false
```

### Consul Cluster Federation

Both Consul clusters are deployed independently. For WAN federation, additional configuration is required (see [Consul WAN Federation](https://developer.hashicorp.com/consul/docs/connect/gateways/wan-federation)).

---

## Customization

### Update Nomad/Consul Versions

Edit the Packer scripts:

```bash
# Nomad version
vim packer/scripts/provision-nomad.sh
# Change: export NOMAD_VERSION="1.10.5+ent"

# Consul version
vim packer/scripts/provision-consul.sh
# Change: export CONSUL_VERSION="1.22.2+ent"
```

Rebuild images:

```bash
task packer
```

### Custom Machine Types

```hcl
# terraform.tfvars
nomad_client_machine_type = "n2-standard-8"
nomad_client_disk_size    = 100
```

### Task Commands

For a comprehensive list of all task commands and how they work with scenarios, see the [Task Commands and Scenarios](#task-commands-and-scenarios) section.

Quick reference:
```bash
task --list          # List all available tasks
task help            # Show common workflows
task status          # Show environment status
```

---

## Troubleshooting

### Common Issues

#### Packer Build Fails

**Problem:** Image build fails with authentication errors

**Solution:**
```bash
gcloud auth application-default login
gcloud auth login --update-adc
```

#### Terraform Apply Timeout

**Problem:** Consul/Nomad health checks timeout

**Solution:**
- Verify firewall rules allow internal communication
- Check VM startup script logs:
  ```bash
  gcloud compute ssh <instance> --zone=<zone> --tunnel-through-iap \
    --command="sudo journalctl -u google-startup-scripts -f"
  ```

#### Nomad Jobs Fail to Schedule

**Problem:** Jobs stay in pending state

**Solution:**
```bash
# Check client connectivity
nomad node status

# Verify Consul integration
nomad operator debug -duration 30s
```

#### GCS Bucket Already Exists

**Problem:** Terraform fails with bucket name conflict

**Solution:** Bucket names are globally unique. Use a unique `name_prefix` or delete existing bucket.

#### Consul ACL Bootstrap Fails

**Problem:** ACL bootstrap timeout or token rejected

**Solution:**
- Ensure token format is valid UUID
- Check Consul server logs:
  ```bash
  gcloud compute ssh <consul-server> --zone=<zone> --tunnel-through-iap \
    --command="sudo journalctl -u consul -f"
  ```

### Viewing Logs

```bash
# VM startup logs
gcloud compute ssh <instance> --zone=<zone> --tunnel-through-iap \
  --command="sudo journalctl -u google-startup-scripts"

# Nomad logs
gcloud compute ssh <instance> --zone=<zone> --tunnel-through-iap \
  --command="sudo journalctl -u nomad"

# Consul logs
gcloud compute ssh <instance> --zone=<zone> --tunnel-through-iap \
  --command="sudo journalctl -u consul"
```

---

## Security Considerations

### Current Limitations

| Area | Current State | Production Recommendation |
|------|---------------|---------------------------|
| **TLS** | Disabled | Enable TLS for all services |
| **mTLS** | Disabled | Enable Consul Connect |
| **ACLs** | Basic token | Implement fine-grained policies |
| **Firewall** | Wide open internally | Restrict to required ports |
| **External Access** | Public IPs | Use private IPs + bastion |
| **Secrets** | In tfvars | Use Secret Manager or Vault |
| **Audit Logging** | Not configured | Enable GCP audit logs |

### Sensitive Outputs

Sensitive values are marked in Terraform:

```bash
# View sensitive outputs
terraform output grafana_admin_password
terraform output consul_acl_bootstrap_token
```

### Firewall Rules

Created firewall rules:

| Rule | Ports | Source | Target |
|------|-------|--------|--------|
| IAP SSH | 22/tcp | GCP IAP ranges | All nodes |
| Consul Mgmt | 8500/tcp | Your IP | Consul servers |
| Nomad Mgmt | 4646/tcp | Your IP | Nomad servers |
| Internal Cluster | Various | Node tags | Node tags |
| Observability | 3000,3100,12344-12346/tcp | 10.128.0.0/16 | Nomad clients |

---

## Cleanup

### Destroy All Resources

```bash
task destroy
```

### Clean Packer Images

```bash
task clean
```

### Full Reset

```bash
task redeploy
```

### Manual Cleanup

```bash
# Delete specific resources
terraform -chdir=tf/scenarios/nomad-consul destroy -target=module.nomad

# List and delete images manually
gcloud compute images list --project $PROJECT_ID --no-standard-images
gcloud compute images delete <image-name> --project $PROJECT_ID
```

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `task apply`
5. Submit a pull request

### Code Style

- Terraform: Use `terraform fmt`
- Shell scripts: Use `shellcheck`
- Follow existing naming conventions

---

## Ports Reference

| Service | Port | Protocol | Purpose |
|---------|------|----------|---------|
| Nomad HTTP API | 4646 | TCP | UI and API access |
| Nomad RPC | 4647 | TCP | Internal RPC |
| Nomad Serf | 4648 | TCP/UDP | Cluster membership |
| Consul HTTP API | 8500 | TCP | UI and API access |
| Consul RPC | 8300 | TCP | Internal RPC |
| Consul Serf LAN | 8301 | TCP/UDP | LAN gossip |
| Consul Serf WAN | 8302 | TCP/UDP | WAN gossip |
| Consul DNS | 8600 | TCP/UDP | DNS interface |
| Traefik HTTP | 80 | TCP | HTTP ingress |
| Traefik HTTPS | 443 | TCP | HTTPS ingress |
| Traefik API | 8080 | TCP | API endpoint |
| Traefik Dashboard | 8081 | TCP | Dashboard UI |
| Loki HTTP | 3100 | TCP | Log push/query API |
| Loki gRPC | 9096 | TCP | gRPC API |
| Grafana | 3000 | TCP | Dashboard UI |
| Alloy Gateway | 12346 | TCP | Log ingestion |
| Alloy Collector | 12344 | TCP | Collector endpoint |

---

## References

- [Nomad Production Reference Architecture](https://developer.hashicorp.com/nomad/tutorials/enterprise/production-reference-architecture-vm-with-consul)
- [Nomad Documentation](https://developer.hashicorp.com/nomad/docs)
- [Consul Documentation](https://developer.hashicorp.com/consul/docs)
- [Packer Documentation](https://developer.hashicorp.com/packer/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Grafana Loki Documentation](https://grafana.com/docs/loki/latest/)
- [Grafana Alloy Documentation](https://grafana.com/docs/alloy/latest/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)

---

## License

This project is provided as-is for educational and demonstration purposes. See [LICENCE](LICENCE) for details.
