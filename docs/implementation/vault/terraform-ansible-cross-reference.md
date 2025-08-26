# Terraform-Ansible Cross-Reference for Vault Infrastructure

## Overview

This document provides a comprehensive cross-reference between Terraform infrastructure provisioning and Ansible configuration management for the Vault cluster deployment. It ensures consistency between infrastructure-as-code and configuration management while maintaining clear separation of concerns.

## Infrastructure Layer (Terraform)

### VM Provisioning

Terraform manages the underlying VM infrastructure for the Vault cluster:

```hcl
# VM definitions in Terraform
resource "proxmox_vm_qemu" "vault_master" {
  vmid        = 3100
  name        = "vault-master-lloyd"
  target_node = "lloyd"
  memory      = 2048
  cores       = 2
  sockets     = 1

  disk {
    storage = "local-lvm"
    type    = "scsi"
    size    = "20G"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
}

resource "proxmox_vm_qemu" "vault_production" {
  count       = 3
  vmid        = 3201 + count.index
  name        = "vault-prod-${count.index + 1}-${var.node_names[count.index]}"
  target_node = var.node_names[count.index]
  memory      = 2048
  cores       = 2
  sockets     = 1

  disk {
    storage = "local-lvm"
    type    = "scsi"
    size    = "20G"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }
}
```

### Network Configuration

```hcl
# Network variables passed to cloud-init
locals {
  vault_nodes = {
    vault-master-lloyd = {
      ip_address = "192.168.10.100"
      gateway    = "192.168.10.1"
    }
    vault-prod-1-holly = {
      ip_address = "192.168.10.101"
      gateway    = "192.168.10.1"
    }
    vault-prod-2-mable = {
      ip_address = "192.168.10.102"
      gateway    = "192.168.10.1"
    }
    vault-prod-3-lloyd = {
      ip_address = "192.168.10.103"
      gateway    = "192.168.10.1"
    }
  }
}
```

## Configuration Layer (Ansible)

### Inventory Mapping

Ansible inventory maps to Terraform-provisioned resources:

| Terraform Resource | Ansible Host | VM ID | Physical Node |
|-------------------|--------------|-------|---------------|
| `vault_master` | `vault-master-lloyd` | 3100 | lloyd |
| `vault_production[0]` | `vault-prod-1-holly` | 3201 | holly |
| `vault_production[1]` | `vault-prod-2-mable` | 3202 | mable |
| `vault_production[2]` | `vault-prod-3-lloyd` | 3203 | lloyd |

### Variable Consistency

Ansible host variables must align with Terraform resource attributes:

```yaml
# Ansible host_vars/vault-master-lloyd.yml
proxmox_node: lloyd        # Matches Terraform target_node
vm_id: 3100               # Matches Terraform vmid
vm_memory: 2048           # Matches Terraform memory
vm_cores: 2               # Matches Terraform cores
vm_storage: 20            # Matches Terraform disk.size
```

## Cross-Reference Matrix

### Resource Identification

| Component | Terraform Identifier | Ansible Identifier | Purpose |
|-----------|---------------------|-------------------|---------|
| Master Node | `vault_master` | `vault_master` group | Transit engine host |
| Production Cluster | `vault_production[*]` | `vault_production` group | Raft cluster members |
| VM Resources | `vmid = 3100-3203` | `vm_id: 3100-3203` | Proxmox VM tracking |
| Network | Static IP assignment | `ansible_host: *.tailfb3ea.ts.net` | Network connectivity |

### Configuration Dependencies

| Terraform Output | Ansible Variable | Usage |
|------------------|------------------|--------|
| VM IP addresses | `ansible_host` | SSH connectivity |
| VM specifications | `vm_*` variables | Resource validation |
| Node assignment | `proxmox_node` | Physical placement tracking |
| Network configuration | `vault_*_addr` | Service binding |

## Deployment Workflow

### Phase 1: Infrastructure Provisioning (Terraform)

```bash
# Provision VM infrastructure
cd terraform/vault-cluster
terraform plan -var-file="production.tfvars"
terraform apply -var-file="production.tfvars"
```

**Terraform Outputs:**

- VM IDs and names
- IP addresses assigned
- DNS configurations
- Storage allocations

### Phase 2: Configuration Management (Ansible)

```bash
# Configure Vault services
uv run ansible-playbook playbooks/infrastructure/vault/configure-production-nodes.yml \
  -i inventory/vault-cluster/production.yaml
```

**Ansible Inputs:**

- VM connectivity via Terraform-assigned IPs
- Host variables aligned with Terraform resources
- Service configuration using infrastructure details

## State Synchronization

### Terraform State → Ansible Inventory

Terraform state should be used to generate or validate Ansible inventory:

