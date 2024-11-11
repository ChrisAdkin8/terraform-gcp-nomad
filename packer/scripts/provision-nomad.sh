#!/bin/bash

export NOMAD_VERSION="1.8.3+ent"
export CONSUL_VERSION="1.19.2+ent"

# Update system packages
sudo dnf update -y

# Install required packages
sudo dnf install -y unzip curl wget

# Add HashiCorp's official RPM repository
curl -fsSL https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo

# Install Nomad
sudo dnf install -y nomad

# Install Consul
sudo dnf install -y consul

# Upgrade Nomad to ent
wget -q "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip"
unzip "nomad_${NOMAD_VERSION}_linux_amd64.zip"
chmod +x nomad
sudo chown root:root nomad
sudo mv nomad /usr/bin/nomad
nomad --version

# Upgrade Consul to ent
wget -q "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip"
unzip consul_${CONSUL_VERSION}_linux_amd64.zip
chmod +x consul
sudo chown root:root consul
sudo mv consul /usr/bin/consul
consul --version

# Setup Consul Permisions
sudo touch /var/log/consul.log
sudo chown consul:consul /var/log/consul.log

# Set SELinux Context
sudo chcon -t bin_t /usr/bin/nomad
sudo chcon -t bin_t /usr/bin/consul

# Copy config files
sudo cp /tmp/nomad.hcl /etc/nomad.d/nomad.hcl
sudo cp /tmp/consul.hcl /etc/consul.d/consul.hcl

# Copy license files
sudo cp /tmp/nomad.hclic /etc/nomad.d/license.hclic
sudo cp /tmp/consul.hclic /etc/consul.d/license.hclic

# Create host volume directory
sudo mkdir -p /opt/nomad/hv001

# Enable Services to start at boot
sudo systemctl enable nomad
sudo systemctl enable consul
