---
Task: Configure Nomad TLS for Cluster Communication
Task ID: PKI-003
Parent Issue: 98 - mTLS for Service Communication
Priority: P0 - Critical
Estimated Time: 3 hours
Dependencies: PKI-001
Status: Ready
---

## Objective

Create an Ansible playbook that enables TLS encryption and authentication for all Nomad cluster communication (RPC and HTTP) using Vault-issued certificates.

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/configure-nomad-tls.yml
- Create: playbooks/infrastructure/vault/validate-nomad-tls.yml
- Modify: Nomad configuration files for TLS settings
- Modify: /etc/environment for Nomad client environment variables

## Reference Implementations

- Pattern example: playbooks/infrastructure/vault/deploy-tls-certificates.yml
- Validation pattern: playbooks/infrastructure/vault/smoke-test.yml
- Certificate generation: Similar pattern in setup-pki-intermediate-ca.yml (lines 246-256)

## Dependencies

- PKI-001: Created PKI roles for certificate issuance (nomad-agent role required)
- Nomad cluster must be operational and accessible
- Vault intermediate CA configured and issuing certificates

## Prerequisites

- [ ] PKI roles created (PKI-001)
- [ ] Nomad cluster operational
- [ ] Vault access configured on Nomad nodes

## Implementation Steps

1. **Generate Nomad Certificates**

   ```yaml
   - name: Generate Nomad server certificates
     community.hashi_vault.vault_pki_generate_certificate:
       role_name: nomad-agent
       common_name: "server.global.nomad"
       alt_names:
         - "server.{{ datacenter }}.nomad"
         - "nomad.service.consul"
         - "{{ inventory_hostname }}.nomad.spaceships.work"
       ip_sans:
         - "{{ ansible_default_ipv4.address }}"
         - "127.0.0.1"
       ttl: "720h"
     register: nomad_cert
     when: nomad_node_role == "server"

   - name: Generate Nomad client certificates
     community.hashi_vault.vault_pki_generate_certificate:
       role_name: nomad-agent
       common_name: "client.global.nomad"
       alt_names:
         - "client.{{ datacenter }}.nomad"
         - "{{ inventory_hostname }}.nomad.spaceships.work"
       ip_sans:
         - "{{ ansible_default_ipv4.address }}"
         - "127.0.0.1"
       ttl: "720h"
     register: nomad_cert
     when: nomad_node_role == "client"
   ```

2. **Deploy Certificates**

   ```yaml
   - name: Create Nomad TLS directory
     ansible.builtin.file:
       path: /opt/nomad/tls
       state: directory
       owner: nomad
       group: nomad
       mode: "0755"

   - name: Deploy Nomad certificates
     ansible.builtin.copy:
       content: "{{ item.content }}"
       dest: "{{ item.dest }}"
       owner: nomad
       group: nomad
       mode: "{{ item.mode }}"
     loop:
       - { content: "{{ consul_ca_cert.data.data }}", dest: "/opt/nomad/tls/ca.crt", mode: "0644" }
       - { content: "{{ nomad_cert.data.certificate }}", dest: "/opt/nomad/tls/nomad.crt", mode: "0644" }
       - { content: "{{ nomad_cert.data.private_key }}", dest: "/opt/nomad/tls/nomad.key", mode: "0600" }
   ```

3. **Configure Nomad TLS Settings**

   ```yaml
   - name: Configure Nomad TLS
     ansible.builtin.blockinfile:
       path: /etc/nomad.d/nomad.hcl
       marker: "# {mark} ANSIBLE MANAGED TLS CONFIG"
       block: |
         tls {
           http = true
           rpc  = true

           ca_file   = "/opt/nomad/tls/ca.crt"
           cert_file = "/opt/nomad/tls/nomad.crt"
           key_file  = "/opt/nomad/tls/nomad.key"

           verify_server_hostname = true
           verify_https_client    = false  # Soft enforcement initially

           # TLS versions
           tls_min_version = "tls12"
           tls_cipher_suites = [
             "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
             "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
           ]
         }
   ```

4. **Update Environment Variables**

   ```yaml
   - name: Set Nomad client environment for TLS
     ansible.builtin.lineinfile:
       path: /etc/environment
       regexp: "^{{ item.key }}="
       line: "{{ item.key }}={{ item.value }}"
     loop:
       - { key: "NOMAD_ADDR", value: "https://127.0.0.1:4646" }
       - { key: "NOMAD_CACERT", value: "/opt/nomad/tls/ca.crt" }
       - { key: "NOMAD_CLIENT_CERT", value: "/opt/nomad/tls/nomad.crt" }
       - { key: "NOMAD_CLIENT_KEY", value: "/opt/nomad/tls/nomad.key" }
   ```

