---
Task: Enable mTLS Hard Enforcement
Task ID: PKI-006
Parent Issue: 98 - mTLS for Service Communication
Priority: P0 - Critical
Estimated Time: 3 hours
Dependencies: PKI-005 (48+ hours in soft enforcement)
Status: Ready
---

## Objective

Create an Ansible playbook that enables strict mTLS verification across all HashiCorp services, rejecting any connections without valid client certificates. This includes configuration validation and service health verification.

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/enable-mtls-hard-enforcement.yml
- Create: playbooks/infrastructure/vault/validate-mtls-hard-enforcement.yml
- Modify: Service configuration files (/etc/consul.d/tls.hcl, /etc/nomad.d/nomad.hcl, /etc/vault.d/vault.hcl)

## Reference Implementations

- Pattern example: playbooks/infrastructure/vault/deploy-tls-certificates.yml
- Validation pattern: playbooks/infrastructure/vault/smoke-test.yml
- Similar task: PKI-005 (soft enforcement implementation)

## Execution Environment

- Target cluster: doggos-homelab (for Nomad/Consul services)
- Inventory: inventory/environments/doggos-homelab/proxmox.yml
- Required secrets (via Infisical):
  - CONSUL_MASTER_TOKEN (path: /apollo-13/consul)
  - VAULT_PROD_ROOT_TOKEN (path: /apollo-13/vault)
- Service addresses: Defined in inventory group_vars

## Dependencies

