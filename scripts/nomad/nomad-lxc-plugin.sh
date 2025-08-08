#!/usr/bin/env bash
set -euo pipefail

# --- Variables ---
LXC_DRIVER_VERSION="0.1.0"
PLUGIN_DIR="/opt/nomad/plugins"
ZIP_NAME="nomad-driver-lxc_${LXC_DRIVER_VERSION}_linux_amd64.zip"
BIN_NAME="nomad-driver-lxc"

# --- Install LXC dependencies ---
sudo apt update
sudo apt install -y lxc lxc-templates

# --- Download and install Nomad LXC driver ---
cd /tmp/
sudo rm -f ${BIN_NAME}* || true

curl -O "https://releases.hashicorp.com/nomad-driver-lxc/${LXC_DRIVER_VERSION}/${ZIP_NAME}"
unzip -o "${ZIP_NAME}"

sudo mkdir -p "${PLUGIN_DIR}"
sudo mv "${BIN_NAME}" "${PLUGIN_DIR}/lxc"
sudo chmod +x "${PLUGIN_DIR}/lxc"

rm -f "${ZIP_NAME}"

# --- Restart Nomad and check node status ---
sudo systemctl restart nomad
nomad node status -self
