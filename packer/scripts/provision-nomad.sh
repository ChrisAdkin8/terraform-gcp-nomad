#!/bin/bash

export CONSUL_VERSION="1.22.2+ent"

# Update system packages
sudo dnf update -y

# Install required packages
sudo dnf install -y unzip curl wget yum-utils

# Add HashiCorp's official RPM repository
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

# Install Consul & Nomad
sudo dnf install -y consul nomad

# Upgrade Nomad to ent
wget -q "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip"
unzip "nomad_${NOMAD_VERSION}_linux_amd64.zip" nomad
chmod +x nomad
sudo chown root:root nomad
sudo mv nomad /usr/bin/nomad
nomad --version

# Upgrade Consul to ent
wget -q "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip"
unzip consul_${CONSUL_VERSION}_linux_amd64.zip consul
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

# Enable Services to start at boot
#sudo systemctl enable nomad
#sudo systemctl enable consul

# Install Google Cloud Ops Agent
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
