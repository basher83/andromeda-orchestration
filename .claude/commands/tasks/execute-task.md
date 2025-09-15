---
description: Execute the task for a given feature
argument-hint: [Task file]
---

# Execute Task

Implement a feature using the task file.

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

### Before Starting: Verify Infisical Integration

**IMPORTANT**: Before implementing any task, verify Infisical is working:

1. **Test the integration**: Run `uv run ansible-playbook playbooks/examples/infisical-test.yml`
2. **Verify success**: You should see "INFISICAL_SECRET_RETRIEVAL_WORKS!!"

If the test fails, see troubleshooting below.

### Infisical Integration Patterns

Three patterns are demonstrated in `playbooks/examples/infisical-test.yml`:

1. **Single Secret Retrieval**: Use `.value` accessor for individual secrets
2. **Multiple Secrets as Dict**: Use `as_dict=True` for all secrets from a path
3. **Complete Workflow**: Retrieve → Use → Cleanup pattern

For comprehensive documentation and patterns, see:

- `docs/implementation/infisical/infisical-complete-guide.md` - Complete setup and usage guide
- `docs/implementation/infisical/infisical-patterns.md` - Real-world implementation patterns
- `docs/implementation/infisical/infisical-official.md` - Official documentation reference

### Required Setup

- Python dependencies installed: `uv sync` (includes infisicalsdk)
- macOS users: Special configuration required (documented in infisical-complete-guide.md)

### Common Secret Paths and Names

- Consul: `/apollo-13/consul` → `CONSUL_MASTER_TOKEN`
- Vault: `/apollo-13/vault` → `VAULT_PROD_ROOT_TOKEN`
- Service credentials: `/apollo-13/services/<service-name>` → (varies by service)

### Troubleshooting

If `playbooks/examples/infisical-test.yml` fails:

1. **Check dependencies**: Run `uv pip list | grep infisical`
2. **Verify collection**: Run `ansible-galaxy collection list | grep infisical`
3. **Check env vars**: Run `mise env | grep INFISICAL`
4. **macOS users**: Ensure `OBJC_DISABLE_INITIALIZE_FORK_SAFETY = "YES"` is set in the environment

### Fallback Pattern (Last Resort)

If SDK integration continues to fail, use the Infisical CLI wrapper:

```bash
infisical run --env=prod --path="/apollo-13/vault" -- \
  uv run ansible-playbook playbooks/infrastructure/vault/<task-name>.yml \
  -i inventory/environments/vault-cluster/production.yaml
```

Then modify your playbook to use environment lookups:

```yaml
vars:
  vault_token: "{{ lookup('env', 'VAULT_PROD_ROOT_TOKEN') }}"
```

## Specialized Sub-agents

`.claude/agents/ansible-research.md`

- Specialist for discovering official and community Ansible collections, assessing quality metrics, analyzing repository health, and providing integration recommendations for technologies like NetBox, Proxmox, Nomad, Consul, Vault, and DNS/IPAM systems.

`.claude/agents/github-implementation-research.md`

- Specialist designed to find high-quality code examples, patterns, and implementation strategies from GitHub repositories.

## Execution Process

1. **Pre-flight Check**

   - Run `uv sync` to ensure all dependencies are installed
   - Verify Infisical integration: `uv run ansible-playbook playbooks/examples/infisical-test.yml`
   - Confirm you see "INFISICAL_SECRET_RETRIEVAL_WORKS!!"
   - If it fails, stop and troubleshoot using the Secrets Management section
   - Check target inventory: `uv run ansible-inventory -i inventory/environments/<target-cluster>/ --list`
     - This shows available hosts, groups, and variables configured for the environment
     - Pay attention to vars like `vault_addr`, `consul_http_addr`, etc.

2. **Load Task**

   - Read the specified task file @$ARGUMENTS
   - Understand all context and requirements
   - Follow all instructions in the task file and extend the research if needed
   - Ensure you have all needed context to implement the task fully
   - Review relevant role documentation if task involves those services:
     - `roles/vault/README.md` - Vault deployment and configuration patterns
     - `roles/consul/README.md` - Consul setup and ACL management
     - `roles/nomad/README.md` - Nomad cluster configuration
   - Do more web searches and codebase exploration as needed
   - Use ansible-research when task requires a new pattern not found in the codebase
   - Use github-implementation-research when task requires a integration strategy not found in the codebase

