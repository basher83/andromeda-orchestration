# Ansible Standards

## Purpose

Define consistent Ansible patterns that ensure maintainable, testable, and scalable automation.

## Background

After migrating from static inventories and hardcoded credentials to dynamic infrastructure and centralized secrets, we've established patterns that scale with our infrastructure growth.

## Standard

### Directory Structure

#### Role-First Architecture

```text
roles/                 # PRIMARY automation logic
├── consul/           # Service roles (reusable)
│   ├── tasks/
│   ├── templates/
│   ├── defaults/
│   ├── handlers/
│   ├── meta/
│   ├── molecule/     # Testing
│   └── README.md
├── nomad/
└── monitoring/

playbooks/            # ORCHESTRATION only
├── site.yml         # Main deployment
├── infra.yml        # Infrastructure subset
├── monitoring.yml   # Monitoring subset
└── assessment/      # Read-only assessments

inventory/
├── inventory.yml    # Dynamic inventory
├── group_vars/      # Group variables
│   ├── all/
│   │   ├── global.yml
│   │   └── vault.yml     # Encrypted secrets
│   ├── consul_servers/
│   └── nomad_clients/
└── host_vars/       # Host-specific overrides
```

#### Anti-Pattern to Avoid

```text
❌ playbooks/infrastructure/consul/deploy-consul.yml
❌ playbooks/infrastructure/consul/configure-consul.yml
❌ playbooks/infrastructure/consul/backup-consul.yml

✅ roles/consul/              # All consul logic here
✅ playbooks/site.yml         # Just orchestrates roles
```

### Inventory Strategy

#### Why Dynamic Proxmox Inventories?

1. **Source of Truth**: Proxmox IS the truth for what VMs exist
2. **Auto-discovery**: New VMs automatically appear
3. **Consistent Metadata**: Tags, descriptions auto-populate groups
4. **No Drift**: Can't forget to update inventory
5. **Multi-cluster**: Each cluster has its own inventory

#### Configuration Pattern

```yaml
plugin: community.general.proxmox
api_host: "{{ lookup('env', 'PROXMOX_HOST') }}"
api_user: "{{ lookup('env', 'PROXMOX_USER') }}"
api_password: "{{ lookup('env', 'PROXMOX_PASSWORD') }}"

# Dynamic grouping based on Proxmox metadata
keyed_groups:
  - key: tags
    separator: ""
  - key: status
    prefix: status
compose:
  ansible_host: "interfaces[0].ip | default(name)"
```

### Playbook Standards

#### Naming Convention

- Use descriptive kebab-case: `deploy-consul-servers.yml`
- Prefix with action: `deploy-`, `configure-`, `backup-`, `check-`
- Include target: `-consul-`, `-nomad-`, `-monitoring-`

#### Structure

```yaml
---
- name: Clear description of playbook purpose
  hosts: appropriate_group
  gather_facts: yes # Explicitly set
  become: yes # Explicitly set

  vars:
    # Playbook-level variables

  pre_tasks:
    - name: Validation tasks

  roles:
    - role: role_name
      when: condition

  tasks:
    - name: Descriptive task names
      module_name:
        param: value
      tags:
        - relevant
        - tags

  post_tasks:
    - name: Verification tasks

  handlers:
    - name: Handler name
```

### Variable Management

#### Complete Hierarchy (highest to lowest precedence)

1. **Extra vars (-e)** - Command line overrides
2. **Task vars (set_fact, register)** - Runtime variables
3. **Block vars** - Block-scoped variables
4. **Role and include vars** - Role variable files
5. **Play vars** - Playbook-specific vars
6. **Host facts** - Gathered system facts
7. **Playbook vars_prompt** - Interactive input
8. **Playbook vars_files** - Variable files
9. **Role params** - Role parameters
10. **Include params** - Include parameters
11. **Role defaults** - Role default values
12. **Group vars (all)** - Global group variables
13. **Group vars (specific)** - Specific group variables
14. **Host vars** - Host-specific settings
15. **Inventory vars** - Inventory-defined variables

#### Secrets Management

