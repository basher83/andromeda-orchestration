# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a NetBox-focused Ansible automation project that integrates NetBox as a source of truth for network
infrastructure management. The project uses containerized Ansible execution environments, dynamic inventory management,
and secure credential management through Infisical.

**Current Focus**: Implementing a comprehensive DNS & IPAM overhaul to transition from ad-hoc DNS management to a
service-aware infrastructure using Consul, PowerDNS, and NetBox. See `docs/implementation/dns-ipam/implementation-plan.md` for the
detailed implementation roadmap.

## Commands

### Running Playbooks with Infisical

```bash
# Run playbooks using uv with Infisical secrets
uv run ansible-playbook playbooks/site.yml -i inventory/og-homelab/infisical.proxmox.yml

# Direct ansible-navigator usage (optional)
ansible-navigator run <playbook.yml> \
  --execution-environment-image ghcr.io/ansible-community/community-ee-minimal:latest --mode stdout
```

### Working with Dynamic Inventory

```bash
# Test inventory with Infisical (recommended)
uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --list
uv run ansible-inventory -i inventory/doggos-homelab/infisical.proxmox.yml --list

# Graph inventory structure
uv run ansible-inventory -i inventory/doggos-homelab/infisical.proxmox.yml --graph

# Test inventory with 1Password (deprecated - for migration only)
# Use ansible-connect wrapper only if still migrating from 1Password
# ./bin/ansible-connect inventory -i inventory/og-homelab/1password.proxmox.yml --list
```

### Running Assessment Playbooks

```bash
# Infrastructure assessment playbooks (Phase 0)
uv run ansible-playbook playbooks/assessment/consul-health-check.yml -i inventory/og-homelab/infisical.proxmox.yml
uv run ansible-playbook playbooks/assessment/dns-ipam-audit.yml -i inventory/og-homelab/infisical.proxmox.yml
uv run ansible-playbook playbooks/assessment/infrastructure-readiness.yml -i inventory/og-homelab/infisical.proxmox.yml
```

### Deploying Nomad Jobs

```bash
# Deploy any Nomad job
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job=nomad-jobs/core-infrastructure/traefik.nomad.hcl

# Deploy Traefik with validation
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-traefik.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

## Architecture

### Inventory Management

- **Directory**: `inventory/` contains all dynamic inventory configurations
- **Current Implementation**:
  - Proxmox dynamic inventory using `community.general.proxmox` plugin
  - Two clusters configured: `og-homelab` and `doggos-homelab`
  - Dual inventory files per cluster:
    - `infisical.proxmox.yml` - Uses Infisical for secrets (recommended)
    - `1password.proxmox.yml` - Uses 1Password for secrets (legacy)
- **In Progress**: DNS & IPAM infrastructure deployment (see `docs/implementation/dns-ipam/implementation-plan.md`)
- **Planned**: NetBox dynamic inventory integration (see `docs/implementation/netbox-integration.md` for patterns)
- **Authentication**:
  - Infisical: Machine identity credentials via environment variables
  - 1Password: API tokens via Connect server (legacy)

### Nomad Job Management

- **Directory**: `nomad-jobs/` contains all Nomad job specifications
- **Structure**:
  - `core-infrastructure/` - Essential services (Traefik load balancer)
  - `platform-services/` - Infrastructure services (PowerDNS, future NetBox)
  - `applications/` - User-facing applications
- **Deployment**: Using `community.general.nomad_job` Galaxy module via playbooks
- **Port Strategy**: Dynamic ports by default (20000-32000), static only for DNS (53) and load balancer (80/443)

### Execution Environment

- Based on `community-ee-minimal` container image
- Includes `ansible-core`, `ansible-runner`, and `community.general` collection
- Configured in `execution-environment.yml`

### Documentation Structure

- `docs/implementation/dns-ipam/implementation-plan.md`: Master plan for DNS & IPAM overhaul:

  - 5-phase implementation approach
  - Detailed task checklists
  - Risk assessments and mitigation strategies
  - Success criteria for each phase

- `docs/implementation/netbox-integration.md`: Comprehensive NetBox integration patterns including:

  - Dynamic inventory configuration
  - State management with NetBox modules
  - Runtime data queries with `netbox.netbox.nb_lookup`
  - Event-driven automation patterns

- `docs/implementation/secrets-management/infisical-setup.md`: Infisical secrets management guide:

  - Accurate explanation of projects, environments, folders, and secrets
  - Current state with secrets at `/apollo-13/`
  - Migration plan to organized folder structure
  - Ansible collection usage patterns

- `docs/archive/1password-integration.md`: 1Password Connect integration for secrets management (deprecated):
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
   - Use Infisical for secret retrieval (recommended)
   - 1Password Connect still available during transition
   - Environment variables for authentication

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
- Follow the implementation plan in `docs/implementation/dns-ipam/implementation-plan.md`
- Ensure Infisical environment variables are set before running commands (see `docs/implementation/secrets-management/infisical-setup.md`)
- Use the execution environment for consistency across different systems
- Always test inventory plugins with `ansible-inventory` before running playbooks
- NetBox integration should follow the patterns in `docs/implementation/netbox-integration.md`

## Recommended Tools

- For enhanced searching via bash commands use eza, fd, and rg

## Working with Specialized Agents

When working on tasks in this project, follow these guidelines:

### 1. Always Check for Specialized Agents First

Before starting any task, review available agents to see if one matches the work:

- **docs-agent**: Documentation updates, markdown fixes, doc organization
- **netbox-integration-engineer**: NetBox modules, lookups, source-of-truth patterns
- **ansible-playbook-developer**: Creating/testing playbooks, especially for NetBox/DNS/IPAM
- **task-master**: Project management, task tracking, priority evaluation
- **git-commit-organizer**: Creating clean commits from workspace changes
- **infrastructure-assessment-analyst**: Pre-implementation assessments and audits

### 2. Use Specialized Agents Proactively

Don't wait to be asked - if a task matches an agent's description, use it immediately. The agents are designed to handle specific domains more effectively than general-purpose approaches.

### 3. Avoid Defaulting to Direct Implementation

Resist the urge to jump straight into implementation. Take a moment to:

- Consider which agent best fits the task
- Use the agent's specialized knowledge and patterns
- Let agents handle their domains of expertise

This approach ensures better quality, consistency, and adherence to project patterns.
