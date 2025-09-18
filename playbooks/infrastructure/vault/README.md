# Vault Infrastructure Playbooks

![GitHub last commit](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration?path=playbooks/infrastructure/vault/README.md&display_timestamp=author&style=plastic&logo=github)

This directory contains Ansible playbooks for managing HashiCorp Vault infrastructure, including PKI, transit engine, Consul integration, and production deployment.

## 🔥 Smoke Test Procedure

### What is a Smoke Test?

A smoke test in DevOps refers to a set of basic, high-level tests run on a new deployment or build that verify whether the most critical functions of an application are working correctly, before proceeding to deeper and more comprehensive testing stages.

**Purpose**: Provide early detection of major issues such as deployment problems or severe configuration errors that could prevent the infrastructure automation from running at all. If smoke tests fail, further operations are halted, saving time and preventing potential damage.

**In this context**: We're testing that Ansible can successfully authenticate with Infisical and retrieve secrets needed for Vault operations, ensuring the basic infrastructure automation pipeline is functional.

### Running the Smoke Test

A comprehensive smoke test playbook is provided to verify both Ansible-Infisical integration and complete Vault infrastructure readiness:

```bash
# Standard smoke test (recommended before any production operations)
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
  -i inventory/environments/vault-cluster/production.yaml

# Include recovery key retrieval test (use sparingly - only when needed)
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
  -i inventory/environments/vault-cluster/production.yaml \
  --extra-vars "test_recovery_keys=true"

# Verbose output for debugging failed tests
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
  -i inventory/environments/vault-cluster/production.yaml \
  --extra-vars "verbose_output=true"

# Note: Do NOT use --check mode with smoke tests. Smoke tests are designed to
# detect real issues and always perform actual connectivity and authentication tests.
```

#### Comprehensive Test Coverage

The enhanced smoke test performs 12 categories of checks:

**Core Infrastructure (Tests 1-6):**

1. **Infisical Environment Variables**: Verifies mise has loaded credentials
2. **Secret Retrieval**: Tests fetching Vault tokens from Infisical
3. **Network Connectivity**: Checks HTTPS/HTTP API accessibility to all Vault nodes
4. **Vault Authentication**: Validates token authentication using Infisical credentials
5. **Raft Operations**: Lists Raft peers (equivalent to `vault operator raft list-peers`)
6. **Seal Status**: Checks if each Vault node is sealed/unsealed and initialized

**Authorization & Secrets (Tests 7-9):**
7. **Token Permissions**: Verifies token has required capabilities for operations
8. **Operational Secrets**: Validates all operational secrets are retrievable from Infisical
9. **Recovery Keys**: Confirms all 5 recovery keys exist (with optional retrieval test)

**Operational Readiness (Tests 10-12):**
10. **Write/Read Operations**: Tests actual secret write/read/delete operations
11. **Port Accessibility**: Verifies Vault API (8200) and Raft (8201) ports are open
12. **Disk Space**: Checks available disk space for Raft storage on production nodes

**SSH Connectivity:**

- Additional test for Ansible SSH access to all Vault nodes

The playbook provides a comprehensive summary showing:

- Pass/fail status for each test category
- Node-by-node connectivity results
- Raft cluster membership and leader status
- Specific, actionable next steps for any failures

### Smoke Test Results Interpretation

| Test                  | Pass Criteria         | Failure Indicates                               |
| --------------------- | --------------------- | ----------------------------------------------- |
| Environment Variables | Both return `true`    | mise not configured or .mise.local.toml missing |
| Infisical Lookup      | Returns `true`        | Authentication failed or network issues         |
| Specific Secret       | Returns secret name   | Secret doesn't exist or path incorrect          |
| Inventory Parse       | Shows success message | Syntax error in inventory or Infisical lookup   |
| Connectivity          | All hosts respond     | Network issues or SSH configuration             |
| Test Playbook         | Shows success message | Integration not working end-to-end              |

### When to Run Smoke Tests