```yaml
# NEVER hardcode secrets
password: "{{ lookup('env', 'SERVICE_PASSWORD') }}"

# Use Infisical via environment
api_key: "{{ lookup('env', 'API_KEY') }}"

# Direct Infisical lookup
        netbox_token: >-
          {{ (lookup('infisical.vault.read_secrets',
                     universal_auth_client_id=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID'),
                     universal_auth_client_secret=lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET'),
                     project_id=infisical_project_id,
                     env_slug=infisical_env,
                     path='/apollo-13/services/netbox',
                     secret_name='NETBOX_API_KEY')).value }}

# Validate secrets exist
pre_tasks:
  - name: Validate required secrets
    fail:
      msg: "Required secret {{ item }} not found"
    when: ansible_env[item] is not defined or ansible_env[item] == ''
    loop:
      - DATABASE_PASSWORD
      - API_KEY
    tags: validation

# Never log sensitive data
- name: Configure with secrets
  template:
    src: config.j2
    dest: /etc/service/config
    mode: '0600'
  no_log: true
  notify: restart service

# Use ansible-vault for group_vars secrets
# group_vars/prod/vault.yml (encrypted)
$ANSIBLE_VAULT;1.1;AES256
database_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256...
```

### Collection Management

#### Required Collections (requirements.yml)

```yaml
collections:
  - name: community.general      # >=8.0.0  - Core community modules
  - name: community.proxmox      # >=1.0.0  - Proxmox management
  - name: netbox.netbox          # >=3.13.0 - NetBox integration
  - name: infisical.vault        # >=1.1.0  - Secrets management
  - name: community.postgresql   # >=4.1.0  - Database operations
  - name: ansible.posix          # >=1.5.0  - POSIX operations
  - name: ansible.utils          # >=2.10.0 - Data utilities
  - name: community.hashi_vault  # ==7.0.0  - HashiCorp Vault
```

#### Installation

```bash
# Install all required collections
ansible-galaxy collection install -r requirements.yml

# Or with uv (recommended)
uv run ansible-galaxy collection install -r requirements.yml

# Force reinstall/upgrade
ansible-galaxy collection install -r requirements.yml --force

# Install to specific location
ansible-galaxy collection install -r requirements.yml -p ./collections
```

#### Version Pinning Strategy

- **Exact versions** (`==7.0.0`) - For critical dependencies with breaking changes
- **Minimum versions** (`>=8.0.0`) - For stable, backward-compatible collections
- **Range constraints** (`>=4.1.0,<4.2.0`) - For known compatibility windows
- **Latest compatible** (`>=1.0.0`) - For actively maintained collections

Always test collection updates in development before production deployment.

### Module Usage

#### Module Security Priority (highest to lowest trust)

1. **ansible.builtin.\*** - Core modules, highest security
2. **ansible.posix.\*** - POSIX compliance, well-maintained
3. **Official collections** - Vendor-maintained (e.g., netbox.netbox.\*)
4. **community.general.\*** - Community-maintained, established
5. **Other community collections** - Use with caution
6. **Custom modules** - Requires security review

#### Preferred Modules by Function

- **Files**: `ansible.builtin.copy`, `template`, `file` (not `raw`)
- **Services**: `ansible.builtin.service`, `systemd` (not `shell`)
- **Network**: `ansible.builtin.uri` with validation
- **Package Management**: `ansible.builtin.package`, `apt`, `yum` (not `shell`)
- **User Management**: `ansible.builtin.user`, `group` (not manual commands)

#### Infrastructure-Specific Modules

- **Proxmox**: `community.proxmox.*` - VM/container management
- **Nomad**: `community.general.nomad_job`, custom modules in `plugins/modules/nomad_*`
- **NetBox**: `netbox.netbox.*` - IPAM and DCIM operations
- **Consul**: `community.general.consul*`, custom modules in `plugins/modules/consul_*`
- **Vault**: `community.hashi_vault.vault_*` - Secret management
- **PostgreSQL**: `community.postgresql.*` - Database operations
- **Infisical**: `infisical.vault.*` - Alternative secrets management

#### Utility Collections

- **POSIX Operations**: `ansible.posix.*` - ACLs, mounts, sysctls
- **Data Manipulation**: `ansible.utils.*` - Filters and lookups for data transformation

#### Modules to Avoid

