x§# Terraform GCP Nomad

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
| Consul Enterprise | 1.19.2+ent |
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

### 4. Create Configuration

Create `tf/terraform.tfvars`:

```hcl
# Required
project_id               = "your-gcp-project-id"
initial_management_token = "your-consul-acl-token"  # Generate with: uuidgen

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
    │   └── nomad-consul/               # Main scenario
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── outputs.tf
    │       ├── providers.tf
    │       ├── versions.tf
    │       ├── locals.tf
    │       ├── data.tf
    │       ├── network.tf
    │       ├── consul.tf
    │       ├── nomad.tf
    │       ├── gcs.tf
    │       ├── observability.tf
    │       └── terraform.tfvars
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
        └── observability/              # Grafana/Loki/Alloy stack
            ├── main.tf
            ├── dashboard.tf
            ├── gcs.tf
            ├── iam.tf
            ├── variables.tf
            ├── outputs.tf
            └── templates/
                ├── traefik.nomad.tpl
                ├── loki.nomad.tpl
                ├── grafana.nomad.tpl
                ├── gateway.nomad.tpl
                ├── collector.nomad.tpl
                └── prometheus.nomad.tpl
```

### Module: `network`

Creates the VPC infrastructure including subnets, NAT, routers, and firewall rules.

**Inputs:**
- `name_prefix`, `short_prefix` - Naming conventions
- `region`, `secondary_region` - GCP regions
- `subnet_cidr`, `secondary_subnet_cidr` - Network ranges
- `mgmt_cidr` - Management access CIDR

**Outputs:**
- `subnet_self_link`, `secondary_subnet_self_link`
- `network_self_link`

### Module: `consul`

Deploys Consul server cluster with IAM and optional DNS.

**Inputs:**
- `project_id`, `region`, `zone`
- `consul_server_instances` - Number of servers
- `datacenter` - Consul datacenter name
- `gcs_bucket` - Config/license storage

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

**Outputs:**
- `fqdn` - DNS name for cluster
- `traefik_api_ip`, `traefik_ui_ip`
- `external_server_ips`, `internal_server_ips`
- `nomad_client_sa_email` - Service account for clients

### Module: `observability`

Deploys the Grafana-based observability stack as Nomad jobs.

**Inputs:**
- `project_id`, `region`, `data_center`
- `nomad_addr` - Nomad API address
- `consul_token` - Consul ACL token
- `loki_bucket_name`, `log_retention_days`

**Outputs:**
- `grafana_admin_password`

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
# Change: export CONSUL_VERSION="1.19.2+ent"
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

### Available Task Commands

```bash
task --list
```

| Command | Description |
|---------|-------------|
| `task all` | Build images and deploy |
| `task packer` | Build all Packer images |
| `task apply` | Apply Terraform |
| `task destroy` | Destroy infrastructure |
| `task plan` | Show Terraform plan |
| `task output` | Show outputs |
| `task clean` | Delete GCP images |
| `task redeploy` | Destroy, clean, and redeploy |
| `task list-scenarios` | Show available scenarios |
| `task status` | Show current state |

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
