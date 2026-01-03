# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Resource labels support across all modules (`labels`, `environment` variables)
- `versions.tf` to observability module with proper provider constraints
- `proxy_subnet_cidr` and `secondary_proxy_subnet_cidr` variables to network module
- `additional_allowed_cidrs` variable for flexible firewall configuration
- Comprehensive Grafana-based observability stack (Loki, Alloy, Grafana)
- Multi-datacenter support with primary and secondary cluster deployments

### Changed
- Renamed `data_center` variable to `datacenter` for consistency across all modules
- Standardized Terraform version constraint to `>= 1.5.0` across all modules
- Standardized Google provider version to `~> 6.0` across all modules
- Updated proxy-only subnet CIDR allocation to use variables instead of hardcoded regions
- Improved IAM scopes for Consul and Nomad instances (least-privilege)
- Updated README.md with complete variable documentation

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
