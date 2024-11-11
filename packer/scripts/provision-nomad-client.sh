#!/bin/bash
set -e

# Enable the HashiCorp test repository for exec2 driver
yum-config-manager --enable hashicorp-test
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y \
  containerd.io \
  containernetworking-plugins \
  docker-ce \
  docker-ce-cli \
  docker-compose-plugin \
  java-11-openjdk \
  java-11-openjdk-devel
#  nomad-driver-exec2

# Create a symbolic link for the CNI plugins
mkdir /opt/cni
ln -s /usr/libexec/cni /opt/cni/bin

# Create a directory for a host volume
mkdir -p /opt/nomad/hv001

systemctl enable docker

# Setup JAVA_HOME
echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk" >> /etc/profile.d/java.sh
