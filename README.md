# Terraform GCP Nomad

Deploy a [HashiCorp Nomad](https://www.nomadproject.io/) and [Consul](https://www.consul.io/) cluster on Google Cloud Platform (GCP) using Packer and Terraform.

## Disclaimer

This repo is designed for demostration purposes only, as such it has not been created for production purposes in terms of:

- security hardening
- performance
- scalability
- high availability

## Architecture

The deployment creates:

- **2 x 3 client node Nomad clusters**

  Provides cluster management and job scheduling
 
- **2 Consul clusters**

  Provides service discovery and health checking

- **Traefik**

  Ingress controller for routing traffic to services
   
- **Grafana based observability stack**

  Consisting of Loki backed by a GCS bucket, an Alloy Gateway, an alloy agent on each Nomad node and Grafana

![Reference Diagram](./docs/reference-diagram.png)

## Prerequisites

Before you begin, ensure you have the following installed:

| Tool | Installation Guide |
|------|-------------------|
| Google Cloud CLI (gcloud) | [Install Guide](https://cloud.google.com/sdk/docs/install) |
| HashiCorp Packer | [Install Guide](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli) |
| HashiCorp Terraform | [Install Guide](https://developer.hashicorp.com/terraform/install) |
| Task | [Install Guide](https://taskfile.dev/installation/) |

You will also need:

- A GCP project with billing enabled
- Nomad Enterprise license file (`nomad.hclic`)
- Consul Enterprise license file (`consul.hclic`)

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

# Get current project
gcloud config get-value project

# Set project
gcloud config set project YOUR_PROJECT_ID
```

**If Nomad and Consul have been deployed before using this repo, check that tf/terraform.vars does not contain an
  old GCP project id.**

### 3. Add License Files

Copy your Nomad and Consul license files to the repository root:

```bash
cp ~/Downloads/nomad.hclic .
cp ~/Downloads/consul.hclic .
```

### 4. Build Images with Packer

To short cut deploying the Nomad/Consul setup in individual steps, the following command can be run:

```bash
task all
```

Otherwise, follow the rest of the steps in this README.

Build the VM images using Task:

```bash
task packer
```

Or build manually:

```bash
# Initialize Packer
packer init packer/gcp-almalinux-nomad-server.pkr.hcl
packer init packer/gcp-almalinux-nomad-client.pkr.hcl
packer init packer/gcp-almalinux-consul-server.pkr.hcl

# Build images
packer build -var-file=variables.pkrvars.hcl packer/gcp-almalinux-nomad-server.pkr.hcl
packer build -var-file=variables.pkrvars.hcl packer/gcp-almalinux-nomad-client.pkr.hcl
packer build -var-file=variables.pkrvars.hcl packer/gcp-almalinux-consul-server.pkr.hcl
```

### 5. Deploy with Terraform

Deploy the infrastructure:

```bash
task apply
```

Or manually:

```bash
cd tf
terraform init
terraform apply
```

## Accessing the Cluster

After deployment, you can access:

| Service | Port | URL |
|---------|------|-----|
| Nomad UI | 4646 | `http://<nomad-server-ip>:4646` |
| Consul UI | 8500 | `http://<consul-server-ip>:8500` |

The firewall rules automatically open TCP ports 4646 and 8500 for external access.

## Customizing Versions

To update Nomad or Consul versions, modify the following scripts:

- **Nomad**: `packer/scripts/provision-nomad.sh` — Update `NOMAD_VERSION`
- **Consul**: `packer/scripts/provision-consul.sh` — Update `CONSUL_VERSION`

Then rebuild the images with Packer.

## Project Structure

```
terraform-gcp-nomad/
│
├── 📄 README.md                                # Project documentation
├── 📄 Taskfile.yml                             # Task runner configuration
├── 📄 project.sh                               # GCP authentication & setup script
├── 📄 build-packer.sh                          # Parallel Packer build script
├── 📄 variables.pkrvars.hcl                    # Shared Packer variables
│
├── 📄 nomad.hclic                              # Nomad Enterprise license (user-provided)
├── 📄 consul.hclic                             # Consul Enterprise license (user-provided)
│
├── 📁 packer/                                  # Packer image definitions
│   │
│   ├── 📄 variables.pkr.hcl                    # Packer variable definitions
│   │
│   ├── 📄 gcp-almalinux-nomad-server.pkr.hcl   # Nomad server image template
│   ├── 📄 gcp-almalinux-nomad-client.pkr.hcl   # Nomad client image template
│   ├── 📄 gcp-almalinux-consul-server.pkr.hcl  # Consul server image template
│   │
│   ├── 📁 configs/                             # Provisioning scripts for Packer
│   │   ├── 📄 provision-nomad.sh               # Installs Nomad (set NOMAD_VERSION here)
│   │   └── 📄 provision-consul.sh              # Installs Consul (set CONSUL_VERSION here)
│   │
│   └── 📁 scripts/                             # Provisioning scripts for Packer
│       ├── 📄 provision-nomad.sh               # Installs Nomad (set NOMAD_VERSION here)
│       └── 📄 provision-consul.sh              # Installs Consul (set CONSUL_VERSION here)
│
└── 📁 tf/                                      # Terraform configurations
    │
    ├── 📄 consul.tf                        
    ├── 📄 data.tf                        
    ├── 📄 firewall.tf                        
    ├── 📄 gcs.tf                        
    ├── 📄 firewall.tf                        
    ├── 📄 main.tf                              # Root module - orchestrates infrastructure
    ├── 📄 network.tf
    ├── 📄 nomad.tf
    ├── 📄 output.tf
    ├── 📄 providers.tf
    ├── 📄 variables.tf                         # Input variable definitions
    ├── 📄 versions.tf                   
    ├── 📄 outputs.tf                           # Output value definitions
    ├── 📄 terraform.tfvars                     # Variable values (auto-generated)
    │
    └── 📁 modules/                             # Reusable inline Terraform modules
        │
        ├── 📁 nomad/                           # Nomad server cluster module
        │   ├── 📄 data.tf
        │   ├── 📄 dns.tf
        │   ├── 📄 iam.tf
        │   ├── 📄 lb.tf
        │   ├── 📄 main.tf
        │   ├── 📄 mig.tf
        │   ├── 📄 main.tf
        │   ├── 📄 variables.tf
        │   └── 📄 outputs.tf
        │
        ├── 📁 consul/                          # Consul server cluster module
        │   ├── 📄 data.tf
        │   ├── 📄 dns.tf
        │   ├── 📄 iam.tf
        │   ├── 📄 main.tf
        │   ├── 📄 main.tf
        │   ├── 📄 variables.tf
        │   └── 📄 outputs.tf
        │
        ├── 📁 network/                         # VPC, subnets, firewall rules
        │   ├── 📄 firewall.tf
        │   ├── 📄 variables.tf
        │   └── 📄 outputs.tf
        │
        └── 📁 observability/             # Monitoring stack (Loki, Grafana, Alloy)
            ├── 📁 function-code/ 
            ├── 📄 alloy.nomad.tpl
            ├── 📄 grafana.nomad.tpl
            ├── 📄 loki_gateway.nomad.tpl
            ├── 📄 bigquery.tf
            ├── 📄 gcs.tf
            ├── 📄 iam.tf
            ├── 📄 jobs.tf
            ├── 📄 locals.tf
            └── 📄 variables.tf
```

## Component Overview

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
│  │  │                      Nomad Clients                            │  │    │
│  │  ├───────────────────────────────────────────────────────────────┤  │    │
│  │  │                                                               │  │    │
│  │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │  │    │
│  │  │  │   Traefik   │  │    Loki     │  │   Grafana           │    │  │    │
│  │  │  │   :80/:443  │  │   :3100     │  │   :3000             │    │  │    │
│  │  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │  │    │
│  │  │                                                               │  │    │
│  │  │  ┌─────────────┐  ┌─────────────────────────────────────┐     │  │    │
│  │  │  │ Alloy GW    │  │         User Workloads              │     │  │    │
│  │  │  │  :12346     │  │                                     │     │  │    │
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

## Data Flow
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
                            │     GCS Bucket      │     Log Push from
                            │  ┌───────┬───────┐  │     External Agents
                            │  │Chunks │ Index │  │
                            │  └───────┴───────┘  │
                            └─────────────────────┘
```

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
| Loki HTTP | 3100 | TCP | Log push/query API |
| Loki gRPC | 9096 | TCP | gRPC API |
| Grafana | 3000 | TCP | Dashboard UI |
| Alloy Gateway | 12346 | TCP | Log ingestion endpoint |    

## Cleanup

To destroy all resources:

```bash
task destroy
task clean
```

## License

This project is provided as-is for educational and demonstration purposes.

## References

- [Nomad Production Reference Architecture](https://developer.hashicorp.com/nomad/tutorials/enterprise/production-reference-architecture-vm-with-consul)
- [Nomad Documentation](https://developer.hashicorp.com/nomad/docs)
- [Consul Documentation](https://developer.hashicorp.com/consul/docs)
- [Packer Documentation](https://developer.hashicorp.com/packer/docs)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
