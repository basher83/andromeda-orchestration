# Task: Configure Nomad TLS for Cluster Communication

**Task ID**: PKI-003
**Parent Issue**: #98 (mTLS for Service Communication)
**Priority**: P0 - Critical
**Estimated Time**: 3 hours
**Dependencies**: PKI-001

## Objective

Enable TLS encryption and authentication for all Nomad cluster communication (RPC and HTTP) using Vault-issued certificates.

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
       mode: '0755'

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
     throttle: 3  # Restart 3 clients at a time
   ```

## Success Criteria

- [ ] All Nomad nodes using TLS for RPC and HTTP
- [ ] `nomad server members` shows all servers healthy
- [ ] `nomad node status` shows all clients ready
- [ ] API calls require HTTPS
- [ ] No job disruptions during migration

## Validation

```bash
# Verify TLS is enabled
nomad agent-info | grep "tls"

# Test HTTPS API
curl -k https://localhost:4646/v1/status/leader

# Verify certificate
openssl s_client -connect localhost:4646 -showcerts

# Check cluster health
nomad server members
nomad node status

# Verify RPC encryption
nomad operator raft list-peers
```

## Notes

- HTTP and RPC TLS both enabled for complete encryption
- Starting with `verify_https_client: false` for soft enforcement
- Client verification will be enabled in PKI-006
- Nomad CLI automatically uses HTTPS when NOMAD_ADDR set
