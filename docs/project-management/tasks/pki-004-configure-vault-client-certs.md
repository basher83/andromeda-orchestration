# Task: Configure Vault Client Certificate Authentication

**Task ID**: PKI-004
**Parent Issue**: #98 (mTLS for Service Communication)
**Priority**: P1 - High
**Estimated Time**: 2 hours
**Dependencies**: PKI-001

## Objective

Enable client certificate authentication for Vault API access, allowing services to authenticate using mTLS certificates instead of tokens.

## Prerequisites

- [ ] PKI roles created (PKI-001)
- [ ] Vault cluster running with TLS enabled
- [ ] CA certificates deployed to Vault nodes

## Implementation Steps

1. **Update Vault Listener Configuration**

   ```yaml
   - name: Configure Vault for client certificate authentication
     ansible.builtin.blockinfile:
       path: /etc/vault.d/vault.hcl
       marker: "# {mark} ANSIBLE MANAGED CLIENT CERT CONFIG"
       insertafter: 'listener "tcp"'
       block: |
         listener "tcp" {
           address = "0.0.0.0:8200"
           tls_cert_file = "/opt/vault/tls/vault.crt"
           tls_key_file = "/opt/vault/tls/vault.key"

           # Client certificate settings
           tls_client_ca_file = "/opt/vault/tls/ca.crt"
           tls_require_and_verify_client_cert = false  # Soft enforcement

           # TLS parameters
           tls_min_version = "tls12"
           tls_cipher_suites = [
             "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
             "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
           ]
         }
   ```

2. **Enable Certificate Auth Method**

   ```yaml
   - name: Enable cert auth method in Vault
     community.hashi_vault.vault_auth_method:
       method_type: cert
       mount_point: cert
       state: enabled

   - name: Configure certificate auth method
     community.hashi_vault.vault_write:
       path: auth/cert/config
       data:
         disable_binding: false
         max_lease_ttl: "768h"
         default_lease_ttl: "168h"
   ```

3. **Create Certificate Auth Roles**

   ```yaml
   - name: Create Consul service cert auth role
     community.hashi_vault.vault_write:
       path: auth/cert/certs/consul
       data:
         display_name: "consul"
         policies: "consul-agent"
         certificate: "{{ consul_ca_cert.data.data }}"
         allowed_common_names:
           - "*.consul.spaceships.work"
           - "consul.service.consul"
         required_extensions: "ext:1.3.6.1.4.1.41482.2.1"
         ttl: "720h"

   - name: Create Nomad service cert auth role
     community.hashi_vault.vault_write:
       path: auth/cert/certs/nomad
       data:
         display_name: "nomad"
         policies: "nomad-server"
         certificate: "{{ consul_ca_cert.data.data }}"
         allowed_common_names:
           - "*.nomad.spaceships.work"
           - "server.global.nomad"
         ttl: "720h"
   ```

4. **Create Service Policies**

   ```yaml
   - name: Create Consul agent policy
     community.hashi_vault.vault_write:
       path: sys/policies/acl/consul-agent
       data:
         policy: |
           # Consul agent policy
           path "secret/data/consul/*" {
             capabilities = ["read", "list"]
           }
           path "pki-int/issue/consul-agent" {
             capabilities = ["create", "update"]
           }

   - name: Create Nomad server policy
     community.hashi_vault.vault_write:
       path: sys/policies/acl/nomad-server
       data:
         policy: |
           # Nomad server policy
           path "secret/data/nomad/*" {
             capabilities = ["read", "list"]
           }
           path "pki-int/issue/nomad-agent" {
             capabilities = ["create", "update"]
           }
   ```

5. **Test Client Certificate Authentication**

   ```yaml
   - name: Test cert auth with client certificate
     ansible.builtin.uri:
       url: "https://{{ vault_addr }}/v1/auth/cert/login"
       method: POST
       client_cert: /opt/consul/tls/consul.crt
       client_key: /opt/consul/tls/consul.key
       validate_certs: yes
       ca_path: /opt/vault/tls/ca.crt
       body_format: json
       body:
         name: "consul"
     register: cert_auth_response

   - name: Verify authentication succeeded
     ansible.builtin.assert:
       that:
         - cert_auth_response.status == 200
         - cert_auth_response.json.auth.client_token is defined
   ```

## Success Criteria

- [ ] Certificate auth method enabled and configured
- [ ] Service-specific auth roles created
- [ ] Client certificates can authenticate to Vault
- [ ] Appropriate policies attached to cert auth roles
- [ ] Token auth still works (backward compatibility)

## Validation

```bash
# List auth methods
vault auth list

# Test certificate authentication
vault login -method=cert \
  -ca-cert=/opt/vault/tls/ca.crt \
  -client-cert=/opt/consul/tls/consul.crt \
  -client-key=/opt/consul/tls/consul.key \
  name=consul

# Verify policies attached
vault token lookup

# Test API access with client cert
curl --cert /opt/consul/tls/consul.crt \
     --key /opt/consul/tls/consul.key \
     --cacert /opt/vault/tls/ca.crt \
     https://vault.service.consul:8200/v1/sys/health
```

## Notes

- Starting with `tls_require_and_verify_client_cert: false` for compatibility
- Will enable mandatory client certs in PKI-006
- Certificate auth supplements token auth, doesn't replace it
- Services can gradually migrate from tokens to certificates
