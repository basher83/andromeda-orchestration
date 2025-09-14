---
Task: Create Service PKI Roles
Task ID: PKI-001
Parent Issue: 98 - mTLS for Service Communication
Priority: P0 - Critical
Estimated Time: 2 hours
Dependencies: None
Status: Ready
---

## Objective

Create an Ansible playbook that configures dedicated PKI roles in Vault for each HashiCorp service (Consul, Nomad, Vault) to enable secure certificate issuance with appropriate constraints and parameters.

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/create-service-pki-roles.yml
- Create: playbooks/infrastructure/vault/validate-pki-roles.yml

## Reference Implementations

- Pattern example: playbooks/infrastructure/vault/setup-pki-intermediate-ca.yml
- Validation pattern: playbooks/infrastructure/vault/smoke-test.yml
- Similar configuration: PKI role creation in setup-pki-intermediate-ca.yml (lines 218-244)

## Dependencies

- Root CA and Intermediate CA must be configured in Vault
- PKI engines must be enabled and operational
- Vault admin access and authentication configured

## Prerequisites

- [ ] Vault PKI engine configured (Root CA and Intermediate CA)
- [ ] Vault admin access available
- [ ] Service inventory documented (hostnames, IP addresses)

## Implementation Steps

1. **Create Consul Agent PKI Role**

   ```yaml
   - name: Create Consul agent certificate role
     community.hashi_vault.vault_write:
       path: pki-int/roles/consul-agent
       data:
         allowed_domains:
           - "consul.service.consul"
           - "consul.spaceships.work"
         allow_subdomains: true
         allow_bare_domains: true
         allow_localhost: true
         client_flag: true
         server_flag: true
         max_ttl: "8760h"
         ttl: "720h"
   ```

2. **Create Nomad Agent PKI Role**

   ```yaml
   - name: Create Nomad agent certificate role
     community.hashi_vault.vault_write:
       path: pki-int/roles/nomad-agent
       data:
         allowed_domains:
           - "nomad.service.consul"
           - "nomad.spaceships.work"
         allow_subdomains: true
         allow_bare_domains: true
         allow_localhost: true
         client_flag: true
         server_flag: true
         max_ttl: "8760h"
         ttl: "720h"
   ```

3. **Create Vault Agent PKI Role**

   ```yaml
   - name: Create Vault agent certificate role
     community.hashi_vault.vault_write:
       path: pki-int/roles/vault-agent
       data:
         allowed_domains:
           - "vault.service.consul"
           - "vault.spaceships.work"
         allow_subdomains: true
         allow_bare_domains: true
         allow_localhost: true
         client_flag: true
         server_flag: true
         max_ttl: "8760h"
         ttl: "720h"
   ```

4. **Create Client Authentication Role**

   ```yaml
   - name: Create client authentication role
     community.hashi_vault.vault_write:
       path: pki-int/roles/client-auth
       data:
         allowed_domains:
           - "client.spaceships.work"
         allow_subdomains: true
         client_flag: true
         server_flag: false
         max_ttl: "168h" # 7 days for clients
         ttl: "168h"
   ```

## Success Criteria

- [ ] All PKI roles created and accessible via Vault API
- [ ] Test certificate generation from each role succeeds
- [ ] Certificate parameters match service requirements
- [ ] Roles enforce proper domain constraints
- [ ] TTL values align with rotation strategy
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/create-service-pki-roles.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/create-service-pki-roles.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-pki-roles.yml
```

Expected output:

- Each role returns valid configuration when queried
- Test certificate generation succeeds for each role
- Certificate contains correct SANs and flags

## Notes

- TTL set to 30 days (720h) for services, 7 days (168h) for clients
- Max TTL set to 1 year (8760h) to prevent excessively long certificates
- Both client and server flags enabled for service certificates to support mTLS