5. **Rolling Restart with Validation**

   ```yaml
   - name: Restart Nomad servers sequentially
     ansible.builtin.systemd:
       name: nomad
       state: restarted
     throttle: 1
     when: nomad_node_role == "server"

   - name: Wait for Nomad server API
     ansible.builtin.uri:
       url: "https://{{ ansible_default_ipv4.address }}:4646/v1/status/leader"
       validate_certs: yes
       ca_path: /opt/nomad/tls/ca.crt
     retries: 10
     delay: 5

   - name: Restart Nomad clients
     ansible.builtin.systemd:
       name: nomad
       state: restarted
     when: nomad_node_role == "client"
     throttle: 3 # Restart 3 clients at a time
   ```

## Success Criteria

- [ ] All Nomad nodes using TLS for RPC and HTTP
- [ ] `nomad server members` shows all servers healthy
- [ ] `nomad node status` shows all clients ready
- [ ] API calls require HTTPS
- [ ] No job disruptions during migration
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/configure-nomad-tls.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/configure-nomad-tls.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-nomad-tls.yml
```

The validation playbook performs the following checks:

```yaml
- name: Validate Nomad TLS Configuration
  hosts: nomad_servers:nomad_clients
  tasks:
    - name: Verify TLS is enabled in Nomad configuration
      ansible.builtin.command: uv run nomad agent-info
      register: nomad_agent_info
      changed_when: false

    - name: Assert TLS settings are configured
      ansible.builtin.assert:
        that:
          - "'tls' in nomad_agent_info.stdout"
          - "'http = true' in nomad_agent_info.stdout or 'http=true' in nomad_agent_info.stdout"
        fail_msg: "TLS not properly configured in Nomad"

    - name: Test HTTPS API endpoint
      ansible.builtin.uri:
        url: "https://{{ ansible_default_ipv4.address }}:4646/v1/status/leader"
        validate_certs: yes
        ca_path: /opt/nomad/tls/ca.crt
        timeout: 10
      register: api_test

    - name: Assert API responds over HTTPS
      ansible.builtin.assert:
        that:
          - api_test.status == 200
        fail_msg: "Nomad HTTPS API not responding correctly"

    - name: Verify certificate validity and properties
      ansible.builtin.command: >
        openssl x509 -in /opt/nomad/tls/nomad.crt -text -noout -checkend 86400
      register: cert_check
      changed_when: false
      failed_when: cert_check.rc != 0

    - name: Check Nomad cluster health (servers)
      ansible.builtin.command: uv run nomad server members
      register: server_members
      changed_when: false
      when: nomad_node_role == "server"

    - name: Assert all servers are alive
      ansible.builtin.assert:
        that:
          - "'alive' in server_members.stdout"
        fail_msg: "Nomad server cluster health issues detected"
      when: nomad_node_role == "server"

    - name: Check Nomad node status (all nodes)
      ansible.builtin.command: uv run nomad node status
      register: node_status
      changed_when: false

    - name: Assert nodes are ready
      ansible.builtin.assert:
        that:
          - "'ready' in node_status.stdout"
        fail_msg: "Nomad nodes not in ready state"

    - name: Verify RPC encryption (servers only)
      ansible.builtin.command: uv run nomad operator raft list-peers
      register: raft_peers
      changed_when: false
      when: nomad_node_role == "server"

    - name: Assert Raft peers are accessible
      ansible.builtin.assert:
        that:
          - raft_peers.rc == 0
          - raft_peers.stdout | length > 0
        fail_msg: "Nomad Raft communication issues detected"
      when: nomad_node_role == "server"

    - name: Validate environment variables are set
      ansible.builtin.shell: |
        source /etc/environment
        [ -n "$NOMAD_ADDR" ] && [ -n "$NOMAD_CACERT" ]
      register: env_check
      changed_when: false

    - name: Assert Nomad client environment is configured
      ansible.builtin.assert:
        that:
          - env_check.rc == 0
        fail_msg: "Nomad client environment variables not properly configured"
```

Expected output:

- TLS enabled for both HTTP and RPC communication
- HTTPS API endpoint responds correctly with valid certificates
- All certificates valid and not expiring within 24 hours
- All Nomad servers showing alive status in cluster
- All Nomad nodes in ready state
- Raft communication working correctly between servers
- Environment variables properly configured for HTTPS client access

## Notes

- HTTP and RPC TLS both enabled for complete encryption
- Starting with `verify_https_client: false` for soft enforcement
- Client verification will be enabled in PKI-006
- Nomad CLI automatically uses HTTPS when NOMAD_ADDR set