- `raw`, `command`, `shell` - Use specific modules instead
- Deprecated modules - Check documentation
- Modules without active maintenance

#### Module Pattern

```yaml
- name: Deploy Nomad job
  community.general.nomad_job:
    state: present
    content: "{{ lookup('file', job_file) }}"
    force_start: "{{ force | default(false) }}"
    host: "{{ nomad_host }}"
  delegate_to: localhost
  run_once: true
```

## Rationale

### Why Dynamic Inventory?

- **Automation**: No manual inventory maintenance
- **Accuracy**: Always reflects actual infrastructure
- **Scalability**: Works for 10 or 1000 nodes
- **Integration**: Pulls from authoritative sources

### Why This Structure?

- **Logical Grouping**: Related playbooks together
- **Clear Purpose**: Directory names indicate function
- **Reusability**: Modular playbooks and roles
- **Maintainability**: Easy to find and update

### Why Environment Variables for Secrets?

- **Security**: No secrets in code
- **Flexibility**: Different values per environment
- **Simplicity**: Works with any secret backend
- **Auditability**: Secret access is logged

## Examples

### Good Example

```yaml
# playbooks/infrastructure/nomad/deploy-job.yml
---
- name: Deploy Nomad job from file
  hosts: localhost
  gather_facts: no

  vars:
    nomad_host: "{{ lookup('env', 'NOMAD_ADDR') }}"
    job_file: "{{ job }}" # Passed via -e job=path/to/job.hcl

  tasks:
    - name: Validate job file exists
      ansible.builtin.stat:
        path: "{{ job_file }}"
      register: job_stat

    - name: Deploy job to Nomad
      community.general.nomad_job:
        state: present
        content: "{{ lookup('file', job_file) }}"
        host: "{{ nomad_host }}"
      when: job_stat.stat.exists
```

### Bad Example

```yaml
# ❌ Hardcoded values, poor structure
- hosts: all
  tasks:
    - shell: nomad job run /path/to/job.hcl
      environment:
        NOMAD_ADDR: "http://192.168.1.100:4646" # ❌ Hardcoded
        NOMAD_TOKEN: "secret-token-123" # ❌ Secret in code
```

### Security Standards

#### Access Control

```yaml
# Explicit privilege escalation
- name: System configuration
  template:
    src: config.j2
    dest: /etc/service/config
    mode: "0644"
    owner: root
    group: root
  become: yes
  become_user: root
  become_method: sudo
```

#### Validation and Idempotency

```yaml
# Always validate prerequisites
pre_tasks:
  - name: Validate environment
    assert:
      that:
        - ansible_version.full is version('2.12', '>=')
        - target_environment in ['dev', 'staging', 'prod']
        - ansible_os_family == 'Debian'
      fail_msg: "Environment validation failed"
    tags: validation

# Test idempotency in post_tasks
post_tasks:
  - name: Verify service state (idempotency check)
    service:
      name: "{{ service_name }}"
      state: started
    check_mode: yes
    register: service_check
    failed_when: service_check.changed
    tags: validation
```

#### Error Handling

```yaml
# Retry critical operations
- name: Start service with retry
  service:
    name: "{{ service_name }}"
    state: started
  register: service_result
  retries: 3
  delay: 10
  until: service_result is succeeded

# Graceful degradation for optional tasks
- name: Optional monitoring setup
  include_tasks: monitoring.yml
  ignore_errors: yes
  tags: optional

# Proper error messages
- name: Validate configuration
  fail:
    msg: "Configuration invalid: {{ validation_errors | join(', ') }}"
  when: validation_errors | length > 0
```

### Testing Standards

#### Required Testing

1. **Syntax validation**: `ansible-playbook --syntax-check`
2. **Lint checking**: `ansible-lint playbook.yml`
3. **Check mode**: `ansible-playbook --check --diff`
4. **Molecule tests**: For all roles
5. **Integration tests**: End-to-end scenarios

#### Test Structure

```yaml
# Role testing with Molecule
roles/service/
├── molecule/
│   ├── default/
│   │   ├── molecule.yml      # Test configuration
│   │   ├── converge.yml      # Test playbook
│   │   ├── verify.yml        # Verification tasks
│   │   └── prepare.yml       # Test setup
│   └── docker/               # Container tests
├── tests/
│   └── test.yml              # Basic role tests
└── .ansible-lint             # Linting rules
```

