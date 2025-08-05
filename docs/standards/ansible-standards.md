# Ansible Standards

## Purpose
Define consistent Ansible patterns that ensure maintainable, testable, and scalable automation.

## Background
After migrating from static inventories and hardcoded credentials to dynamic infrastructure and centralized secrets, we've established patterns that scale with our infrastructure growth.

## Standard

### Directory Structure

```
playbooks/
├── assessment/        # Read-only assessment playbooks
├── infrastructure/    # Infrastructure deployment/management
│   ├── consul/       # Service-specific subdirectories
│   ├── nomad/        
│   └── monitoring/   
└── site.yml          # Master playbook (if needed)

inventory/
├── og-homelab/       # Per-cluster inventory
│   └── infisical.proxmox.yml
└── doggos-homelab/
    └── infisical.proxmox.yml

roles/
└── [future custom roles]
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
    separator: ''
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
  gather_facts: yes  # Explicitly set
  become: yes        # Explicitly set
  
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

#### Hierarchy (highest to lowest precedence)
1. **Command line** - Runtime overrides
2. **Playbook vars** - Playbook-specific
3. **Group vars** - Group-specific settings
4. **Host vars** - Host-specific settings
5. **Defaults** - Role defaults

#### Secrets Management
```yaml
# NEVER hardcode secrets
password: "{{ lookup('env', 'SERVICE_PASSWORD') }}"

# Use Infisical via environment
api_key: "{{ lookup('env', 'API_KEY') }}"

# Future: Direct Infisical lookup
secret: "{{ lookup('infisical', 'path/to/secret') }}"
```

### Module Usage

#### Preferred Modules
- `ansible.builtin.*` - Use builtin when available
- `community.general.nomad_job` - For Nomad deployments
- `netbox.netbox.*` - For NetBox integration
- `ansible.posix.*` - For POSIX operations

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
    job_file: "{{ job }}"  # Passed via -e job=path/to/job.hcl
    
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
        NOMAD_ADDR: "http://192.168.1.100:4646"  # ❌ Hardcoded
        NOMAD_TOKEN: "secret-token-123"          # ❌ Secret in code
```

## Exceptions

- **Emergency fixes** - May bypass standards with documentation
- **Third-party modules** - May require specific patterns
- **Legacy systems** - Gradual migration acceptable

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
- [Dynamic Inventory Guide](../implementation/secrets-management/infisical-setup.md)
- [Repository Structure](../getting-started/repository-structure.md)
- [uv with Ansible](../getting-started/uv-ansible-notes.md)

### External Resources
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [terraform-homelab](https://github.com/basher83/terraform-homelab) - Infrastructure provisioning (source of Proxmox VMs)