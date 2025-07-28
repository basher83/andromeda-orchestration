# Infrastructure Playbooks

This directory contains playbooks for managing infrastructure components.

## Directory Structure

### user-management/
Playbooks for managing users and SSH access:
- `setup-ansible-user.yml` - Comprehensive ansible user setup with SSH keys and sudo access
- `deploy-ssh-keys.yml` - Legacy SSH key deployment playbook (use setup-ansible-user.yml instead)

### consul-nomad/
Playbooks for Consul and Nomad integration:
- `consul-nomad-integration.yml` - Full Consul-Nomad integration setup
- `enable-consul-nomad-simple.yml` - Simple enablement of Consul-Nomad features

## Usage Examples

### Setting up Ansible User
```bash
# Setup ansible user on all hosts in an inventory
uv run ansible-playbook playbooks/infrastructure/user-management/setup-ansible-user.yml \
  -i inventory/og-homelab/infisical.proxmox.yml \
  -e ansible_user_setup=true

# For initial setup on hosts without ansible user, it will use root
# After setup, it will use the ansible user
```

### Consul-Nomad Integration
```bash
# Enable Consul-Nomad integration
uv run ansible-playbook playbooks/infrastructure/consul-nomad/consul-nomad-integration.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```