- **Before** running any production Vault playbooks
- **After** updating mise configuration
- **After** rotating Infisical credentials
- **When** onboarding new team members
- **During** CI/CD pipeline before deployment
- **After** infrastructure changes or restarts
- **When** troubleshooting connectivity or authentication issues

## 🚨 CRITICAL: Dynamic Inventory Pattern

### The Anti-Pattern (NEVER DO THIS)

#### ❌ WRONG: Hardcoding infrastructure details in playbooks

```yaml
# This is BAD - hardcoded IPs defeat the purpose of inventory
- name: Configure services
  hosts: localhost
  vars:
    # ANTI-PATTERN: Hardcoded IPs
    service_nodes:
      - name: service-node-1
        address: 'https://192.168.10.30:8200'
      - name: service-node-2
        address: 'https://192.168.10.31:8200'

    # ANTI-PATTERN: Hardcoded leader
    leader_addr: 'https://192.168.10.31:8200'
```

**Why this is wrong:**

- **Violates DRY**: Duplicates information already in inventory
- **Maintenance nightmare**: Must update multiple files when IPs change
- **Environment coupling**: Playbook only works for one specific environment
- **Error prone**: Easy to have mismatches between inventory and playbook
- **Defeats inventory purpose**: Makes inventory irrelevant

### The Correct Pattern (ALWAYS DO THIS)

#### ✅ RIGHT: Dynamically discover from inventory

```yaml
# This is GOOD - uses inventory as single source of truth
- name: Configure services
  hosts: localhost
  pre_tasks:
    - name: Build service nodes list from inventory
      ansible.builtin.set_fact:
        service_nodes: |-
          {%- set nodes = [] -%}
          {%- for host in groups.get('service_cluster', []) -%}
            {%- set ip = hostvars[host]['ansible_host'] -%}
            {%- set port = hostvars[host].get('service_port', '8200') -%}
            {%- if ip|ansible.utils.ipaddr('ipv6') -%}
              {%- set address = 'https://[' + ip + ']:' + port -%}
            {%- else -%}
              {%- set address = 'https://' + ip + ':' + port -%}
            {%- endif -%}
            {%- set node = {
              'name': host,
              'address': address,
              'role': hostvars[host].get('service_role', 'unknown')
            } -%}
            {%- set _ = nodes.append(node) -%}
          {%- endfor -%}
          {{ nodes }}

    - name: Set leader address from inventory
      ansible.builtin.set_fact:
        leader_addr: |-
          {%- set leader_host = groups['service_leaders'][0] -%}
          {%- set ip = hostvars[leader_host]['ansible_host'] -%}
          {%- set port = hostvars[leader_host].get('service_port', '8200') -%}
          {%- if ip|ansible.utils.ipaddr('ipv6') -%}
            https://[{{ ip }}]:{{ port }}
          {%- else -%}
            https://{{ ip }}:{{ port }}
          {%- endif -%}
      when: groups.get('service_leaders', []) | length > 0
```

**Why this is correct:**

- **Single source of truth**: Inventory defines all infrastructure
- **Environment agnostic**: Same playbook works with dev/staging/prod inventories
- **IPv6 compatible**: Automatically wraps IPv6 addresses in square brackets for URLs
- **Automatic updates**: Changes to inventory automatically reflected
- **Maintainable**: Update only the inventory when infrastructure changes
- **Testable**: Can use different inventories for testing

**Requirements:**

- `ansible.utils` collection must be installed for the `ipaddr` filter
- The `ipaddr('ipv6')` filter detects IPv6 addresses and enables proper URL formatting

### Implementation Checklist

When writing playbooks, ensure:

- [ ] NO hardcoded IP addresses
- [ ] NO hardcoded hostnames (use inventory names)
- [ ] NO hardcoded ports (get from hostvars or defaults)
- [ ] NO hardcoded service addresses
- [ ] ALL infrastructure data comes from inventory via:
  - `groups` dictionary for group membership
  - `hostvars` dictionary for host variables
  - `inventory_hostname` for current host
  - Dynamic fact gathering with `set_fact`

### Validation Enforcement Example

