## Commands

### Running Playbooks with Infisical

```bash
# Run playbooks using uv with Infisical secrets
# First, install optional dependencies: uv sync --extra secrets
uv run ansible-playbook playbooks/site.yml -i inventory/og-homelab/infisical.proxmox.yml
```

**CRITICAL**: When working with NetBox or any playbooks that need Infisical secrets:

- ALWAYS use `uv run ansible-playbook` (not `ansible-playbook` directly)
- If you encounter "worker was found in a dead state" errors with Infisical lookups this indicates an error authenticating with the infisical API. You must verify the environment variables are set correctly via .mise.local.toml. The variables needed are INFISICAL_UNIVERSAL_AUTH_CLIENT_ID and INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET.

- As a last resort, you can get the token via the CLI and use the environment variable:

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

**Directory**: `inventory/` contains all dynamic and static inventory configurations

See [`inventory/README.md`](inventory/README.md) for comprehensive inventory documentation including:

- Current implementation details for Proxmox, Tailscale, Vault, and NetBox inventories
- Environment-specific configurations and host details
- Authentication setup and usage examples
- DNS & IPAM integration status and roadmap

### Nomad Job Management

**Directory**: `nomad-jobs/` contains all Nomad job specifications

See [`nomad-jobs/README.md`](nomad-jobs/README.md) for comprehensive Nomad job documentation including:

- Directory structure and organizational policy for job specifications
- Currently deployed services (Traefik, PowerDNS, PostgreSQL, Vault PKI services)
- Deployment procedures using Ansible playbooks and direct Nomad commands
- Job requirements including Consul service identity and port allocation strategy
- Service categories (core infrastructure, platform services, applications)
- Best practices for secrets management, volumes, and service discovery
- Troubleshooting guides for common deployment issues

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

For the current infrastructure deployment state and service configurations, see:
**[docs/operations/infrastructure-state.md](docs/operations/infrastructure-state.md)**

This includes detailed information about:

- Cluster configurations (og-homelab, doggos-homelab)
- Service deployments (Consul, Nomad, Vault, DNS, IPAM)
- Network topology and port allocations
- Version information and operational status

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
