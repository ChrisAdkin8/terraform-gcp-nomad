# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **GKE Consul Dataplane Scenario** - New `gke-consul-dataplane` scenario for deploying GKE with Consul service mesh
  - Complete scenario in `tf/scenarios/gke-consul-dataplane/` directory
  - Deploys Consul control plane (1-3 servers) with ACL enabled
  - Deploys GKE cluster (3 nodes default) with Consul dataplane integration
  - Shared VPC networking between Consul servers and GKE
  - GCS bucket for configuration and license files
  - Comprehensive scenario README with quick start guide
  - Example terraform.tfvars file for easy configuration
  - Task command shortcut: `task gke-dataplane`
  - Feature flags for flexible deployment (create_consul_cluster, create_gke_cluster)
  - Cost estimate: ~$300/month for default configuration
- **GKE Consul Dataplane Module** - New `gke-consule-dataplane` module for deploying GKE clusters with Consul service mesh integration
  - GKE cluster deployment with workload identity enabled
  - Consul dataplane deployment via official HashiCorp Helm chart (version 1.3.0 default)
  - Automatic sidecar injection for service mesh with mTLS between services
  - GKE services registered in Consul catalog with `k8s-` prefix
  - Consul DNS integration for `.consul` domain resolution from Kubernetes pods
  - Consul ingress gateway with external LoadBalancer (ports 80, 443, 8080, 8443)
  - Firewall rules for GKE-to-Consul server connectivity (ports 8500, 8502, 8301, 8600)
  - Integration with existing VPC infrastructure via `subnet_self_link` variable
  - Kubernetes provider (~> 2.25) and Helm provider (~> 2.12) support
  - Module README with comprehensive usage examples and troubleshooting guide
- Resource labels support across all modules (`labels`, `environment` variables)
- `versions.tf` to observability module with proper provider constraints
- `proxy_subnet_cidr` and `secondary_proxy_subnet_cidr` variables to network module
- `additional_allowed_cidrs` variable for flexible firewall configuration
- Comprehensive Grafana-based observability stack (Loki, Alloy, Grafana)
- Multi-datacenter support with primary and secondary cluster deployments

### Changed
- **GKE Module Architecture** - Transitioned `gke-consule-dataplane` module from self-contained VPC to external networking
  - Removed `vpc.tf` file (VPC and subnet now provided externally via `subnet_self_link` variable)
  - Added data sources to extract network information from provided subnet
  - Updated GKE cluster to use provided network and subnet instead of creating its own
  - Added workload identity configuration for enhanced security
- Renamed `data_center` variable to `datacenter` for consistency across all modules
- Standardized Terraform version constraint to `>= 1.5.0` across all modules
- Standardized Google provider version to `~> 6.0` across all modules
- Updated proxy-only subnet CIDR allocation to use variables instead of hardcoded regions
- Improved IAM scopes for Consul and Nomad instances (least-privilege)
- Updated README.md with complete variable documentation
- Updated README.md to reflect `gke-consul-dataplane` scenario implementation status

### Documentation
- Added comprehensive "Task Commands and Scenarios" section to README.md explaining:
  - How the Taskfile scenario-based deployment system works
  - Detailed reference for all task commands organized by category
  - Token management workflow and lifecycle
  - Scenario shortcuts and Terraform operation details
  - Packer image building process and parallel execution
  - Common workflows and usage patterns
- Added detailed "Nomad-Consul Scenario" section documenting:
  - Complete infrastructure deployed in primary and secondary datacenters
  - Consul cluster configuration (servers, ACLs, service discovery)
  - Nomad cluster architecture (servers, MIG clients, preemptible instances)
  - Observability stack components (Traefik, Loki, Grafana, Alloy)
  - Networking infrastructure (VPC, subnets, NAT, load balancers)
  - Security configuration (firewall rules, IAM, service accounts)
  - Storage layout (GCS bucket usage and lifecycle)
  - Resource labeling strategy for cost tracking
  - Deployment sequence and data flow diagrams
  - Feature flags for fine-grained control
  - Access methods and CLI configuration examples
  - Cost breakdown and optimization strategies
- Added `gke-consule-dataplane` module documentation:
  - Comprehensive README.md in module directory with architecture diagram
  - Usage examples (basic, minimal, service discovery only, custom Helm version)
  - Complete inputs/outputs reference table
  - Feature documentation (service mesh, service discovery, DNS, ingress gateway)
  - Networking and firewall rules documentation
  - Security considerations and production recommendations
  - Troubleshooting guide with kubectl/helm commands
  - Integration examples with Consul module
  - Resources created reference
- Updated main README.md Module Reference section with `gke-consule-dataplane` module
- Added "GKE Consul Dataplane Scenario" section to main README with:
  - Complete architecture overview (Consul control plane + GKE dataplane)
  - Quick deployment instructions
  - Testing service mesh guide with example application
  - Configuration options reference table
  - Use cases and cost breakdown
  - Reference to detailed scenario README
- Updated project structure tree to include both GKE module files and scenario directory
- Updated scenario descriptions and shortcuts in Task Commands section
- Updated Table of Contents to include new documentation sections
- Reorganized Customization section to reference comprehensive task commands documentation

### Fixed
- Consul module outputs now correctly return external and internal IPs
- Removed provider definition from GKE child module (was breaking provider inheritance)
- Fixed stray character in README.md title

### Security
- Added `sensitive = true` to password and token variables
- Implemented least-privilege IAM scopes for compute instances

## [1.0.0] - 2024-09-09
### Added
- Initial deployment of Nomad in a cluster with 3 servers and 1 client by default.
- Deployment of a Consul cluster with 3 nodes for service discovery.
- Consul clients are automatically configured on other nodes using `provider=gce` and `tag_value=consul-server` for discovery.
- Nomad peers are automatically discovered and joined using Consul with `auto_advertise`, `server_auto_join`, and `client_auto_join`.
- Packer used to create the following images:
  - `almalinux-nomad-server`
  - `almalinux-nomad-client`
  - `almalinux-consul-server`
- Terraform used to manage the infrastructure deployment.

### Notes
- The cluster is designed to automatically discover peers and form a complete network using Consul's service discovery mechanism.