To enforce the no-hardcoded-IPs convention in your playbooks, add this validation as a pre_task:

```yaml
- name: Example playbook with validation enforcement
  hosts: localhost
  vars:
    # Define any variables that might contain host/IP information
    service_endpoint: "{{ service_endpoint | default('') }}"
    database_host: "{{ database_host | default('') }}"
    api_base_url: "{{ api_base_url | default('') }}"

  pre_tasks:
    # Validate no hardcoded IPs before proceeding
    - name: Validate no hardcoded IP addresses
      ansible.builtin.include_tasks: "{{ playbook_dir }}/../../../tasks/validate-no-hardcoded-ips.yml"
      vars:
        validate_hostlike_vars:
          service_endpoint: "{{ service_endpoint }}"
          database_host: "{{ database_host }}"
          api_base_url: "{{ api_base_url }}"
        validate_allowlist: []  # Default: no IPs allowed. Override if needed for specific cases
      tags: [preflight]

    # Your other pre_tasks here
    - name: Build service nodes from inventory
      ansible.builtin.set_fact:
        service_nodes: |-
          {%- set nodes = [] -%}
          {%- for host in groups.get('vault_cluster', []) -%}
            {%- set ip = hostvars[host]['ansible_host'] -%}
            {%- set port = hostvars[host].get('vault_api_port', '8200') -%}
            {%- if ip | ansible.utils.ipaddr('ipv6') and not ip.startswith('[') -%}
              {%- set address = 'https://[' + ip + ']:' + port -%}
            {%- else -%}
              {%- set address = 'https://' + ip + ':' + port -%}
            {%- endif -%}
            {%- set _ = nodes.append({'name': host, 'address': address}) -%}
          {%- endfor -%}
          {{ nodes }}

  tasks:
    # Your playbook tasks here
    - name: Display service nodes
      debug:
        var: service_nodes
```

**Key points:**

- **Path resolution**: Uses `{{ playbook_dir }}/../../../tasks/` to reach the shared validation task
- **Variable specification**: Use `validate_hostlike_vars` to declare which variables to check
- **Default allowlist**: Set `validate_allowlist: []` to enforce zero hardcoded IPs
- **Override capability**: Add specific variable names to allowlist for legitimate exceptions
- **Preflight tagging**: Use `tags: [preflight]` to run validations separately if needed
- **Early failure**: Validation runs before any infrastructure operations

## 🔑 Vault Infisical Secrets Reference

All Vault-related secrets are stored in Infisical at path `/apollo-13/vault/` in the `prod` environment.

### Secret Types and Testing Strategy

| Secret Name | Type | Purpose | Used By | Smoke Test |
|------------|------|---------|---------|------------|
| **VAULT_PROD_ROOT_TOKEN** | Operational | Production cluster root token | All admin playbooks, PKI operations | ✅ Retrieved & Used |
| **VAULT_TRANSIT_TOKEN** | Operational | Transit engine auto-unseal token | Auto-unseal configuration, transit operations | ✅ Retrieved & Verified |
| **CONSUL_TOKEN_VAULT_MASTER_LLOYD** | Operational | Consul ACL for vault-master-lloyd | Consul service registration | ✅ Retrieved & Verified |
| **CONSUL_TOKEN_VAULT_PROD_1_HOLLY** | Operational | Consul ACL for vault-prod-1-holly | Consul service registration | ✅ Retrieved & Verified |
| **CONSUL_TOKEN_VAULT_PROD_2_MABLE** | Operational | Consul ACL for vault-prod-2-mable | Consul service registration | ✅ Retrieved & Verified |
| **CONSUL_TOKEN_VAULT_PROD_3_LLOYD** | Operational | Consul ACL for vault-prod-3-lloyd | Consul service registration | ✅ Retrieved & Verified |
| **VAULT_PROD_RECOVERY_KEY_1** | Recovery | Shamir key 1 of 5 (threshold: 3) | Emergency unseal only | ⚠️ Existence only* |
| **VAULT_PROD_RECOVERY_KEY_2** | Recovery | Shamir key 2 of 5 (threshold: 3) | Emergency unseal only | ⚠️ Existence only* |
| **VAULT_PROD_RECOVERY_KEY_3** | Recovery | Shamir key 3 of 5 (threshold: 3) | Emergency unseal only | ⚠️ Existence only* |
| **VAULT_PROD_RECOVERY_KEY_4** | Recovery | Shamir key 4 of 5 (threshold: 3) | Emergency unseal only | ⚠️ Existence only* |
| **VAULT_PROD_RECOVERY_KEY_5** | Recovery | Shamir key 5 of 5 (threshold: 3) | Emergency unseal only | ⚠️ Existence only* |

