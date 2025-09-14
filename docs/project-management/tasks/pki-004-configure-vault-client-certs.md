---
Task: Configure Vault Client Certificate Authentication
Task ID: PKI-004
Parent Issue: 98 - mTLS for Service Communication
Priority: P1 - High
Estimated Time: 2 hours
Dependencies: PKI-001, PKI-003
Status: Ready
---

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

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-vault-client-certs.yml
```

The validation playbook performs the following checks:

```yaml
- name: Validate Vault Client Certificate Authentication
  hosts: vault_servers
  tasks:
    - name: List enabled auth methods
      community.hashi_vault.vault_list:
        path: sys/auth
      register: auth_methods

    - name: Assert cert auth method is enabled
      ansible.builtin.assert:
        that:
          - "'cert/' in auth_methods.data.data"
        fail_msg: "Certificate auth method not enabled in Vault"

    - name: Test certificate authentication for Consul
      ansible.builtin.uri:
        url: "https://{{ ansible_default_ipv4.address }}:8200/v1/auth/cert/login"
        method: POST
        client_cert: /opt/consul/tls/consul.crt
        client_key: /opt/consul/tls/consul.key
        validate_certs: yes
        ca_path: /opt/vault/tls/ca.crt
        body_format: json
        body:
          name: "consul"
      register: consul_cert_auth
      when: inventory_hostname in groups['consul_servers'] or inventory_hostname in groups['consul_clients']

    - name: Assert Consul certificate authentication succeeded
      ansible.builtin.assert:
        that:
          - consul_cert_auth.status == 200
          - consul_cert_auth.json.auth.client_token is defined
          - consul_cert_auth.json.auth.policies is defined
        fail_msg: "Consul certificate authentication failed"
      when: consul_cert_auth is defined

    - name: Test certificate authentication for Nomad
      ansible.builtin.uri:
        url: "https://{{ ansible_default_ipv4.address }}:8200/v1/auth/cert/login"
        method: POST
        client_cert: /opt/nomad/tls/nomad.crt
        client_key: /opt/nomad/tls/nomad.key
        validate_certs: yes
        ca_path: /opt/vault/tls/ca.crt
        body_format: json
        body:
          name: "nomad"
      register: nomad_cert_auth
      when: inventory_hostname in groups['nomad_servers'] or inventory_hostname in groups['nomad_clients']

    - name: Assert Nomad certificate authentication succeeded
      ansible.builtin.assert:
        that:
          - nomad_cert_auth.status == 200
          - nomad_cert_auth.json.auth.client_token is defined
          - nomad_cert_auth.json.auth.policies is defined
        fail_msg: "Nomad certificate authentication failed"
      when: nomad_cert_auth is defined

    - name: Verify token properties for Consul auth
      community.hashi_vault.vault_token_lookup:
        token: "{{ consul_cert_auth.json.auth.client_token }}"
      register: consul_token_info
      when: consul_cert_auth is defined and consul_cert_auth.json.auth.client_token is defined

    - name: Assert Consul token has correct policies
      ansible.builtin.assert:
        that:
          - "'consul-agent' in consul_token_info.data.data.policies"
        fail_msg: "Consul token does not have correct policies attached"
      when: consul_token_info is defined

    - name: Verify token properties for Nomad auth
      community.hashi_vault.vault_token_lookup:
        token: "{{ nomad_cert_auth.json.auth.client_token }}"
      register: nomad_token_info
      when: nomad_cert_auth is defined and nomad_cert_auth.json.auth.client_token is defined

    - name: Assert Nomad token has correct policies
      ansible.builtin.assert:
        that:
          - "'nomad-server' in nomad_token_info.data.data.policies"
        fail_msg: "Nomad token does not have correct policies attached"
      when: nomad_token_info is defined

    - name: Test API access with client certificate
      ansible.builtin.uri:
        url: "https://{{ ansible_default_ipv4.address }}:8200/v1/sys/health"
        client_cert: /opt/consul/tls/consul.crt
        client_key: /opt/consul/tls/consul.key
        validate_certs: yes
        ca_path: /opt/vault/tls/ca.crt
      register: api_health_check
      when: inventory_hostname in groups['consul_servers'] or inventory_hostname in groups['consul_clients']

    - name: Assert API responds with client certificate
      ansible.builtin.assert:
        that:
          - api_health_check.status == 200
          - api_health_check.json.initialized == true
        fail_msg: "Vault API not accessible with client certificates"
      when: api_health_check is defined

    - name: Verify backward compatibility with token auth still works
      ansible.builtin.uri:
        url: "https://{{ ansible_default_ipv4.address }}:8200/v1/sys/health"
        validate_certs: yes
        ca_path: /opt/vault/tls/ca.crt
        headers:
          X-Vault-Token: "{{ vault_token }}"
      register: token_health_check
      when: vault_token is defined

    - name: Assert token authentication still works
      ansible.builtin.assert:
        that:
          - token_health_check.status == 200
        fail_msg: "Token authentication compatibility broken"
      when: token_health_check is defined
```

Expected output:

- Certificate auth method enabled and accessible
- Consul and Nomad services can authenticate using their certificates
- Authentication tokens contain correct policies (consul-agent, nomad-server)
- API endpoints respond correctly with client certificate authentication
- Backward compatibility maintained with existing token authentication
- All certificate-based authentication requests return valid tokens with appropriate TTLs

## Notes

- Starting with `tls_require_and_verify_client_cert: false` for compatibility
- Will enable mandatory client certs in PKI-006
- Certificate auth supplements token auth, doesn't replace it
- Services can gradually migrate from tokens to certificates
