# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NetBox-focused Ansible automation project that integrates NetBox as a source of truth for network
infrastructure management. The project uses containerized Ansible execution environments, dynamic inventory management,
and secure credential management through 1Password.

**Current Focus**: Implementing a comprehensive DNS & IPAM overhaul to transition from ad-hoc DNS management to a
service-aware infrastructure using Consul, PowerDNS, and NetBox. See `docs/dns-ipam-implementation-plan.md` for the
detailed implementation roadmap.

## Commands

### Running Playbooks with 1Password Integration

```bash
# Using the wrapper script (recommended - handles credential retrieval)
./bin/ansible-connect playbook playbooks/site.yml

# Direct ansible-navigator usage
ansible-navigator run <playbook.yml> \
  --execution-environment-image ghcr.io/ansible-community/community-ee-minimal:latest --mode stdout
```

### Working with Dynamic Inventory

```bash
# Test Proxmox inventory with 1Password integration
./bin/ansible-connect inventory -i inventory/og-homelab/proxmox.yml --list
./bin/ansible-connect inventory -i inventory/doggos-homelab/proxmox.yml --list

# Graph inventory structure
./bin/ansible-connect inventory -i inventory/og-homelab/proxmox.yml --graph
./bin/ansible-connect inventory -i inventory/doggos-homelab/proxmox.yml --graph
```

### Running Assessment Playbooks

```bash
# Infrastructure assessment playbooks (Phase 0)
./bin/ansible-connect playbook playbooks/assessment/consul-health-check.yml
./bin/ansible-connect playbook playbooks/assessment/dns-ipam-audit.yml
./bin/ansible-connect playbook playbooks/assessment/infrastructure-readiness.yml
```

## Architecture

### Inventory Management

- **Directory**: `inventory/` contains all dynamic inventory configurations
- **Current Implementation**:
  - Proxmox dynamic inventory using `community.general.proxmox` plugin
  - Two clusters configured: `og-homelab` and `doggos-homelab`
- **In Progress**: DNS & IPAM infrastructure deployment (see `docs/dns-ipam-implementation-plan.md`)
- **Planned**: NetBox dynamic inventory integration (see `docs/netbox.md` for patterns)
- **Authentication**: Uses API tokens stored in 1Password, accessed via environment variables

### Execution Environment

- Based on `community-ee-minimal` container image
- Includes `ansible-core`, `ansible-runner`, and `community.general` collection
- Configured in `execution-environment.yml`

### Documentation Structure

- `docs/dns-ipam-implementation-plan.md`: Master plan for DNS & IPAM overhaul:
  - 5-phase implementation approach
  - Detailed task checklists
  - Risk assessments and mitigation strategies
  - Success criteria for each phase

- `docs/netbox.md`: Comprehensive NetBox integration patterns including:
  - Dynamic inventory configuration
  - State management with NetBox modules
  - Runtime data queries with `netbox.netbox.nb_lookup`
  - Event-driven automation patterns

- `docs/1password-integration.md`: 1Password Connect integration for secrets management:
  - Vault item lookups using `community.general.onepassword`
  - Secret injection patterns
  - Error handling strategies
  - Environment setup instructions

### Key Integration Patterns

1. **NetBox as Source of Truth**
   - All network device information should be queried from NetBox
   - Device configurations should be generated based on NetBox data
   - State changes should be reflected back in NetBox

2. **Dynamic Inventory Grouping**
   - Devices grouped by NetBox attributes (site, role, platform, tags)
   - Custom grouping via `keyed_groups` and `compose` directives
   - Ansible variables composed from NetBox custom fields

3. **Secret Management**
   - Never hardcode credentials
   - Use 1Password Connect for secret retrieval
   - Environment variables for API tokens

## Current Infrastructure State

### Clusters

- **og-homelab**: Original Proxmox cluster (details pending assessment)
- **doggos-homelab**: 3-node Proxmox cluster (lloyd, holly, mable) running Nomad
  - 3 Nomad servers (one per node)
  - 3 Nomad clients (one per node)
  - Tagged with: nomad, staging, terraform, server/client roles

### Services

- **Consul**: Deployed (configuration state pending assessment)
- **Nomad**: Operational on doggos-homelab
- **DNS**: Currently Pi-hole + Unbound (to be migrated)
- **IPAM**: Ad-hoc management (to be replaced with NetBox)

## Important Considerations

- The project is actively implementing DNS & IPAM infrastructure changes
- Follow the implementation plan in `docs/dns-ipam-implementation-plan.md`
- Always source environment variables before running commands: `source ./scripts/set-1password-env.sh`
- Use the execution environment for consistency across different systems
- Always test inventory plugins with `ansible-inventory` before running playbooks
- NetBox integration should follow the patterns in `docs/netbox.md`

## Recommended Tools

- For enhanced searching via bash commands use eza, fd, and rg