3. **ULTRATHINK**

   - Think hard before you execute the plan. Create a comprehensive plan addressing all requirements.
   - Break down complex tasks into smaller, manageable steps using your todos tools.
   - Use the TodoWrite tool to create and track your implementation plan.
   - Identify implementation patterns from existing code to follow.

4. **Execute the plan**

   - Update the task status to <In Progress> in `docs/project-management/tasks/README.md`
   - Update the task status to <In Progress> in `docs/project-management/tasks/<Task ID>.md`
   - Execute the task @$ARGUMENTS
   - Implement all the code following these CRITICAL patterns:

   ## 🚨 CRITICAL: Dynamic Inventory Pattern (MANDATORY)

   ### ❌ NEVER DO THIS (Anti-Pattern):

   ```yaml
   # WRONG: Hardcoded IPs/addresses in playbooks
   - name: Configure service
     hosts: localhost
     vars:
       service_endpoints:
         - address: "192.168.10.30:8200" # BAD: Hardcoded IP
         - address: "192.168.10.31:8200" # BAD: Hardcoded IP
       leader: "https://192.168.10.31:8200" # BAD: Hardcoded address
   ```

   ### ✅ ALWAYS DO THIS (Correct Pattern):

   ```yaml
   # RIGHT: Dynamic discovery from inventory
   - name: Configure service
     hosts: localhost
     pre_tasks:
       - name: Discover nodes from inventory
         ansible.builtin.set_fact:
           service_endpoints: |-
             {%- set nodes = [] -%}
             {%- for host in groups.get('service_group', []) -%}
               {%- set endpoint = {
                 'name': host,
                 'address': hostvars[host]['ansible_host'] + ':' + hostvars[host].get('service_port', '8200')
               } -%}
               {%- set _ = nodes.append(endpoint) -%}
             {%- endfor -%}
             {{ nodes }}
   ```

   **Why this matters:**

   - Inventory is the single source of truth
   - Playbooks work across all environments (dev/staging/prod)
   - No maintenance when infrastructure changes
   - Prevents IP mismatches and errors

   - For playbooks that use domain variables, include domain assertions:

     ```yaml
     pre_tasks:
       - name: Include domain validation
         ansible.builtin.include_tasks: ../../tasks/domain-assertions.yml
     ```

     This prevents `.local` domain usage (macOS mDNS conflict)

5. **Validate**

   - **MANDATORY: Include IP validation in all playbooks**:

     Every playbook MUST include this validation in pre_tasks:

     ```yaml
     - name: Your Playbook Name
       hosts: all
       any_errors_fatal: true # Critical - stop on validation failure
       pre_tasks:
         # This MUST be the first pre_task
         - name: Validate no hardcoded IPs
           ansible.builtin.include_tasks: ../../tasks/validate-no-hardcoded-ips.yml
           vars:
             validate_hostlike_vars:
               # List ALL variables that reference hosts/endpoints
               service_endpoint: "{{ service_endpoint | default('') }}"
               database_host: "{{ database_host | default('') }}"
               api_url: "{{ api_url | default('') }}"
               leader_addr: "{{ leader_addr | default('') }}"
             validate_allowlist: [] # Only add exceptions if absolutely necessary

         # Then build from inventory...
         - name: Discover service endpoints from inventory
           ansible.builtin.set_fact:
             service_endpoint: "{{ hostvars[groups['services'][0]]['ansible_host'] }}"
     ```

     This validation will:

     - Use ansible.utils.ipaddr filter to detect IPv4/IPv6 addresses
     - Fail immediately with clear remediation instructions
     - Ensure inventory is the single source of truth
     - Prevent deployment of hardcoded infrastructure

   - Run applicable checks based on files created:
     - `uv run ansible-playbook --syntax-check -i inventory/environments/doggos-homelab/static-test.yml playbooks/infrastructure/vault/<task-name>.yml` (where <task-name> matches the task ID, e.g., pki-001-create-roles)
     - `uv run ansible-lint --profile production playbooks/infrastructure/vault/<task-name>.yml` (where <task-name> matches the task ID, e.g., pki-001-create-roles)
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

6. **Complete**

   - Ensure all checklist items done
   - Run final validation suite
   - Report completion status
   - Read the task again to ensure you have implemented everything
   - Update the task status to <Blocked/Complete/Failed> in `docs/project-management/tasks/README.md`
   - Update the task status to <Blocked/Complete/Failed> in `docs/project-management/tasks/<Task ID>.md`

7. **Reference the Task**
   - You can always reference the task again if needed

Note: If validation fails, use error patterns in task to fix and retry.
