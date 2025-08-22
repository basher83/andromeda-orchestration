# Archived Playbooks

This directory contains playbooks that are no longer current but are kept for reference.

## Files

### `fix-docker-consul-dns-iptables.yml`

- **Status**: Archived (2025-08-22)
- **Reason**: Uses outdated iptables approach for Docker DNS redirection
- **Replacement**: `../infrastructure/consul-nomad/configure-docker-consul-dns.yml`
- **Migration**: DNS redirection rules now handled by nftables template in `roles/system_base/templates/nftables.conf.j2`

## Why Archived?

These playbooks used iptables for firewall management, but the system has migrated to nftables-only for consistency and to avoid conflicts. The archived playbooks may contain useful logic but should not be run on current systems.

## Using Archived Playbooks

❌ **Do not run these playbooks directly** - they may conflict with current nftables configuration.

✅ **Reference them for understanding** - they contain useful patterns and logic that may help with troubleshooting or creating new playbooks.

If you need functionality from an archived playbook, check if there's a modern replacement or create a new nftables-compatible version.