*Recovery keys are verified to exist but not retrieved during standard smoke tests. Use `--extra-vars "test_recovery_keys=true"` to test retrieval when necessary (e.g., after key rotation).

### Security Notes

- **Operational Secrets**: Used regularly by automation, tested on every smoke test run
- **Recovery Keys**: Write-only in normal operations, only retrieved during actual recovery scenarios
- **Access Control**: Machine identity should have read access to operational secrets, restricted access to recovery keys
- **Rotation**: Operational tokens should be rotated periodically; recovery keys only when compromised

## 📚 Playbook Directory

### Testing & Validation

#### [smoke-test.yml](./smoke-test.yml)

**Purpose**: Comprehensive smoke test for Vault infrastructure and Infisical integration
**Use Case**: Pre-deployment validation, troubleshooting connectivity issues
**Dependencies**: Infisical credentials, inventory configuration

### Core Deployment & Migration

#### [migrate-vault-master-to-production.yml](./migrate-vault-master-to-production.yml)

**Purpose**: Complete orchestration for migrating vault-master-lloyd from dev to production mode
**Use Case**: Issue #99 - Blue-green deployment strategy for zero-downtime migration
**Dependencies**: Requires PKI infrastructure, exports transit keys, deploys TLS

#### [deploy-vault-prod.yml](./deploy-vault-prod.yml)

**Purpose**: Deploy production Vault cluster with Raft storage
**Use Case**: Initial production cluster deployment with auto-unseal
**Dependencies**: Requires transit master operational

#### [initialize-production-vault.yml](./initialize-production-vault.yml)

**Purpose**: Initialize vault-master-lloyd with production configuration and Raft storage
**Use Case**: Convert dev instance to production mode with proper storage backend
**Dependencies**: Part of migration workflow

### PKI Infrastructure

#### [setup-pki-root-ca.yml](./setup-pki-root-ca.yml)

**Purpose**: Configure Vault PKI engine as root Certificate Authority
**Use Case**: Issue #95 - Establish root CA for infrastructure certificates
**Dependencies**: Vault must be unsealed and initialized

#### [setup-pki-intermediate-ca.yml](./setup-pki-intermediate-ca.yml)

**Purpose**: Create intermediate CA for issuing service certificates
**Use Case**: Issue #96 - Sign service certificates without exposing root CA
**Dependencies**: Root CA must be configured

#### [replace-self-signed-certificates.yml](./replace-self-signed-certificates.yml)

**Purpose**: Replace temporary self-signed certificates with CA-issued ones
**Use Case**: Issue #97 - Deploy proper PKI certificates to all Vault nodes
**Dependencies**: Intermediate CA operational

#### [deploy-tls-certificates.yml](./deploy-tls-certificates.yml)

**Purpose**: Generate and deploy TLS certificates from Vault PKI for vault-master-lloyd
**Use Case**: Part of production migration, 1-year TTL for transit master
**Dependencies**: PKI infrastructure operational

#### [validate-pki-certificates.yml](./validate-pki-certificates.yml)

**Purpose**: Verify certificate chain and expiration dates
**Use Case**: Regular validation of PKI infrastructure health
**Dependencies**: Certificates deployed

#### [monitor-pki-certificates.yml](./monitor-pki-certificates.yml)

**Purpose**: Check certificate expiration and alert on upcoming renewals
**Use Case**: Proactive certificate management
**Dependencies**: PKI certificates in use

