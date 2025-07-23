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

# Set up environment file
if [ ! -f scripts/set-1password-env.sh ]; then
    echo ""
    echo "Creating 1Password environment configuration..."
    cp scripts/set-1password-env.sh.example scripts/set-1password-env.sh
    echo "✅ Created scripts/set-1password-env.sh"
    echo ""
    echo "⚠️  Please edit scripts/set-1password-env.sh with your 1Password Connect details"
else
    echo "✅ Environment configuration already exists"
fi

# Create directories
echo ""
echo "Ensuring directory structure..."
mkdir -p playbooks/infrastructure roles

# Final instructions
echo ""
echo "Setup complete! Next steps:"
echo "1. Edit scripts/set-1password-env.sh with your 1Password Connect details"
echo "2. Store your credentials in 1Password (see docs/1password-integration.md)"
echo "3. Test the setup:"
echo "   ./bin/ansible-connect inventory -i inventory/og-homelab/proxmox.yml --list"
echo ""
echo "For detailed documentation, see:"
echo "- README.md - Project overview"
echo "- docs/1password-integration.md - 1Password setup"
echo "- docs/troubleshooting.md - Common issues"