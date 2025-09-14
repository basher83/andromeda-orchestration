---
description: Execute the task for a given feature
argument-hint: [Task file]
---

# Execute Task

Implement a feature using using the task file.

## Task File

Task file path will be provided as argument, e.g., docs/project-management/tasks/<task-id>.md

- @$ARGUMENTS

## Project Context

You are working in an Ansible project with the following structure:

- Playbooks: playbooks/infrastructure/<service>/
- Inventory: inventory/environments/<cluster>/
- Target clusters: vault-cluster (production), doggos-homelab (nomad-consul cluster)
- Execution pattern: Always use `uv run ansible-playbook`
- Naming: Use kebab-case for files, follow existing patterns in the directory

## Current Infrastructure State

- Vault is deployed with PKI enabled at pki-int/
- Nomad/Consul cluster has TLS enabled
- Consul provides service discovery at \*.service.consul

## Quick Start Pattern

1. **Install all dependencies first**: `uv sync` (installs everything from pyproject.toml)
2. Copy structure from reference implementation in the task's Reference Implementations section
3. Use static-test.yml for syntax checks, target cluster inventory for execution
4. Variables are in inventory/environments/<cluster>/group_vars/all/
5. Secrets are managed via Infisical (see Secrets Management section below)

## Secrets Management

Secrets are retrieved using Infisical lookups. Pattern example:

```yaml
vars:
  consul_token: >-
    {{ lookup('infisical.vault.read_secrets',
              universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
              universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
              project_id='7b832220-24c0-45bc-a5f1-ce9794a31259',
              env_slug='prod',
              path='/apollo-13/consul',
              secret_name='CONSUL_MASTER_TOKEN').value }}
```

Note:

- The Infisical client credentials must be set in your environment via .mise.local.toml
- All Python dependencies must be installed: `uv sync` (includes infisicalsdk, hvac for Vault, python-nomad, etc.)
- Dependencies are defined in pyproject.toml

Common secret paths:

- Consul tokens: `/apollo-13/consul`
- Vault tokens: `/apollo-13/vault`
- Service credentials: `/apollo-13/services/<service-name>`

For more examples, see: `playbooks/examples/infisical-demo.yml`

### Fallback Pattern (if Infisical lookup fails)

If you encounter "worker was found in a dead state" or other Infisical lookup errors, use the CLI wrapper:

```bash
infisical run --env=prod --path="/apollo-13/vault" -- \
  uv run ansible-playbook playbooks/infrastructure/vault/<task-name>.yml \
  -i inventory/environments/doggos-homelab/proxmox.yml
```

This exports secrets as environment variables, then reference them in playbooks:

```yaml
vars:
  vault_token: "{{ lookup('env', 'VAULT_TOKEN') }}"
  consul_token: "{{ lookup('env', 'CONSUL_MASTER_TOKEN') }}"
```

## Specialized Sub-agents

`.claude/agents/ansible-research.md`

- Specialist for discovering official and community Ansible collections, assessing quality metrics, analyzing repository health, and providing integration recommendations for technologies like NetBox, Proxmox, Nomad, Consul, Vault, and DNS/IPAM systems.

`.claude/agents/github-implementation-research.md`

- Specialist designed to find high-quality code examples, patterns, and implementation strategies from GitHub repositories.

## Execution Process

1. **Load Task**

   - Read the specified task file @$ARGUMENTS
   - Understand all context and requirements
   - Follow all instructions in the task file and extend the research if needed
   - Ensure you have all needed context to implement the task fully
   - Do more web searches and codebase exploration as needed
   - Use ansible-research when task requires a new pattern not found in the codebase
   - Use github-implementation-research when task requires a integration strategy not found in the codebase

2. **ULTRATHINK**

   - Think hard before you execute the plan. Create a comprehensive plan addressing all requirements.
   - Break down complex tasks into smaller, manageable steps using your todos tools.
   - Use the TodoWrite tool to create and track your implementation plan.
   - Identify implementation patterns from existing code to follow.

3. **Execute the plan**

   - Update the task status to <In Progress> in `docs/project-management/tasks/README.md`
   - Update the task status to <In Progress> in `docs/project-management/tasks/<Task ID>.md`
   - Execute the task @$ARGUMENTS
   - Implement all the code

4. **Validate**

   - Run applicable checks based on files created:
     - `uv run ansible-playbook --syntax-check -i inventory/environments/doggos-homelab/static-test.yml playbooks/infrastructure/vault/<task-name>.yml` (where <task-name> matches the task ID, e.g., pki-001-create-roles)
     - `uv run ansible-lint playbooks/infrastructure/vault/<task-name>.yml` (where <task-name> matches the task ID, e.g., pki-001-create-roles)
     - `shellcheck scripts/<task-name>.sh` (where <task-name> matches the task ID, e.g., find-todos.sh)
     - `markdownlint-cli2 <document-name>.md` (where <document-name> matches the document name, e.g., README.md)
   - Run syntax checks after each major change, full validation after implementation
   - Common issues:
     - Module/plugin errors: **ALWAYS run `uv sync` first** to ensure all dependencies are installed:
       - hvac (for Vault modules)
       - python-nomad (for Nomad modules)
       - infisicalsdk (for secrets)
       - pynetbox (for NetBox integration)
     - Missing variables: check inventory/environments/<cluster>/group_vars/all/vault.yml
     - Authentication errors: ensure service addresses (VAULT_ADDR, CONSUL_HTTP_ADDR) are in inventory vars
     - Secret retrieval errors:
       - Verify all dependencies installed: `uv sync` then check with `uv pip list`
       - Ensure Infisical credentials are set via .mise.local.toml
       - If "worker was found in a dead state": use the Infisical CLI fallback pattern (see Secrets Management section)
     - Connection errors: verify target hosts are accessible via `uv run ansible -i inventory/environments/<cluster>/proxmox.yml <host> -m ping`
     - Missing dependencies: verify task prerequisites are completed
   - Re-run until all pass

5. **Complete**

   - Ensure all checklist items done
   - Run final validation suite
   - Report completion status
   - Read the task again to ensure you have implemented everything
   - Update the task status to <Blocked/Complete/Failed> in `docs/project-management/tasks/README.md`
   - Update the task status to <Blocked/Complete/Failed> in `docs/project-management/tasks/<Task ID>.md`

6. **Reference the Task**
   - You can always reference the task again if needed

Note: If validation fails, use error patterns in task to fix and retry.
