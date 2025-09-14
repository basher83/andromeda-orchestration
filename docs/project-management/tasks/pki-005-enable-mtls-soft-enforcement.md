---
Task: Enable mTLS Soft Enforcement
Task ID: PKI-005
Parent Issue: 98 - mTLS for Service Communication
Priority: P0 - Critical
Estimated Time: 2 hours
Dependencies: PKI-002, PKI-003, PKI-004
Status: Ready
---

## Objective

Create an Ansible playbook that enables mTLS in permissive mode across all HashiCorp services to validate certificate configuration without disrupting existing connections.

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/enable-mtls-soft-enforcement.yml
- Create: playbooks/infrastructure/vault/validate-mtls-soft-enforcement.yml
- Modify: Consul, Nomad, and Vault configuration files for soft enforcement settings
- Create: /usr/local/bin/validate-mtls.sh validation script
- Create: /etc/rsyslog.d/tls-monitor.conf and /etc/logrotate.d/tls-logs

## Reference Implementations

- Pattern example: playbooks/infrastructure/vault/configure-production-nodes.yml
- Validation pattern: playbooks/infrastructure/vault/smoke-test.yml
- Configuration modification: Similar replace patterns in existing playbooks

## Execution Environment

- Target cluster: doggos-homelab (for service configuration), vault-cluster (for PKI)
- Inventory: inventory/environments/doggos-homelab/proxmox.yml (primary)
- Required secrets (via Infisical):
  - CONSUL_MASTER_TOKEN (path: /apollo-13/consul)
  - VAULT_PROD_ROOT_TOKEN (path: /apollo-13/vault)
- Service addresses: Defined in inventory group_vars

## Dependencies

- PKI-002: Consul auto-encrypt configured (TLS certificates deployed)
- PKI-003: Nomad TLS configured (TLS certificates and environment configured)
- PKI-004: Vault client certs configured (Certificate authentication enabled)
- All services must have TLS certificates deployed and functional

## Prerequisites

- [ ] All services have TLS certificates deployed
- [ ] Consul auto-encrypt configured (PKI-002)
- [ ] Nomad TLS configured (PKI-003)
- [ ] Vault client certs configured (PKI-004)

## Implementation Steps

1. **Enable Soft Enforcement on Consul**

   ```yaml
   - name: Enable Consul soft mTLS enforcement
     ansible.builtin.lineinfile:
       path: /etc/consul.d/tls.hcl
       regexp: "^\\s*verify_incoming\\s*="
       line: "  verify_incoming = false  # Soft enforcement"
     notify: reload consul

   - name: Enable intention defaults for gradual migration
     community.general.consul_intention:
       service_src: "*"
       service_dest: "*"
       action: allow
       state: present
   ```

2. **Enable Soft Enforcement on Nomad**

   ```yaml
   - name: Configure Nomad soft mTLS enforcement
     ansible.builtin.replace:
       path: /etc/nomad.d/nomad.hcl
       regexp: 'verify_https_client\s*=\s*true'
       replace: "verify_https_client = false  # Soft enforcement"
     notify: reload nomad
   ```

3. **Enable Soft Enforcement on Vault**

   ```yaml
   - name: Configure Vault soft mTLS enforcement
     ansible.builtin.replace:
       path: /etc/vault.d/vault.hcl
       regexp: 'tls_require_and_verify_client_cert\s*=\s*true'
       replace: "tls_require_and_verify_client_cert = false  # Soft enforcement"
     notify: reload vault
   ```

4. **Configure Monitoring for Non-TLS Connections**

   ```yaml
   - name: Enable TLS connection logging
     ansible.builtin.blockinfile:
       path: /etc/rsyslog.d/tls-monitor.conf
       create: yes
       block: |
         # Log non-TLS connection attempts
         :msg, contains, "connection without TLS" /var/log/tls-violations.log
         :msg, contains, "TLS handshake error" /var/log/tls-errors.log
         & stop

   - name: Create log rotation for TLS logs
     ansible.builtin.copy:
       dest: /etc/logrotate.d/tls-logs
       content: |
         /var/log/tls-*.log {
           daily
           rotate 7
           compress
           missingok
           notifempty
         }
   ```

