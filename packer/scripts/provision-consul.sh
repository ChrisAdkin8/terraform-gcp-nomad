#!/bin/bash

export CONSUL_VERSION="1.19.2+ent"

# Update system packages
sudo dnf update -y

# Install required packages
sudo dnf install -y unzip curl wget

# Add HashiCorp's official RPM repository
curl -fsSL https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo

# Install Consul
sudo dnf install -y consul

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
sudo chcon -t bin_t /usr/bin/consul

# Copy config files
sudo cp /tmp/consul.hcl /etc/consul.d/consul.hcl

# Copy license files
sudo cp /tmp/consul.hclic /etc/consul.d/license.hclic

# Enable Services to start at boot
#sudo systemctl enable consul

# Install Google Cloud Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
