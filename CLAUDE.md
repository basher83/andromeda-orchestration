# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible automation project that is working towards integrating NetBox as a source of truth for network
infrastructure management. The project uses multiple dynamic inventory sources (Proxmox, NetBox, Tailscale), and secure credential management through Infisical.

**Current Focus**: Implementing a comprehensive DNS & IPAM overhaul to transition from ad-hoc DNS management to a
service-aware infrastructure using Consul, PowerDNS, and NetBox. See `docs/implementation/dns-ipam/implementation-plan.md` for the
detailed implementation roadmap.

## Commands

### Running Playbooks with Infisical

```bash
# Run playbooks using uv with Infisical secrets
# First, install optional dependencies: uv sync --extra secrets
uv run ansible-playbook playbooks/site.yml -i inventory/og-homelab/infisical.proxmox.yml
```

**CRITICAL**: When working with NetBox or any playbooks that need Infisical secrets:

- ALWAYS use `uv run ansible-playbook` (not `ansible-playbook` directly)
- The Infisical Ansible collection (`infisical.vault.read_secrets`) has issues with Python virtual environments
- If you encounter "worker was found in a dead state" errors with Infisical lookups, use the CLI workaround:

  ```bash
  # Get token via CLI and use environment variable
  export NETBOX_TOKEN=$(infisical secrets get NETBOX_API_KEY --env=staging --path="/apollo-13/services/netbox" --plain)
  ansible-playbook playbooks/infrastructure/netbox-playbook.yml
  ```

  For detailed Infisical configuration and paths, see `docs/implementation/infisical/infisical-complete-guide.md`

- For localhost-only playbooks (like NetBox API operations), you can skip inventory:

  ```bash
  uv run ansible-playbook playbooks/infrastructure/netbox-dns-discover.yml
  ```

### Working with Dynamic Inventory

```bash
# Test inventory with Infisical (recommended)
uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --list
uv run ansible-inventory -i inventory/doggos-homelab/infisical.proxmox.yml --list

# Graph inventory structure
uv run ansible-inventory -i inventory/og-homelab/infisical.proxmox.yml --graph
uv run ansible-inventory -i inventory/doggos-homelab/infisical.proxmox.yml --graph
```

### Running Assessment Playbooks

