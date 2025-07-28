#!/usr/bin/env bash
# Quick setup script for new users

set -euo pipefail

echo "NetBox Ansible Project Setup"
echo "============================"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible not found. Please install Ansible first."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Please install Python 3.9+."
    exit 1
fi

echo "✅ Prerequisites satisfied"
echo ""

# Install collections
echo "Installing Ansible collections..."
ansible-galaxy collection install -r requirements.yml

# Check for uv
if ! command -v uv &> /dev/null; then
    echo "❌ uv not found. Please install uv first (see docs/uv-ansible-notes.md)"
    exit 1
fi

# Set up Python environment with uv
echo ""
echo "Setting up Python environment with uv..."
uv sync
echo "✅ Python environment configured"

# Create directories
echo ""
echo "Ensuring directory structure..."
mkdir -p playbooks/infrastructure roles

# Final instructions
echo ""
echo "Setup complete! Next steps:"
echo "1. Set up Infisical machine identity credentials (see docs/infisical-setup-and-migration.md)"
echo "2. Test the setup:"
echo "   uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --list"
echo ""
echo "For detailed documentation, see:"
echo "- README.md - Project overview"
echo "- docs/infisical-setup-and-migration.md - Infisical setup and configuration"
echo "- docs/troubleshooting.md - Common issues"