#### [automated-certificate-renewal.yml](./automated-certificate-renewal.yml)

**Purpose**: Automate certificate renewal before expiry
**Use Case**: Issue #100 - Prevent certificate expiration outages
**Dependencies**: PKI infrastructure, valid root token

### Transit Engine & Auto-Unseal

#### [configure-transit-engine.yml](./configure-transit-engine.yml)

**Purpose**: Configure transit engine for auto-unseal operations
**Use Case**: Enable auto-unseal for production cluster
**Dependencies**: Vault initialized and unsealed

#### [export-transit-keys.yml](./export-transit-keys.yml)

**Purpose**: Export transit keys from dev instance for migration
**Use Case**: Backup transit keys before migration
**Dependencies**: Dev instance with transit engine

#### [setup-transit-master.yml](./setup-transit-master.yml)

**Purpose**: Configure dedicated transit instance for auto-unseal
**Use Case**: Separate transit concerns from storage
**Dependencies**: Dedicated Vault instance

#### [unseal-vault.yml](./unseal-vault.yml)

**Purpose**: Unseal Vault nodes using stored keys or auto-unseal
**Use Case**: Recovery after restart or maintenance
**Dependencies**: Unseal keys in Infisical

### Consul Integration

#### [deploy-consul-agents.yml](./deploy-consul-agents.yml)

**Purpose**: Deploy Consul agents to Vault nodes with full configuration
**Use Case**: Enable service discovery and health monitoring
**Dependencies**: Consul cluster operational

#### [deploy-consul-agents-simple.yml](./deploy-consul-agents-simple.yml)

**Purpose**: Simplified Consul agent deployment
**Use Case**: Quick Consul setup without complex ACLs
**Dependencies**: Consul servers available

#### [register-consul-service.yml](./register-consul-service.yml)

**Purpose**: Register vault-master-lloyd with Consul service discovery
**Use Case**: Enable health checks and service routing
**Dependencies**: Consul agent running, token in Infisical

#### [create-consul-acl-tokens.yml](./create-consul-acl-tokens.yml)

**Purpose**: Generate Consul ACL tokens for Vault nodes
**Use Case**: Secure Consul-Vault integration
**Dependencies**: Consul ACL system enabled

#### [check-consul-acl-status.yml](./check-consul-acl-status.yml)

**Purpose**: Verify Consul ACL configuration and token validity
**Use Case**: Troubleshooting Consul integration
**Dependencies**: Consul ACLs configured

#### [update-consul-acl-policy.yml](./update-consul-acl-policy.yml)

**Purpose**: Update Consul ACL policies for Vault services
**Use Case**: Adjust permissions after deployment
**Dependencies**: Existing ACL tokens

#### [update-consul-vault-integration.yml](./update-consul-vault-integration.yml)

**Purpose**: Reconfigure Consul-Vault integration settings
**Use Case**: Update after infrastructure changes
**Dependencies**: Both services operational

#### [vault-consul-status.yml](./vault-consul-status.yml)

**Purpose**: Check health of Vault-Consul integration
**Use Case**: Regular health monitoring
**Dependencies**: Integration configured

#### [final-vault-consul-verification.yml](./final-vault-consul-verification.yml)

**Purpose**: Complete verification of Vault-Consul setup
**Use Case**: Post-deployment validation
**Dependencies**: Full deployment complete

### Service Management

#### [register-vault-service-api.yml](./register-vault-service-api.yml)

**Purpose**: Register Vault service via Consul API
**Use Case**: Alternative to agent-based registration
**Dependencies**: Consul API accessible

#### [verify-vault-service-registration.yml](./verify-vault-service-registration.yml)

**Purpose**: Confirm Vault services properly registered
**Use Case**: Post-registration validation
**Dependencies**: Services registered

#### [fix-vault-service-registration.yml](./fix-vault-service-registration.yml)

**Purpose**: Troubleshoot and repair service registration issues
**Use Case**: Fix registration problems
**Dependencies**: Consul agent running

#### [fix-vault-health-checks.yml](./fix-vault-health-checks.yml)