```bash
# Infrastructure assessment playbooks (primarily built for doggos-homelab cluster)
uv run ansible-playbook playbooks/assessment/consul-health-check.yml -i inventory/doggos-homelab/infisical.proxmox.yml
uv run ansible-playbook playbooks/assessment/dns-ipam-audit.yml -i inventory/doggos-homelab/infisical.proxmox.yml
uv run ansible-playbook playbooks/assessment/infrastructure-readiness.yml -i inventory/doggos-homelab/infisical.proxmox.yml

# Note: Most playbooks are designed for doggos-homelab. Test carefully before running against og-homelab.
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

- **Directory**: `inventory/` contains all dynamic and static inventory configurations
- **Current Implementation**:
  - **Proxmox Dynamic Inventory**: Using `community.general.proxmox` plugin
    - `og-homelab/infisical.proxmox.yml` - Original cluster
    - `doggos-homelab/infisical.proxmox.yml` - 3-node Nomad cluster
  - **Tailscale Dynamic Inventory**:
    - `tailscale/ansible_tailscale_inventory.py` - Dynamic inventory script for Tailscale nodes
    - `tailscale-static.yml` - Static Tailscale inventory for testing
  - **Vault Cluster Inventory**:
    - `vault-cluster/production.yaml` - Dedicated 4-VM Vault production cluster
  - **NetBox Inventory**:
    - `netbox.yml` - NetBox dynamic inventory (functional, pending post-DNS-migration adjustments)
- **In Progress**: DNS & IPAM infrastructure deployment (see `docs/implementation/dns-ipam/implementation-plan.md`)
- **Planned**: Full NetBox dynamic inventory integration (see `docs/implementation/dns-ipam/netbox-integration-patterns.md` for patterns)
- **Authentication**:
  - Infisical: Machine identity credentials via environment variables
  - Tailscale: API key via environment variables
  - NetBox: API token via Infisical

### Nomad Job Management

- **Directory**: `nomad-jobs/` contains all Nomad job specifications
- **Structure**:
  - `core-infrastructure/` - Essential services (Traefik load balancer)
  - `platform-services/` - Infrastructure services (PowerDNS, future NetBox)
  - `applications/` - User-facing applications
- **Deployment**: Using `community.general.nomad_job` Galaxy module via playbooks
- **Port Strategy**: Dynamic ports by default (20000-32000), static only for DNS (53) and load balancer (80/443)

### Python Environment

- Uses `uv` for Python virtual environment management
- All Ansible commands run through `uv run` for consistency
- Dependencies managed in `pyproject.toml`

### Documentation Structure

- `docs/implementation/dns-ipam/implementation-plan.md`: Master plan for DNS & IPAM overhaul:

  - 5-phase implementation approach
  - Detailed task checklists
  - Risk assessments and mitigation strategies
  - Success criteria for each phase

- `docs/implementation/dns-ipam/netbox-integration-patterns.md`: Comprehensive NetBox integration patterns including:

  - Dynamic inventory configuration
  - State management with NetBox modules
  - Runtime data queries with `netbox.netbox.nb_lookup`
  - Event-driven automation patterns

- `docs/implementation/infisical/infisical-complete-guide.md`: Complete Infisical configuration guide:

  - Project setup and authentication
  - Current secret organization at `/apollo-13/` and `/services/`
  - Ansible collection usage patterns and examples
  - Troubleshooting and best practices

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
   - **Repository Secrets**: Use Infisical for Ansible playbook secrets and credentials
   - **Service Secrets**: Use Vault for lab services and application secrets going forward
   - Environment variables for authentication
   - **Known Issue**: Infisical Ansible collection may fail in virtual environments
   - **Workaround**: Use Infisical CLI to export secrets as environment variables

## Current Infrastructure State

### Clusters

- **og-homelab**: Original Proxmox cluster (proxmoxt430, pve1) mixed workload LXCs and VMs
- **doggos-homelab**: 3-node Proxmox cluster (lloyd, holly, mable) running Nomad
  - 3 Nomad servers (one per node)
  - 3 Nomad clients (one per node)
  - Tagged with: nomad, staging, terraform, server/client roles

### Services

- **Consul**: Production cluster with ACLs enabled (see below for details)
- **Nomad**: Production cluster operational on doggos-homelab (see below for details)
- **Vault**: Production cluster deployed with Raft storage and auto-unseal (see below for details)
- **DNS**: Currently Pi-hole + Unbound (to be migrated to PowerDNS)
- **IPAM**: Ad-hoc management (to be replaced with NetBox)

### Nomad Cluster

**Production Deployment**: Nomad orchestration platform for containerized workloads:

- **Servers** (Raft consensus):
  - nomad-server-1-lloyd: 192.168.11.11:4646-4648 (10G ops network)
  - nomad-server-2-holly: 192.168.11.12:4646-4648 (typically leader)
  - nomad-server-3-mable: 192.168.11.13:4646-4648
- **Clients** (Workers):
  - nomad-client-1-lloyd: 192.168.11.20
  - nomad-client-2-holly: 192.168.11.21
  - nomad-client-3-mable: 192.168.11.22
- **Network Configuration**: Dual NICs - 192.168.10.x (management), 192.168.11.x (10G operations)
- **Version**: v1.10.4 (server-1), v1.10.3 (server-2, server-3)
- **Features**: Docker driver, host volumes, dynamic volumes, Consul integration
- **ACLs**: Currently disabled (to be enabled)
- **Web UI**: Available on any server node port 4646

### Consul Cluster

**Production Deployment**: Service mesh and service discovery platform:

- **Servers** (Raft consensus):
  - nomad-server-1: 192.168.11.11:8300-8302,8500-8502,8600 (10G ops network)
  - nomad-server-2: 192.168.11.12:8300-8302,8500-8502,8600 (typically leader)
  - nomad-server-3: 192.168.11.13:8300-8302,8500-8502,8600
- **Clients**:
  - nomad-client-1: 192.168.11.20:8301,8500,8600
  - nomad-client-2: 192.168.11.21:8301,8500,8600
  - nomad-client-3: 192.168.11.22:8301,8500,8600
- **Network Configuration**: Dual NICs - 192.168.10.x (management), 192.168.11.x (10G operations)
- **Version**: v1.21.4 (server-1), v1.21.3 (server-2, server-3, all clients)
- **Datacenter**: dc1
- **ACLs**: Enabled with bootstrap tokens
- **DNS**: Available on port 8600
- **Web UI**: Available on any node port 8500

### Vault Cluster

**Production Deployment**: Secrets management platform with dedicated 4-VM cluster:

- **Transit Master**: vault-master-lloyd (VM 3100) - Provides auto-unseal service
- **Production Raft Cluster**:
  - vault-prod-1-holly (VM 3201)
  - vault-prod-2-mable (VM 3202)
  - vault-prod-3-lloyd (VM 3203)
- **Domain**: vault.spaceships.work (configured, deployment pending verification)
- **Storage**: Raft consensus with integrated storage
- **Security**: TLS enabled, auto-unseal via transit engine
- **Inventory**: `inventory/vault-cluster/production.yaml`
- **Authentication**: Access tokens and recovery keys stored in Infisical at `/apollo-13/vault/`

For detailed operations guides, see:

- `docs/operations/vault-access.md`
- `docs/implementation/nomad/`
- `docs/implementation/consul/`

## Important Considerations

- The project is actively implementing DNS & IPAM infrastructure changes
- Follow the implementation plan in `docs/implementation/dns-ipam/implementation-plan.md`
- Ensure Infisical environment variables are set before running commands (see `docs/implementation/infisical/infisical-complete-guide.md`)
- Use the execution environment for consistency across different systems
- Always test inventory plugins with `ansible-inventory` before running playbooks
- NetBox integration should follow the patterns in `docs/implementation/dns-ipam/netbox-integration-patterns.md`
- **ALWAYS use `uv run` prefix for Ansible commands** to ensure proper Python environment
- NetBox DNS plugin is installed and operational

## Recommended Tools

- For enhanced searching via bash commands use eza, fd, and rg

## Working with Specialized Agents

When working on tasks in this project, follow these guidelines:

### 1. Always Check for Specialized Agents First

Before starting any task, review available agents to see if one matches the work:

**Linting & Code Quality:**

- **lint-master**: Comprehensive linting coordinator for multiple file types
- **ansible-linter**: Ansible playbook and role linting
- **python-linter**: Python code linting and formatting (ruff, mypy, pylint)
- **yaml-linter**: YAML file validation and formatting
- **shell-linter**: Shell script validation with shellcheck
- **hcl-linter**: HCL/Nomad job file validation and formatting
- **markdown-linter**: Markdown documentation formatting and standards

**Project Management & Documentation:**

- **project-orchestrator**: Sprint planning, phase tracking, project management
- **documentation-specialist**: Creating, updating, and organizing documentation
- **commit-craft**: Creating clean, logical commits following conventional standards

**Meta:**

- **meta-agent**: Generates new sub-agent configurations

### 2. Use Specialized Agents Proactively

Don't wait to be asked - if a task matches an agent's description, use it immediately. The agents are designed to handle specific domains more effectively than general-purpose approaches.

### 3. Avoid Defaulting to Direct Implementation

Resist the urge to jump straight into implementation. Take a moment to:

- Consider which agent best fits the task
- Use the agent's specialized knowledge and patterns
- Let agents handle their domains of expertise

This approach ensures better quality, consistency, and adherence to project patterns.
