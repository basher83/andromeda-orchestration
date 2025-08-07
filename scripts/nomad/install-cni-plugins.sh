#!/bin/bash
# Script to install CNI plugins for Nomad Service Mesh

set -e

# Variables
CNI_VERSION="1.6.2"
CONSUL_CNI_VERSION="1.6.3"
CNI_ARCH=$([ $(uname -m) = aarch64 ] && echo arm64 || echo amd64)

echo "Installing CNI plugins version $CNI_VERSION and Consul CNI plugin version $CONSUL_CNI_VERSION for $CNI_ARCH..."

# Create required directories
sudo mkdir -p /opt/cni/bin
sudo mkdir -p /etc/cni/net.d

# Download and install CNI plugins
echo "Downloading CNI plugins..."
curl -L -o /tmp/cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-${CNI_ARCH}-v${CNI_VERSION}.tgz"
sudo tar -C /opt/cni/bin -xzf /tmp/cni-plugins.tgz

# Download and install Consul CNI plugin
echo "Downloading Consul CNI plugin..."
curl -L -o /tmp/consul-cni.zip "https://releases.hashicorp.com/consul-cni/v${CONSUL_CNI_VERSION}/consul-cni_${CONSUL_CNI_VERSION}_linux_${CNI_ARCH}.zip"
sudo unzip -o /tmp/consul-cni.zip -d /opt/cni/bin

# Configure network settings for bridge mode
echo "Configuring network settings for bridge mode..."
echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-arptables
echo 1 | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

# Persist these settings across reboots
echo "net.bridge.bridge-nf-call-arptables = 1" | sudo tee -a /etc/sysctl.d/bridge.conf
echo "net.bridge.bridge-nf-call-iptables = 1" | sudo tee -a /etc/sysctl.d/bridge.conf
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.d/bridge.conf

# Apply sysctl settings
sudo sysctl -p /etc/sysctl.d/bridge.conf

# Verify installation
echo "Verifying installation..."
ls -la /opt/cni/bin/

echo "Installation complete!"