#### CI/CD Integration

```yaml
# .github/workflows/ansible-ci.yml
name: Ansible CI
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run ansible-lint
        uses: ansible/ansible-lint-action@v6

  molecule:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        role: [consul, nomad, vault]
    steps:
      - name: Run Molecule tests
        run: cd roles/${{ matrix.role }} && molecule test
```

### Role Standards

#### Role Structure (Required)

```text
roles/service_name/
├── README.md              # REQUIRED - Usage documentation
├── meta/
│   └── main.yml          # REQUIRED - Dependencies, platforms
├── defaults/
│   └── main.yml          # REQUIRED - Default variables
├── vars/                 # OS-specific variables
│   ├── Debian.yml
│   └── RedHat.yml
├── tasks/
│   ├── main.yml          # REQUIRED - Entry point
│   ├── install.yml       # Installation tasks
│   ├── configure.yml     # Configuration tasks
│   └── validate.yml      # Validation tasks
├── templates/            # Jinja2 templates
├── files/               # Static files
├── handlers/
│   └── main.yml          # Service handlers
├── molecule/            # REQUIRED - Testing
│   ├── default/
│   │   ├── molecule.yml
│   │   ├── converge.yml
│   │   └── verify.yml
│   └── docker/         # Container tests
├── tests/
│   └── test.yml         # Basic integration tests
└── .ansible-lint        # Linting configuration
```

#### Role Naming Convention

- **Service roles**: `consul`, `nomad`, `vault`
- **Function roles**: `system_base`, `monitoring`, `backup`
- **Integration roles**: `consul_template`, `netdata_consul`
- Use underscores, not hyphens
- Descriptive but concise names

#### Role Documentation (README.md Template)

```markdown
# Role: service_name

## Description
Brief description of what this role does.

## Requirements
- Ansible >= 2.12
- Target OS: Ubuntu 20.04+, RHEL 8+
- Required collections: community.general

## Role Variables

### Required Variables

```yaml
service_version: "1.15.2"          # Service version
service_datacenter: "dc1"           # Datacenter name
```

### Optional Variables

```yaml
service_port: 8500                  # Default port
service_bind_address: "0.0.0.0"     # Bind address
service_enable_tls: false           # TLS configuration
```

## Dependencies

- system_base (for common setup)

## Example Playbook

```yaml
- hosts: consul_servers
  roles:
    - role: consul
      consul_node_role: "{{ datacenter }}"
      consul_datacenter: "{{ datacenter }}"
```

## Testing

```bash
# Run molecule tests
cd roles/service_name
molecule test

# Specific scenario
molecule test -s docker
```

## License

MIT

## Author

Your Organization

### Role Variable Standards

```yaml
# defaults/main.yml - Always document variables
---
# Service configuration
service_name: consul
service_version: "1.15.2"
service_user: "{{ service_name }}"
service_group: "{{ service_name }}"

# Network configuration
service_port: 8500
service_bind_address: "{{ ansible_default_ipv4.address }}"
service_client_addr: "0.0.0.0"

# Paths (follow FHS)
service_config_dir: "/etc/{{ service_name }}"
service_data_dir: "/opt/{{ service_name }}"
service_log_dir: "/var/log/{{ service_name }}"

# Feature flags
service_enable_tls: false
service_enable_ui: true
service_enable_logging: true

# Performance
service_memory_limit: "512M"
service_cpu_limit: "1.0"
```

### Role Task Organization

```yaml
# tasks/main.yml - Orchestrates role execution
---
- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"
  tags: [install, configure]

- import_tasks: validate.yml
  tags: [validate, never]
  when: validate_role | default(false)

- import_tasks: install.yml
  tags: [install]

- import_tasks: configure.yml
  tags: [configure]

- name: Ensure service is started and enabled
  service:
    name: "{{ service_name }}"
    state: started
    enabled: yes
  tags: [configure, service]

- import_tasks: validate.yml
  tags: [validate]
  when: validate_after_deployment | default(true)