```bash
# Generate inventory from Terraform state
terraform output -json | jq -r '
  .vault_cluster.value[] |
  "[\(.group)]",
  "\(.name) ansible_host=\(.ip_address) vm_id=\(.vm_id)"
' > inventory/vault-cluster/terraform-generated.ini
```

### Ansible Facts → Terraform Validation

Ansible gathered facts can validate Terraform resource allocation:

```yaml
# Validate VM specifications match Terraform
- name: Validate VM resources match Terraform specification
  ansible.builtin.assert:
    that:
      - ansible_processor_vcpus == vm_cores
      - (ansible_memtotal_mb | int) >= (vm_memory - 100)  # Account for overhead
      - ansible_hostname == inventory_hostname_short
    fail_msg: "VM specification mismatch between Terraform and actual deployment"
```

## Variable Mapping Standards

### Naming Conventions

| Resource Type | Terraform Convention | Ansible Convention |
|--------------|---------------------|-------------------|
| VM Names | `vault-{role}-{index}-{node}` | Same |
| VM IDs | Sequential: 3100+ | `vm_id: {{ terraform_vmid }}` |
| IP Addresses | `192.168.10.100+` | `ansible_host: {{ terraform_ip }}` |
| Storage Paths | `/opt/vault` | `vault_data_dir: /opt/vault` |

### Environment Propagation

```yaml
# Environment variables from Terraform → Ansible
vault_datacenter: "{{ terraform_datacenter | default('doggos-cluster') }}"
vault_domain: "{{ terraform_domain | default('vault.spaceships.work') }}"
vault_cluster_name: "{{ terraform_cluster_name | default('vault-production') }}"
```

## Security Integration

### Secret Management Flow

1. **Terraform**: Provisions infrastructure without secrets
2. **Ansible**: Configures services using Infisical secrets
3. **Vault**: Generates and manages application secrets

```yaml
# NO secrets in Terraform or Ansible code
vault_transit_token: "{{ lookup('infisical.vault.read_secrets',
                           env='prod',
                           path='/apollo-13/vault',
                           secret_name='VAULT_TRANSIT_TOKEN') }}"
```

### Certificate Management

```yaml
# TLS certificates from Terraform-managed Let's Encrypt
vault_tls_cert_file: "/etc/ssl/certs/{{ terraform_cert_domain }}.crt"
vault_tls_key_file: "/etc/ssl/private/{{ terraform_cert_domain }}.key"
```

## Maintenance Procedures

### Infrastructure Updates

1. **Modify Terraform configuration**
2. **Run `terraform plan` to review changes**
3. **Apply Terraform changes**
4. **Update corresponding Ansible variables**
5. **Run Ansible playbooks to reconfigure services**

### Configuration Updates

1. **Update Ansible playbooks/variables**
2. **Test in development environment**
3. **Apply to production with rolling updates**
4. **Verify services remain healthy**

## Troubleshooting Cross-Reference

| Issue | Terraform Check | Ansible Check | Resolution |
|-------|----------------|---------------|------------|
| VM not accessible | `terraform show` VM state | `ansible all -m ping` | Check network/firewall |
| Resource mismatch | Compare tfstate to specs | Check `ansible_facts` | Recreate VM or update config |
| Service failures | VM console logs | `systemctl status vault` | Check configuration alignment |

## Integration Testing

### Validation Pipeline

```bash
#!/bin/bash
# Validate Terraform → Ansible alignment

# 1. Verify Terraform infrastructure
cd terraform/vault-cluster
terraform validate
terraform plan -detailed-exitcode

# 2. Validate Ansible inventory alignment
cd ../..
uv run ansible-inventory -i inventory/vault-cluster/production.yaml --graph

# 3. Test connectivity
uv run ansible vault_cluster -m ping -i inventory/vault-cluster/production.yaml

# 4. Validate configuration
uv run ansible-playbook playbooks/infrastructure/vault/test-connectivity.yml \
  -i inventory/vault-cluster/production.yaml --check

# 5. Check resource alignment
uv run ansible-playbook playbooks/infrastructure/vault/validate-resources.yml \
  -i inventory/vault-cluster/production.yaml
```

## Documentation Standards

### Change Management

When modifying either Terraform or Ansible configurations:

1. **Update this cross-reference document**
2. **Document variable mappings**
3. **Update deployment procedures**
4. **Test the complete workflow**
5. **Validate both layers work together**

### Version Alignment

| Component | Version Tracking |
|-----------|-----------------|
| Terraform | Git tags + state file |
| Ansible | Playbook version headers |
| Vault | `vault_version` variable |
| VMs | Cloud-init metadata |

This ensures Infrastructure and Configuration layers remain synchronized and maintainable.

---

**Last Updated**: August 25, 2025
**Document Owner**: Infrastructure Team
**Review Schedule**: On any Terraform or Ansible changes affecting Vault cluster