5. **Deploy Validation Script**

   ```yaml
   - name: Deploy mTLS validation script
     ansible.builtin.copy:
       dest: /usr/local/bin/validate-mtls.sh
       mode: "0755"
       content: |
         #!/bin/bash
         echo "=== mTLS Soft Enforcement Validation ==="

         # Check Consul
         echo "Consul TLS Status:"
         consul info | grep -E "(encrypted|verify)"

         # Check Nomad
         echo "Nomad TLS Status:"
         nomad agent-info | grep -E "(tls|verify)"

         # Check Vault
         echo "Vault TLS Status:"
         vault status -format=json | jq '.tls_enabled'

         # Check for non-TLS connections
         echo "Non-TLS connection attempts (last 100):"
         tail -100 /var/log/tls-violations.log 2>/dev/null | wc -l

   - name: Run validation
     ansible.builtin.command: /usr/local/bin/validate-mtls.sh
     register: validation_output

   - name: Display validation results
     ansible.builtin.debug:
       var: validation_output.stdout_lines
   ```

## Success Criteria

- [ ] All services accept both TLS and non-TLS connections
- [ ] TLS connections are logged and preferred
- [ ] No service disruptions occur
- [ ] Monitoring captures non-TLS connection attempts
- [ ] Validation script confirms soft enforcement active
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/enable-mtls-soft-enforcement.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/enable-mtls-soft-enforcement.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-mtls-soft-enforcement.yml
```

Validation playbook content:

```yaml
---
- name: Validate mTLS Soft Enforcement
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Test TLS connection to Consul
      ansible.builtin.uri:
        url: "https://consul.service.consul:8501/v1/status/leader"
        client_cert: /opt/consul/tls/consul.crt
        client_key: /opt/consul/tls/consul.key
        validate_certs: yes
      register: tls_connection
      changed_when: false

    - name: Test non-TLS connection to Consul (should work in soft mode)
      ansible.builtin.uri:
        url: "http://consul.service.consul:8500/v1/status/leader"
        method: GET
      register: non_tls_connection
      changed_when: false
      failed_when: false

    - name: Check for non-TLS connection attempts in logs
      ansible.builtin.command: grep "connection without TLS" /var/log/tls-violations.log
      register: non_tls_attempts
      changed_when: false
      failed_when: false

    - name: Monitor active TLS connections
      ansible.builtin.command: ss -tln
      register: active_connections
      changed_when: false

    - name: Filter HashiCorp service connections
      ansible.builtin.set_fact:
        service_connections: "{{ active_connections.stdout_lines | select('match', '.*:(8200|8300|8301|8500|8501|4646|4647|4648)') | list }}"

    - name: Display validation results
      ansible.builtin.debug:
        msg: |
          TLS Connection Status: {{ 'SUCCESS' if tls_connection.status == 200 else 'FAILED' }}
          Non-TLS Connection Status: {{ 'ALLOWED' if non_tls_connection.status == 200 else 'BLOCKED' }}
          Non-TLS Attempts Found: {{ non_tls_attempts.stdout_lines | length }}
          Active Service Connections: {{ service_connections | length }}

    - name: Verify soft enforcement is working
      ansible.builtin.assert:
        that:
          - tls_connection.status == 200
          - non_tls_connection.status == 200  # Should work in soft mode
        fail_msg: "mTLS soft enforcement validation failed"
        success_msg: "mTLS soft enforcement is working correctly"
```

## Monitoring Period

Run in soft enforcement for **48 hours** minimum to:

- Identify all clients not using TLS
- Update client configurations as needed
- Validate no critical services affected
- Build confidence before hard enforcement

## Notes

- Soft enforcement allows gradual migration
- Monitor logs to identify services needing updates
- Document all non-TLS clients for remediation
- Prepare rollback plan before proceeding to hard enforcement
