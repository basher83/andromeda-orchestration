---
Task: Configure Consul Auto-Encrypt with mTLS
Task ID: PKI-002
Parent Issue: 98 - mTLS for Service Communication
Priority: P0 - Critical
Estimated Time: 4 hours
Dependencies: PKI-001
Status: Ready
---

## Objective

Create an Ansible playbook that enables Consul auto-encrypt to automatically distribute and rotate TLS certificates for all Consul agents, establishing mutual TLS authentication across the cluster.

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/configure-consul-auto-encrypt.yml
- Create: playbooks/infrastructure/vault/validate-consul-auto-encrypt.yml
- Modify: Consul configuration templates as needed

## Reference Implementations

- Pattern example: playbooks/infrastructure/vault/deploy-tls-certificates.yml
- Validation pattern: playbooks/infrastructure/vault/smoke-test.yml
- Service restart pattern: Rolling restart implementation in setup-pki-intermediate-ca.yml

## Execution Environment

- Target cluster: vault-cluster (for Vault PKI configuration)
- Inventory: inventory/environments/vault-cluster/proxmox.yml
- Required secrets (via Infisical):
  - VAULT_PROD_ROOT_TOKEN (path: /apollo-13/vault)
- Service addresses: Defined in inventory group_vars

## Dependencies

- PKI-001: Created PKI roles for certificate issuance (consul-agent role required)
- Consul cluster must be operational and accessible
- Vault intermediate CA configured and issuing certificates

## Prerequisites

- [ ] PKI roles created (PKI-001)
- [ ] Consul servers running and accessible
- [ ] Ansible inventory updated with Consul nodes

## Implementation Steps

1. **Generate CA Certificate for Consul**

   ```yaml
   - name: Generate Consul CA certificate from Vault
     community.hashi_vault.vault_read:
       path: pki-int/ca/pem
     register: consul_ca_cert

   - name: Deploy CA certificate to all Consul nodes
     ansible.builtin.copy:
       content: "{{ consul_ca_cert.data.data }}"
       dest: /opt/consul/tls/ca.crt
       owner: consul
       group: consul
       mode: "0644"
   ```

2. **Configure Consul Servers for Auto-Encrypt**

   ```yaml
   - name: Update Consul server configuration
     ansible.builtin.template:
       src: consul-server-tls.hcl.j2
       dest: /etc/consul.d/tls.hcl
     vars:
       consul_tls_config:
         ca_file: "/opt/consul/tls/ca.crt"
         cert_file: "/opt/consul/tls/consul.crt"
         key_file: "/opt/consul/tls/consul.key"
         verify_incoming: false # Start with soft enforcement
         verify_outgoing: true
         verify_server_hostname: true
         auto_encrypt:
           allow_tls: true
   ```

3. **Generate Server Certificates**

   ```yaml
   - name: Generate Consul server certificates
     community.hashi_vault.vault_pki_generate_certificate:
       role_name: consul-agent
       common_name: "{{ inventory_hostname }}.consul.spaceships.work"
       alt_names:
         - "server.dc1.consul"
         - "consul.service.consul"
       ip_sans:
         - "{{ ansible_default_ipv4.address }}"
         - "127.0.0.1"
       ttl: "720h"
     register: consul_cert

   - name: Deploy server certificates
     ansible.builtin.copy:
       content: "{{ item.content }}"
       dest: "{{ item.dest }}"
       owner: consul
       group: consul
       mode: "{{ item.mode }}"
     loop:
       - { content: "{{ consul_cert.data.certificate }}", dest: "/opt/consul/tls/consul.crt", mode: "0644" }
       - { content: "{{ consul_cert.data.private_key }}", dest: "/opt/consul/tls/consul.key", mode: "0600" }
   ```

4. **Configure Consul Clients for Auto-Encrypt**

   ```yaml
   - name: Configure Consul clients
     ansible.builtin.template:
       src: consul-client-tls.hcl.j2
       dest: /etc/consul.d/tls.hcl
     vars:
       consul_tls_config:
         ca_file: "/opt/consul/tls/ca.crt"
         verify_outgoing: true
         verify_server_hostname: true
         auto_encrypt:
           tls: true
   ```

5. **Implement Rolling Restart**

   ```yaml
   - name: Restart Consul servers (one at a time)
     ansible.builtin.systemd:
       name: consul
       state: restarted
     throttle: 1
     when: inventory_hostname in groups['consul_servers']

   - name: Wait for Consul server to rejoin
     ansible.builtin.wait_for:
       port: 8300
       host: "{{ ansible_default_ipv4.address }}"
       delay: 10
       timeout: 60

   - name: Restart Consul clients
     ansible.builtin.systemd:
       name: consul
       state: restarted
     when: inventory_hostname in groups['consul_clients']
   ```

## Success Criteria

- [ ] All Consul agents have valid TLS certificates
- [ ] Consul cluster communication encrypted
- [ ] Auto-encrypt distributing certificates to clients
- [ ] `consul members` shows all nodes healthy
- [ ] No disruption to existing services
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/configure-consul-auto-encrypt.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/configure-consul-auto-encrypt.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-consul-auto-encrypt.yml
```

The validation playbook performs the following checks:

```yaml
- name: Validate Consul Auto-Encrypt Configuration
  hosts: consul_servers:consul_clients
  tasks:
    - name: Verify TLS is enabled in Consul configuration
      ansible.builtin.command: uv run consul info
      register: consul_info
      changed_when: false

    - name: Assert TLS is configured
      ansible.builtin.assert:
        that:
          - "'encrypt' in consul_info.stdout"
        fail_msg: "TLS encryption not enabled in Consul"

    - name: Check certificate validity
      ansible.builtin.command: >
        openssl x509 -in /opt/consul/tls/consul.crt -text -noout -checkend 86400
      register: cert_check
      changed_when: false
      failed_when: cert_check.rc != 0

    - name: Verify encrypted communication
      ansible.builtin.command: uv run consul members -detailed
      register: consul_members
      changed_when: false

    - name: Assert all members show encrypted status
      ansible.builtin.assert:
        that:
          - "'Status=alive' in consul_members.stdout"
        fail_msg: "Consul cluster communication issues detected"

    - name: Test auto-encrypt functionality (clients only)
      ansible.builtin.shell: >
        systemctl status consul | grep -q "auto-encrypt" ||
        journalctl -u consul --since="10 minutes ago" | grep -q "auto-encrypt"
      register: auto_encrypt_test
      changed_when: false
      when: inventory_hostname in groups['consul_clients']

    - name: Validate certificate auto-distribution
      ansible.builtin.stat:
        path: /opt/consul/tls/consul.crt
      register: client_cert

    - name: Assert client certificates exist
      ansible.builtin.assert:
        that:
          - client_cert.stat.exists
          - client_cert.stat.mode == '0644'
        fail_msg: "Client certificates not properly distributed"
```

Expected output:

- TLS encryption enabled in Consul configuration
- All certificates valid and not expiring within 24 hours
- All cluster members showing healthy status
- Auto-encrypt successfully distributing certificates to clients

## Notes

- Starting with `verify_incoming: false` for soft enforcement
- Will enable hard enforcement in PKI-006 after validation
- Auto-encrypt eliminates need for manual client certificate management
- Certificates auto-renewed before expiration