```

#### Role Testing Requirements

```yaml
# molecule/default/molecule.yml
---
dependency:
  name: galaxy
  options:
    requirements-file: requirements.yml
driver:
  name: docker
platforms:
  - name: instance-ubuntu-20
    image: geerlingguy/docker-ubuntu2004-ansible:latest
    pre_build_image: true
    privileged: true
    volume_mounts:
      - "/sys/fs/cgroup:/sys/fs/cgroup:rw"
    command: "/lib/systemd/systemd"
  - name: instance-centos-8
    image: geerlingguy/docker-centos8-ansible:latest
    pre_build_image: true
    privileged: true
    volume_mounts:
      - "/sys/fs/cgroup:/sys/fs/cgroup:rw"
    command: "/usr/sbin/init"
provisioner:
  name: ansible
  config_options:
    defaults:
      callbacks_enabled: timer,profile_tasks
  inventory:
    host_vars:
      instance-ubuntu-20:
        validate_role: true
verifier:
  name: ansible
```

#### Role Dependencies (meta/main.yml)

```yaml
---
galaxy_info:
  role_name: service_name
  author: Your Organization
  description: Service deployment and configuration
  license: MIT
  min_ansible_version: 2.12
  platforms:
    - name: Ubuntu
      versions:
        - focal
        - jammy
    - name: EL
      versions:
        - 8
        - 9
  galaxy_tags:
    - service
    - infrastructure
    - hashicorp

dependencies:
  - role: system_base
    when: install_system_base | default(true)
  - role: ntp
    when: service_requires_time_sync | default(false)

collections:
  - community.general
  - ansible.posix
```

#### Role Versioning and Tagging

```bash
# Version tags for roles
git tag -a role-consul-v1.2.0 -m "Consul role version 1.2.0"
git tag -a role-nomad-v2.1.0 -m "Nomad role version 2.1.0"

# Semantic versioning for roles
# v1.0.0 - Major: Breaking changes
# v1.1.0 - Minor: New features, backward compatible
# v1.1.1 - Patch: Bug fixes
```

### Tagging Strategy

#### Standard Tags

```yaml
tags:
  - install # Installation tasks
  - configure # Configuration changes
  - validate # Validation/verification
  - security # Security hardening
  - optional # Non-critical tasks
  - never # Skip by default
  - service:name # Service-specific
  - env:prod # Environment-specific
  - debug # Debug/troubleshooting
```

#### Tag Usage

```bash
# Run only installation
ansible-playbook site.yml --tags install

# Skip optional tasks
ansible-playbook site.yml --skip-tags optional

# Service-specific deployment
ansible-playbook site.yml --tags service:consul

# Role-specific operations
ansible-playbook site.yml --tags consul
```

## Exceptions

- **Emergency fixes** - May bypass standards with documentation
- **Third-party modules** - May require specific patterns
- **Legacy systems** - Gradual migration acceptable
- **Security exceptions** - Must be documented and time-limited

## Migration

1. **Inventory Migration**:

   ```bash
   # Move from static to dynamic
   mv inventory/hosts.ini inventory/.archive/
   cp inventory/templates/infisical.proxmox.yml inventory/cluster/
   ```

2. **Playbook Cleanup**:

   - Extract hardcoded values to variables
   - Move secrets to environment lookups
   - Reorganize into proper directories

3. **Testing Migration**:
   - Add molecule tests for roles
   - Create check-mode playbooks
   - Implement pre-commit hooks

## References

### Internal Documentation

- [Dynamic Inventory Guide](../implementation/infisical/infisical-setup.md)
- [Repository Structure](../getting-started/repository-structure.md)
- [uv with Ansible](../getting-started/uv-ansible-notes.md)

### External Resources

- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Spacelift Ansible Best Practices](https://spacelift.io/blog/ansible-best-practices) - Comprehensive guide covering variables, secrets, testing, and optimization
- [How to Evaluate Community Ansible Roles](https://www.jeffgeerling.com/blog/2019/how-evaluate-community-ansible-roles-your-playbooks) - Jeff Geerling's guide for vetting third-party roles
- [terraform-homelab](https://github.com/basher83/terraform-homelab) - Infrastructure provisioning (source of Proxmox VMs)
