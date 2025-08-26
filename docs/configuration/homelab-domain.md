# Homelab Domain Configuration

## Overview

This project uses a configurable `homelab_domain` variable to avoid hardcoding domain names. The default domain is `spaceships.work`, replacing the legacy `.local` domains that conflict with mDNS on macOS systems.

## Configuration Locations

### Global Configuration

- **Inventory Group Variables**:
  - `inventory/doggos-homelab/group_vars/all/main.yml`
  - `inventory/og-homelab/group_vars/all/main.yml`

### Role Defaults

- **Consul DNS Role**: `roles/consul_dns/defaults/main.yml`
- **Nomad Role**: `roles/nomad/defaults/main.yml`

### Nomad Jobs

All Nomad jobs support the `homelab_domain` variable through HCL2:

```hcl
variable "homelab_domain" {
  type        = string
  default     = "spaceships.work"
  description = "The domain for the homelab environment"
}
```

## Usage Examples

### In Ansible Playbooks

```yaml
- name: Configure service DNS
  set_fact:
    service_fqdn: "{{ service_name }}.{{ homelab_domain }}"
```

### In Nomad Jobs

```hcl
tags = [
  "traefik.enable=true",
  "traefik.http.routers.api.rule=Host(`traefik.${var.homelab_domain}`)"
]
```

### In Templates

```jinja2
server {
    server_name {{ app_name }}.{{ homelab_domain }};
}
```

## Migration from .local

The project previously used `.lab.local` and `.homelab.local` domains, which caused issues with:

- macOS mDNS (Bonjour) resolution
- Docker container DNS resolution
- General network conflicts with local multicast DNS

All active code has been migrated to use the `homelab_domain` variable. A linting rule prevents future `.local` usage:

- Pre-commit hook: Automatically checks for `.local` domains
- Manual check: `mise run lint:domains` or `./scripts/lint-no-dot-local.sh`

## Changing the Domain

To use a different domain:

1. Update inventory group variables:

   ```yaml
   homelab_domain: "your-domain.example"
   ```

2. For Nomad jobs, pass the variable during deployment:

   ```bash
   nomad job run -var="homelab_domain=your-domain.example" job.nomad.hcl
   ```

## DNS Configuration

Ensure your DNS server (PowerDNS, Pi-hole, etc.) is configured with zones for your chosen domain. Services will automatically register with the configured domain through Consul service discovery.
