# Deployment Log

This file tracks all production deployments to the infrastructure.

## Format

Each deployment entry should include:
- Date and time (UTC)
- Component deployed
- Version/commit hash
- Method used (Ansible/Manual/Other)
- Operator
- Notes/Issues

---

## 2025 Deployments

### September 2025

#### 2025-09-05 05:27 UTC - Vault PKI Monitor

- **Component**: vault-pki-monitor (Nomad periodic job)
- **File**: `nomad-jobs/platform-services/vault-pki-monitor.nomad.hcl`
- **Method**: Direct `nomad job run` (should have used Ansible)
- **Operator**: AI IDE Agent
- **Changes Made**:
  - Fixed volume mount path from `/opt/netbox-ansible` to `/opt/andromeda-orchestration`
  - Updated Vault address to use Consul service discovery
  - Removed unnecessary `network_mode = "host"`
  - Fixed deprecated `cron` to `crons` syntax
  - Simplified Infisical auth to use host environment variables
- **Schedule**: Runs every 6 hours starting at 06:00 UTC
- **Related Issue**: GitHub #100 - Automate Certificate Rotation and Distribution
- **Archon Task**: 1c57b421-dfd8-4147-8483-3f5c852c31d3
- **Notes**: Deployment method violated project standards. Should have used:
  ```bash
  uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
    -i inventory/doggos-homelab/infisical.proxmox.yml \
    -e job=nomad-jobs/platform-services/vault-pki-monitor.nomad.hcl
  ```

### August 2025

#### 2025-08-23 - Vault Production Cluster

- **Component**: Vault HA Cluster
- **Version**: 1.20.2
- **Method**: Ansible playbooks
- **Operator**: basher83
- **Notes**:
  - 4-node cluster with Raft storage
  - Auto-unseal via transit engine
  - TLS enabled with self-signed certificates
  - See ADR-2025-08-23-vault-production-deployment.md

#### 2025-08-22 - Traefik Load Balancer

- **Component**: Traefik
- **Method**: Nomad job via Ansible
- **File**: `nomad-jobs/core-infrastructure/traefik.nomad.hcl`
- **Notes**: Dynamic port allocation, service discovery via Consul

#### 2025-08-10 - PostgreSQL Database

- **Component**: PostgreSQL 16
- **Method**: Nomad job
- **File**: `nomad-jobs/platform-services/postgresql.nomad.hcl`
- **Notes**: Deployed for PowerDNS backend support

---

## Deployment Standards

1. **Always use Ansible playbooks** for production deployments
2. **Never use direct CLI commands** (`nomad job run`, `docker run`, etc.)
3. **Document all deployments** in this log
4. **Link to related issues** and tasks
5. **Note any deviations** from standards

## Rollback Procedures

See individual service documentation for rollback procedures:
- Vault: `docs/implementation/vault/production-deployment.md`
- Nomad Jobs: Use `nomad job revert` or redeploy previous version
- Ansible: Rerun playbooks with previous configuration