**Purpose**: Repair failing health checks
**Use Case**: Resolve health check issues
**Dependencies**: Services registered

#### [update-health-checks-https.yml](./update-health-checks-https.yml)

**Purpose**: Update health checks for HTTPS endpoints
**Use Case**: After enabling TLS
**Dependencies**: TLS certificates deployed

### Secrets Management

#### [manage-secrets.yml](./manage-secrets.yml)

**Purpose**: General secret management operations
**Use Case**: Create, update, delete secrets in Vault
**Dependencies**: Vault unsealed, appropriate policies

#### [create-powerdns-secrets.yml](./create-powerdns-secrets.yml)

**Purpose**: Generate and store PowerDNS credentials in Vault
**Use Case**: Secure PowerDNS deployment
**Dependencies**: Vault KV engine enabled

### Maintenance & Operations

#### [configure-production-nodes.yml](./configure-production-nodes.yml)

**Purpose**: Apply production configuration to Vault nodes
**Use Case**: Standardize node configuration
**Dependencies**: Nodes accessible via SSH

#### [enable-vault-tls.yml](./enable-vault-tls.yml)

**Purpose**: Enable TLS listeners on Vault nodes
**Use Case**: Secure Vault API endpoints
**Dependencies**: TLS certificates available

#### [check-vault-tls-status.yml](./check-vault-tls-status.yml)

**Purpose**: Verify TLS configuration and certificate validity
**Use Case**: TLS troubleshooting
**Dependencies**: TLS enabled

#### [test-connectivity.yml](./test-connectivity.yml)

**Purpose**: Test network connectivity between Vault nodes
**Use Case**: Network troubleshooting
**Dependencies**: Nodes deployed

#### [cleanup-test-services.yml](./cleanup-test-services.yml)

**Purpose**: Remove test services and temporary configurations
**Use Case**: Clean up after testing
**Dependencies**: Test services exist

#### [reset-vault.yml](./reset-vault.yml)

**Purpose**: Complete Vault reset for disaster recovery
**Use Case**: Recovery from critical failures
**Dependencies**: Backup available

## 🚀 Usage Guidelines

### Prerequisites

1. **Environment Setup**

   ```bash
   # Ensure mise is configured
   cp .mise.local.toml.example .mise.local.toml
   # Add your Infisical credentials
   $EDITOR .mise.local.toml

   # Load environment
   mise trust
   mise env
   ```

2. **Required Environment Variables**

   - `INFISICAL_UNIVERSAL_AUTH_CLIENT_ID`
   - `INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET`

3. **Python Dependencies**

   ```bash
   # Install with secrets support
   uv sync --extra secrets
   ```

### Running Playbooks

```bash
# Standard execution with inventory
uv run ansible-playbook playbooks/infrastructure/vault/[playbook-name].yml \
  -i inventory/environments/vault-cluster/production.yaml

# With specific tags
uv run ansible-playbook playbooks/infrastructure/vault/[playbook-name].yml \
  -i inventory/environments/vault-cluster/production.yaml \
  --tags "deploy,configure"

# Dry run mode
uv run ansible-playbook playbooks/infrastructure/vault/[playbook-name].yml \
  -i inventory/environments/vault-cluster/production.yaml \
  --check
```

## 🔐 Security Notes

- All secrets are retrieved from Infisical at runtime
- No credentials should be hardcoded in playbooks
- Use `no_log: true` for sensitive operations
- Certificates have varying TTLs:
  - Production nodes: 30 days
  - Transit master: 1 year
  - Root CA: 10 years
  - Intermediate CA: 5 years

## 📝 Related Documentation

- [Vault PKI Infrastructure Implementation (Issue #94)](https://github.com/basher83/andromeda-orchestration/issues/94)
- [Infisical Complete Guide](../../../docs/implementation/infisical/infisical-complete-guide.md)
- [Vault Production Deployment](../../../docs/implementation/vault/production-deployment.md)
- [PKI Certificate Management](../../../docs/implementation/vault/pki-root-ca-setup.md)
