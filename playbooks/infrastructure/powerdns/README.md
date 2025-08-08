# PowerDNS Infrastructure Playbooks

This directory contains Ansible playbooks for deploying and managing PowerDNS as part of the DNS & IPAM infrastructure overhaul (Phase 2).

## Playbook Overview

### Pre-deployment Setup

1. **`powerdns-prepare-volumes.yml`**
   - Creates host volume directories on Nomad clients
   - Sets up `/opt/nomad/volumes/powerdns-mysql` for persistent MySQL data
   - Required before deploying the Nomad job

2. **`powerdns-generate-secrets.yml`**
   - Generates secure random passwords for MySQL and PowerDNS API
   - Outputs secrets to console and saves to `/tmp/powerdns-secrets.txt`
   - Use when you need to generate new secrets

3. **`powerdns-setup-manual.yml`**
   - Generates secrets and provides manual instructions
   - Shows exact Consul KV commands to run
   - Useful for manual setup or troubleshooting

### Automated Setup

4. **`powerdns-setup-consul-kv.yml`**
   - Automatically creates PowerDNS secrets in Consul KV
   - Retrieves Consul management token from Infisical
   - Creates keys: `powerdns/mysql/root_password`, `powerdns/mysql/password`, `powerdns/api/key`
   - Checks for existing secrets to prevent overwriting

5. **`powerdns-setup-secrets.yml`**
   - Alternative secret setup playbook
   - Stores secrets in both Consul KV and Infisical
   - Creates comprehensive secret structure

### Access Control

6. **`powerdns-consul-acl.yml`**
   - Creates Consul ACL policy and token for PowerDNS
   - Grants read access to `powerdns/` KV path
   - Enables service registration permissions

7. **`powerdns-anonymous-acl.yml`**
   - Updates Consul anonymous token policy
   - Adds DNS query permissions for PowerDNS service
   - Required for unauthenticated DNS queries

### Post-deployment Configuration

8. **`powerdns-configure-nomad-volumes.yml`**
   - Configures CSI volumes for PowerDNS in Nomad
   - Sets up persistent storage for MySQL database
   - Run after initial deployment if using CSI

## Deployment Workflow

### Quick Start (Automated)

```bash
# 1. Prepare host volumes on Nomad clients
uv run ansible-playbook playbooks/infrastructure/powerdns/powerdns-prepare-volumes.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# 2. Set up secrets in Consul KV
uv run ansible-playbook playbooks/infrastructure/powerdns/powerdns-setup-consul-kv.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# 3. Configure Consul ACLs for PowerDNS
uv run ansible-playbook playbooks/infrastructure/powerdns/powerdns-consul-acl.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml

# 4. Deploy PowerDNS via Nomad
nomad job run jobs/powerdns.nomad
```

### Manual Setup

```bash
# 1. Generate secrets and get manual instructions
uv run ansible-playbook playbooks/infrastructure/powerdns/powerdns-setup-manual.yml

# 2. Follow the displayed instructions to manually set Consul KV values

# 3. Deploy PowerDNS
nomad job run jobs/powerdns.nomad
```

## Verification

After deployment:

```bash
# Check DNS resolution
dig @<nomad-client-ip> example.lab.local A

# Test PowerDNS API
curl -H "X-API-Key: <your-api-key>" http://<nomad-client-ip>:8081/api/v1/servers

# Check Consul service registration
consul catalog services | grep powerdns
```

## Secret Management

Secrets are stored in Consul KV under the `powerdns/` prefix:
- `powerdns/mysql/root_password` - MySQL root password
- `powerdns/mysql/password` - PowerDNS MySQL user password
- `powerdns/api/key` - PowerDNS API key

The Nomad job uses Consul Template to retrieve these secrets at runtime.

## Troubleshooting

1. **Volume Permission Issues**
   - Ensure MySQL directories are owned by UID/GID 999
   - Check `/opt/nomad/volumes/powerdns-mysql` permissions

2. **Secret Access Issues**
   - Verify Consul ACL token has read access to `powerdns/` KV path
   - Check Nomad job has proper Consul token configured

3. **DNS Resolution Failures**
   - Ensure port 53 is open on Nomad clients
   - Check PowerDNS logs via Nomad: `nomad logs <alloc-id>`

## Related Documentation

- PowerDNS Nomad job: `/jobs/powerdns.nomad`
- Phase 2 implementation: `/docs/implementation/dns-ipam/implementation-plan.md`
- Main infrastructure playbooks: `/playbooks/infrastructure/README.md`
