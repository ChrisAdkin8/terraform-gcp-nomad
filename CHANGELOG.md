# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [untagged]
### Added
- *Your new features or improvements will be documented here.*

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
