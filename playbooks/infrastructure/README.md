# Infrastructure Playbooks

This directory contains organized Ansible playbooks for infrastructure management and deployment.

## Directory Structure

### Production Playbooks

- **`consul/`** - Consul service mesh and DNS configuration
  - `phase1-consul-dns.yml` - Enable Consul DNS on clusters
  - `phase1-consul-foundation.yml` - Base Consul setup
  - `consul-telemetry-setup.yml` - Configure Consul telemetry
  - `enable-consul-telemetry.yml` - Enable telemetry collection
  - `simple-telemetry-enable.yml` - Quick telemetry enablement
  - `create-prometheus-acl.yml` - ACL for Prometheus integration

- **`consul-nomad/`** - Consul and Nomad integration
  - `consul-nomad-integration.yml` - Full Consul-Nomad integration setup
  - `enable-consul-nomad-simple.yml` - Simple enablement of Consul-Nomad features
  - Various ACL and token management playbooks

- **`monitoring/`** - Netdata monitoring deployment
  - `deploy-netdata-all.yml` - Deploy to all clusters
  - `deploy-netdata-doggos.yml` - Deploy to doggos-homelab
  - `deploy-netdata-og.yml` - Deploy to og-homelab
  - `netdata-configure-mesh.yml` - Configure parent mesh topology

- **`network/`** - Network configuration
  - `update-nftables-netdata.yml` - Firewall rules for Netdata
  - `update-nftables-nomad.yml` - Firewall rules for Nomad dynamic ports

- **`nomad/`** - Nomad cluster management
  - `cluster-manage.yml` - Manage Nomad cluster operations
  - `cluster-status.yml` - Check Nomad cluster status
  - `deploy-job.yml` - Deploy Nomad jobs using Galaxy modules
  - `deploy-traefik.yml` - Deploy Traefik with validation checks
  - `register-service.yml` - Register services with Nomad

- **`powerdns/`** - PowerDNS deployment and configuration (Phase 2)
  - `powerdns-prepare-volumes.yml` - Prepare host volumes on Nomad clients
  - `powerdns-setup-consul-kv.yml` - Automated secret setup in Consul KV
  - `powerdns-consul-acl.yml` - Configure Consul ACLs for PowerDNS
  - `powerdns-setup-manual.yml` - Manual setup instructions
  - See `powerdns/README.md` for detailed deployment workflow

- **`user-management/`** - User and access management
  - `setup-ansible-user.yml` - Comprehensive ansible user setup with SSH keys and sudo access
  - `deploy-ssh-keys.yml` - Legacy SSH key deployment playbook (use setup-ansible-user.yml instead)

- **`maintenance/`** - Update and maintenance tasks
  - `backup-netdata-config.yml` - Backup Netdata configurations
  - `deploy-netdata-update.yml` - Update Netdata deployments
  - `netdata-update-streaming.yml` - Update streaming configuration

### Hidden Directories

- **`.debug/`** - Troubleshooting and debugging playbooks (10+ files)
  - Various check-* and debug-* playbooks for Netdata troubleshooting
  - Kept hidden to reduce clutter but available when needed

- **`.archive/`** - Old/replaced playbooks kept for reference (8+ files)
  - One-time fixes and initial deployment playbooks
  - Superseded by role-based deployments

### Other Files

- **`templates/`** - Jinja2 templates used by playbooks
- **`CLEANUP_PLAN.md`** - Documentation of the cleanup process

## Usage Examples

### Deploy Netdata Monitoring

```bash
# Deploy to all clusters
uv run ansible-playbook playbooks/infrastructure/monitoring/deploy-netdata-all.yml \
  -i inventory/*/infisical.proxmox.yml

# Deploy to specific cluster
uv run ansible-playbook playbooks/infrastructure/monitoring/deploy-netdata-doggos.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# Configure mesh topology
uv run ansible-playbook playbooks/infrastructure/monitoring/netdata-configure-mesh.yml \
  -i inventory/*/infisical.proxmox.yml
```

### Setting up Ansible User

```bash
# Setup ansible user on all hosts in an inventory
uv run ansible-playbook playbooks/infrastructure/user-management/setup-ansible-user.yml \
  -i inventory/og-homelab/infisical.proxmox.yml \
  -e ansible_user_setup=true
```

### Consul Configuration

```bash
# Enable Consul DNS (Phase 1)
uv run ansible-playbook playbooks/infrastructure/consul/phase1-consul-dns.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# Setup Consul telemetry
uv run ansible-playbook playbooks/infrastructure/consul/consul-telemetry-setup.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Nomad Management

```bash
# Check Nomad cluster status
uv run ansible-playbook playbooks/infrastructure/nomad/cluster-status.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# Deploy a job to Nomad (NEW method with Galaxy modules)
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/platform-services/powerdns.nomad.hcl

# Deploy Traefik with validation
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-traefik.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Consul-Nomad Integration

```bash
# Enable Consul-Nomad integration
uv run ansible-playbook playbooks/infrastructure/consul-nomad/consul-nomad-integration.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Network Configuration

```bash
# Update nftables for Netdata
uv run ansible-playbook playbooks/infrastructure/network/update-nftables-netdata.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Maintenance Tasks

```bash
# Backup Netdata configurations
uv run ansible-playbook playbooks/infrastructure/maintenance/backup-netdata-config.yml \
  -i inventory/*/infisical.proxmox.yml

# Update Netdata streaming configuration
uv run ansible-playbook playbooks/infrastructure/maintenance/netdata-update-streaming.yml \
  -i inventory/*/infisical.proxmox.yml
```

## Debugging

If you need to troubleshoot issues, check the `.debug/` directory for various debugging playbooks:

```bash
# List debug playbooks
ls -la playbooks/infrastructure/.debug/

# Example: Check Netdata streaming status
uv run ansible-playbook playbooks/infrastructure/.debug/check-streaming-status.yml \
  -i inventory/og-homelab/infisical.proxmox.yml
```
