# Task: Enable mTLS Hard Enforcement

**Task ID**: PKI-006
**Parent Issue**: #98 (mTLS for Service Communication)
**Priority**: P0 - Critical
**Estimated Time**: 3 hours
**Dependencies**: PKI-005 (48+ hours in soft enforcement)

## Objective

Enable strict mTLS verification across all HashiCorp services, rejecting any connections without valid client certificates.

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
       replace: 'verify_incoming = true'

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
       replace: 'verify_https_client = true'

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
       replace: 'tls_require_and_verify_client_cert = true'
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

## Validation

```bash
# Test rejection of non-TLS
curl -v http://consul.service.consul:8500/v1/status/leader
# Expected: Connection refused or TLS required error

# Test acceptance of mTLS
curl --cert client.crt --key client.key \
     --cacert ca.crt \
     https://consul.service.consul:8501/v1/status/leader
# Expected: Success

# Verify all connections encrypted
netstat -tn | grep ESTABLISHED | grep -E ":(8200|8501|4647)"
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