- PKI-005: Created soft enforcement configuration with logging that this task needs to analyze for non-TLS connections
- Existing: Certificate files deployed to all services at /opt/*/tls/
- Existing: Service configuration directories and permissions set up correctly

## Prerequisites

- [ ] Soft enforcement running for minimum 48 hours
- [ ] No critical non-TLS clients identified in logs
- [ ] All service clients updated with certificates
- [ ] Backup/rollback plan prepared

## Implementation Steps

1. **Pre-Flight Validation**

   ```yaml
   - name: Check for non-TLS connections in last 24 hours
     ansible.builtin.shell: |
       grep "connection without TLS" /var/log/tls-violations.log | \
       awk -v date="$(date -d '24 hours ago' '+%Y-%m-%d %H:%M')" '$1" "$2 >= date' | wc -l
     register: non_tls_count

   - name: Abort if non-TLS connections detected
     ansible.builtin.fail:
       msg: "Found {{ non_tls_count.stdout }} non-TLS connections in last 24 hours. Resolve before enabling hard enforcement."
     when: non_tls_count.stdout | int > 0
   ```

2. **Enable Hard Enforcement on Consul**

   ```yaml
   - name: Enable Consul strict mTLS
     ansible.builtin.replace:
       path: /etc/consul.d/tls.hcl
       regexp: 'verify_incoming\s*=\s*false'
       replace: "verify_incoming = true"

   - name: Update Consul intention defaults
     community.general.consul_intention:
       service_src: "*"
       service_dest: "*"
       action: deny
       state: present

   - name: Create specific service intentions
     community.general.consul_intention:
       service_src: "{{ item.src }}"
       service_dest: "{{ item.dest }}"
       action: allow
       state: present
     loop:
       - { src: "nomad", dest: "consul" }
       - { src: "vault", dest: "consul" }
       - { src: "traefik", dest: "*" }
   ```

3. **Enable Hard Enforcement on Nomad**

   ```yaml
   - name: Enable Nomad strict mTLS
     ansible.builtin.replace:
       path: /etc/nomad.d/nomad.hcl
       regexp: 'verify_https_client\s*=\s*false'
       replace: "verify_https_client = true"

   - name: Update Nomad ACL default policy
     ansible.builtin.copy:
       dest: /etc/nomad.d/acl.hcl
       content: |
         acl {
           enabled = true
           token_ttl = "30s"
           policy_ttl = "60s"

           # Require TLS for all API requests
           require_tls = true
         }
   ```

4. **Enable Hard Enforcement on Vault**

   ```yaml
   - name: Enable Vault strict mTLS
     ansible.builtin.replace:
       path: /etc/vault.d/vault.hcl
       regexp: 'tls_require_and_verify_client_cert\s*=\s*false'
       replace: "tls_require_and_verify_client_cert = true"
   ```

5. **Staged Rollout**

   ```yaml
   - name: Enable hard enforcement on test node first
     include_tasks: enable_hard_enforcement.yml
     when: inventory_hostname == groups['test_nodes'][0]

   - name: Validate test node
     ansible.builtin.uri:
       url: "https://{{ hostvars[groups['test_nodes'][0]].ansible_default_ipv4.address }}:8500/v1/status/leader"
       client_cert: /opt/consul/tls/consul.crt
       client_key: /opt/consul/tls/consul.key
       validate_certs: yes
     delegate_to: "{{ groups['test_nodes'][0] }}"

   - name: Pause for manual validation
     ansible.builtin.pause:
       prompt: "Test node configured. Verify services working correctly. Press Enter to continue rollout..."

   - name: Enable on remaining nodes
     include_tasks: enable_hard_enforcement.yml
     throttle: 1
     when: inventory_hostname != groups['test_nodes'][0]
   ```

6. **Post-Enforcement Validation**

   ```yaml
   - name: Test that non-TLS connections are rejected
     ansible.builtin.uri:
       url: "http://{{ ansible_default_ipv4.address }}:8500/v1/status/leader"
     register: non_tls_test
     failed_when: false

   - name: Verify non-TLS rejected
     ansible.builtin.assert:
       that:
         - non_tls_test.status == -1 or non_tls_test.status >= 400
       fail_msg: "Non-TLS connections still accepted!"

   - name: Test that TLS connections work
     ansible.builtin.uri:
       url: "https://{{ ansible_default_ipv4.address }}:8501/v1/status/leader"
       client_cert: /opt/consul/tls/consul.crt
       client_key: /opt/consul/tls/consul.key
       validate_certs: yes
     register: tls_test

   - name: Verify TLS accepted
     ansible.builtin.assert:
       that:
         - tls_test.status == 200
   ```

## Success Criteria

- [ ] All services reject non-TLS connections
- [ ] All services accept valid mTLS connections
- [ ] Service mesh communication fully encrypted
- [ ] No service disruptions during rollout
- [ ] Monitoring confirms 100% TLS usage
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/enable-mtls-hard-enforcement.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/enable-mtls-hard-enforcement.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-mtls-hard-enforcement.yml
```

Validation playbook content:

```yaml
---
- name: Validate mTLS Hard Enforcement
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Test rejection of non-TLS connection to Consul
      ansible.builtin.uri:
        url: "http://consul.service.consul:8500/v1/status/leader"
        method: GET
      register: non_tls_test
      changed_when: false
      failed_when: false

    - name: Test acceptance of mTLS connection to Consul
      ansible.builtin.uri:
        url: "https://consul.service.consul:8501/v1/status/leader"
        client_cert: /opt/consul/tls/consul.crt
        client_key: /opt/consul/tls/consul.key
        ca_path: /opt/consul/tls/ca.crt
        validate_certs: yes
      register: tls_test
      changed_when: false

    - name: Test mTLS connection to Nomad
      ansible.builtin.uri:
        url: "https://nomad.service.consul:4647/v1/status/leader"
        client_cert: /opt/nomad/tls/nomad.crt
        client_key: /opt/nomad/tls/nomad.key
        ca_path: /opt/nomad/tls/ca.crt
        validate_certs: yes
      register: nomad_tls_test
      changed_when: false

    - name: Test mTLS connection to Vault
      ansible.builtin.uri:
        url: "https://vault.service.consul:8200/v1/sys/health"
        client_cert: /opt/vault/tls/vault.crt
        client_key: /opt/vault/tls/vault.key
        ca_path: /opt/vault/tls/ca.crt
        validate_certs: yes
      register: vault_tls_test
      changed_when: false

    - name: Check established encrypted connections
      ansible.builtin.command: netstat -tn
      register: established_connections
      changed_when: false

    - name: Filter encrypted service connections
      ansible.builtin.set_fact:
        encrypted_connections: "{{ established_connections.stdout_lines | select('match', '.*ESTABLISHED.*:(8200|8501|4647)') | list }}"

    - name: Display validation results
      ansible.builtin.debug:
        msg: |
          Non-TLS Connection Status: {{ 'REJECTED' if non_tls_test.status != 200 else 'UNEXPECTEDLY ALLOWED' }}
          Consul mTLS Status: {{ 'SUCCESS' if tls_test.status == 200 else 'FAILED' }}
          Nomad mTLS Status: {{ 'SUCCESS' if nomad_tls_test.status == 200 else 'FAILED' }}
          Vault mTLS Status: {{ 'SUCCESS' if vault_tls_test.status == 200 else 'FAILED' }}
          Encrypted Connections: {{ encrypted_connections | length }}

    - name: Verify hard enforcement is working
      ansible.builtin.assert:
        that:
          - non_tls_test.status != 200  # Non-TLS should be rejected
          - tls_test.status == 200      # mTLS should work
          - nomad_tls_test.status == 200
          - vault_tls_test.status == 200
        fail_msg: "mTLS hard enforcement validation failed"
        success_msg: "mTLS hard enforcement is working correctly"

    - name: Log validation completion
      ansible.builtin.debug:
        msg: "mTLS hard enforcement validation completed successfully"
```

## Rollback Plan

If issues occur:

```bash
# Quick rollback script
for service in consul nomad vault; do
  sed -i 's/verify_.*= true/verify_incoming = false/' /etc/$service.d/*.hcl
  systemctl reload $service
done
```

## Notes

- Test on single node first before full rollout
- Monitor service logs closely during rollout
- Keep rollback script ready
- Document any services requiring exceptions
