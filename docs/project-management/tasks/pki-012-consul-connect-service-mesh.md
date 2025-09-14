---
Task: Enable Consul Connect Service Mesh with Vault PKI
Task ID: PKI-012
Parent Issue: 98 - mTLS for Service Communication
Priority: P0 - Critical
Estimated Time: 4 hours
Dependencies: PKI-001, PKI-002
Status: Ready
---

## Objective

Create an Ansible playbook that configures Consul Connect service mesh to use Vault as the certificate authority provider, enabling automatic mTLS between services with centralized PKI management.

## Prerequisites

- [ ] Vault PKI engine configured with intermediate CA
- [ ] Consul servers running with ACLs enabled
- [ ] Consul agents on all nodes
- [ ] Network connectivity between Consul and Vault

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/configure-consul-connect-vault-ca.yml
- Create: playbooks/infrastructure/vault/validate-consul-connect.yml
- Modify: inventory/group_vars/consul_servers.yml (Connect CA configuration)
- Create: nomad-jobs/examples/connect-enabled-service.nomad.hcl (example Connect-enabled job)

## Reference Implementations

- Pattern example: playbooks/infrastructure/consul/configure-consul-cluster.yml
- Validation pattern: playbooks/infrastructure/consul/validate-consul-cluster.yml
- Similar task: PKI-002 (Consul TLS configuration provides foundation for Connect)

## Execution Environment

- Target cluster: doggos-homelab (for Nomad/Consul services)
- Inventory: inventory/environments/doggos-homelab/proxmox.yml
- Required secrets (via Infisical):
  - CONSUL_MASTER_TOKEN (path: /apollo-13/consul)
  - VAULT_PROD_ROOT_TOKEN (path: /apollo-13/vault)
- Service addresses: Defined in inventory group_vars

## Dependencies

- PKI-001: Provides the PKI root and intermediate CA infrastructure required for Connect CA provider configuration
- PKI-002: Provides the basic Consul TLS configuration that Connect builds upon for service mesh security
- Existing: Consul cluster must be operational with ACLs enabled for Connect service registration and intentions

## Implementation Steps

1. **Configure Vault as Connect CA Provider**

   ```yaml
   - name: Configure Consul to use Vault as CA provider
     ansible.builtin.copy:
       dest: /etc/consul.d/connect.hcl
       content: |
         connect {
           enabled = true

           ca_provider = "vault"

           ca_config {
             address = "https://vault.service.consul:8200"
             token = "{{ consul_vault_token }}"

             root_pki_path = "pki"
             intermediate_pki_path = "pki-int-connect"

             # Leaf certificate TTL
             leaf_cert_ttl = "72h"

             # Rotation configuration
             rotation_period = "2160h" # 90 days

             # Cross-signing for migrations
             intermediate_cert_ttl = "8760h" # 1 year

             # Private key configuration
             private_key_type = "rsa"
             private_key_bits = 2048

             # TLS configuration for Vault connection
             ca_file = "/opt/consul/tls/vault-ca.pem"
             tls_skip_verify = false
           }
         }
     notify: reload consul

   - name: Create Connect-specific intermediate CA in Vault
     community.hashi_vault.vault_write:
       path: sys/mounts/pki-int-connect
       data:
         type: pki
         config:
           max_lease_ttl: "87600h" # 10 years

   - name: Configure Connect intermediate CA
     community.hashi_vault.vault_write:
       path: pki-int-connect/intermediate/generate/internal
       data:
         common_name: "Consul Connect Intermediate CA"
         key_type: "rsa"
         key_bits: 4096
   ```

2. **Enable Service Proxies and Intentions**

   ```yaml
   - name: Deploy service with Connect proxy
     ansible.builtin.copy:
       dest: /etc/consul.d/web-service.hcl
       content: |
         service {
           name = "web"
           port = 8080

           connect {
             sidecar_service {
               port = 21000

               proxy {
                 # Upstream dependencies
                 upstreams = [
                   {
                     destination_name = "database"
                     local_bind_port  = 5432
                   },
                   {
                     destination_name = "cache"
                     local_bind_port  = 6379
                   }
                 ]

                 # Proxy configuration
                 config {
                   # Enable HTTP/2
                   protocol = "http2"

                   # Set timeouts
                   local_connect_timeout_ms = 1000
                   handshake_timeout_ms = 5000
                 }
               }
             }
           }

           # Health check
           check {
             name = "Web Health"
             http = "http://localhost:8080/health"
             interval = "10s"
           }
         }

   - name: Create service intentions
     community.general.consul_intention:
       service_src: "{{ item.src }}"
       service_dest: "{{ item.dest }}"
       action: "{{ item.action }}"
       state: present
     loop:
       - { src: "web", dest: "database", action: "allow" }
       - { src: "web", dest: "cache", action: "allow" }
       - { src: "*", dest: "*", action: "deny" } # Default deny
   ```

3. **Configure Nomad Jobs with Connect**

   ```hcl
   # Nomad job with Connect integration
   job "api-service" {
     datacenters = ["dc1"]

     group "api" {
       network {
         mode = "bridge"

         port "http" {
           to = 8080
         }
       }

       service {
         name = "api"
         port = "http"

         connect {
           sidecar_service {
             proxy {
               upstreams {
                 destination_name = "postgres"
                 local_bind_port  = 5432
               }

               upstreams {
                 destination_name = "redis"
                 local_bind_port  = 6379
               }
             }
           }
         }

         check {
           type     = "http"
           path     = "/health"
           interval = "10s"
           timeout  = "2s"
         }
       }

       task "api" {
         driver = "docker"

         config {
           image = "api:latest"
         }

         env {
           DATABASE_URL = "postgres://localhost:5432/api"
           REDIS_URL    = "redis://localhost:6379"
         }
       }
     }
   }
   ```

4. **Implement Connect Gateway for External Services**

   ```yaml
   - name: Configure ingress gateway
     ansible.builtin.copy:
       dest: /etc/consul.d/ingress-gateway.hcl
       content: |
         Kind = "ingress-gateway"
         Name = "ingress-gateway"

         TLS {
           Enabled = true
         }

         Listeners = [
           {
             Port = 443
             Protocol = "http"
             Services = [
               {
                 Name = "web"
                 Hosts = ["web.spaceships.work", "web.service.consul"]

                 TLS {
                   SDS {
                     CertResource = "web-cert"
                     ClusterName = "web"
                   }
                 }
               }
             ]
           }
         ]

   - name: Deploy ingress gateway in Nomad
     ansible.builtin.copy:
       dest: /tmp/ingress-gateway.nomad.hcl
       content: |
         job "ingress-gateway" {
           datacenters = ["dc1"]

           group "gateway" {
             network {
               mode = "bridge"

               port "ingress" {
                 static = 443
                 to     = 443
               }
             }

             service {
               name = "ingress-gateway"

               connect {
                 gateway {
                   proxy {}

                   ingress {
                     listener {
                       port     = 443
                       protocol = "http"

                       service {
                         name  = "web"
                         hosts = ["web.spaceships.work"]
                       }
                     }
                   }
                 }
               }
             }

             task "gateway" {
               driver = "docker"

               config {
                 image = "envoyproxy/envoy:v1.27.0"
               }
             }
           }
         }

   - name: Run ingress gateway job
     ansible.builtin.command:
       cmd: nomad job run /tmp/ingress-gateway.nomad.hcl
   ```

5. **Configure Observability for Connect**

   ```yaml
   - name: Enable Connect metrics
     ansible.builtin.blockinfile:
       path: /etc/consul.d/telemetry.hcl
       block: |
         telemetry {
           prometheus_retention_time = "30s"

           # Connect-specific metrics
           prefix_filter = [
             "+consul.connect",
             "+consul.mesh",
             "+consul.proxy"
           ]
         }

         ui_config {
           enabled = true

           metrics_provider = "prometheus"
           metrics_proxy {
             base_url = "http://prometheus.service.consul:9090"
           }

           dashboard_url_templates {
             service = "https://grafana.service.consul/d/consul-service?var-service={{Service.Name}}"
           }
         }

   - name: Deploy Connect dashboard
     ansible.builtin.copy:
       dest: /etc/grafana/dashboards/consul-connect.json
       content: "{{ lookup('file', 'files/consul-connect-dashboard.json') }}"
   ```

## Success Criteria

- [ ] Vault successfully configured as Connect CA provider
- [ ] Services can establish mTLS connections via Connect
- [ ] Intentions enforced between services
- [ ] Ingress gateway routing external traffic
- [ ] Metrics and observability working
- [ ] Certificate rotation happening automatically
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/configure-consul-connect-vault-ca.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/configure-consul-connect-vault-ca.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-consul-connect.yml
```

Expected output:

```yaml
# Validation playbook
- name: Validate Consul Connect service mesh with Vault PKI
  hosts: localhost
  vars:
    test_service_name: "test-web"
    test_timeout: 120

  tasks:
    - name: Verify Connect CA configuration
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/connect/ca/configuration"
        method: GET
        return_content: true
      register: ca_config
      failed_when:
        - ca_config.status != 200
        - "'vault' not in ca_config.json.Provider"
      changed_when: false

    - name: Check root certificate from Vault
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/connect/ca/roots"
        method: GET
        return_content: true
      register: ca_roots
      failed_when:
        - ca_roots.status != 200
        - ca_roots.json.Roots | length == 0
      changed_when: false

    - name: List Connect-enabled services
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/catalog/services"
        method: GET
        return_content: true
      register: services_list
      changed_when: false

    - name: Register test service with Connect enabled
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/agent/service/register"
        method: PUT
        body_format: json
        body:
          ID: "{{ test_service_name }}"
          Name: "{{ test_service_name }}"
          Tags: ["test", "connect"]
          Port: 8080
          Connect:
            SidecarService: {}
          Check:
            HTTP: "http://localhost:8080/health"
            Interval: "10s"
      register: service_register
      changed_when: false

    - name: Wait for service to be registered
      ansible.builtin.pause:
        seconds: 5

    - name: Get leaf certificate for test service
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/agent/connect/ca/leaf/{{ test_service_name }}"
        method: GET
        return_content: true
      register: leaf_cert
      failed_when:
        - leaf_cert.status != 200
        - "'CertPEM' not in leaf_cert.json"
      changed_when: false

    - name: Verify leaf certificate details
      ansible.builtin.command:
        cmd: openssl x509 -text -noout
        stdin: "{{ leaf_cert.json.CertPEM }}"
      register: cert_details
      changed_when: false
      failed_when: "'spiffe://{{ consul_datacenter | default('dc1') }}.consul/ns/default/dc/{{ consul_datacenter | default('dc1') }}/svc/{{ test_service_name }}' not in cert_details.stdout"

    - name: Check service intentions
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/connect/intentions"
        method: GET
        return_content: true
      register: intentions_list
      changed_when: false

    - name: Create test intention (allow web to database)
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/connect/intentions"
        method: POST
        body_format: json
        body:
          SourceName: "web"
          DestinationName: "database"
          Action: "allow"
          Description: "Test intention for validation"
      register: intention_create
      changed_when: false
      ignore_errors: true

    - name: Verify intention was created
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/connect/intentions"
        method: GET
        return_content: true
      register: intentions_updated
      changed_when: false
      failed_when:
        - intentions_updated.status != 200
        - "'web' not in (intentions_updated.json | map(attribute='SourceName') | list)"

    - name: Test Connect proxy authorization
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/agent/connect/authorize"
        method: POST
        body_format: json
        body:
          Target: "database"
          ClientCertURI: "spiffe://{{ consul_datacenter | default('dc1') }}.consul/ns/default/dc/{{ consul_datacenter | default('dc1') }}/svc/web"
      register: auth_check
      changed_when: false
      failed_when:
        - auth_check.status != 200
        - not auth_check.json.Authorized

    - name: Verify CA rotation capability
      community.hashi_vault.vault_read:
        path: "{{ connect_ca_config.ca_config.intermediate_pki_path | default('pki-int-connect') }}/cert/ca"
      register: connect_ca_cert
      changed_when: false

    - name: Clean up test service
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/agent/service/deregister/{{ test_service_name }}"
        method: PUT
      changed_when: false
      ignore_errors: true

    - name: Clean up test intention
      ansible.builtin.uri:
        url: "http://{{ consul_endpoint | default('localhost:8500') }}/v1/connect/intentions/{{ intention_create.json.ID | default('') }}"
        method: DELETE
      when: intention_create is succeeded and 'json' in intention_create
      changed_when: false
      ignore_errors: true

    - name: Display validation results
      ansible.builtin.debug:
        msg:
          - "Connect CA Provider: {{ ca_config.json.Provider }}"
          - "Root certificates count: {{ ca_roots.json.Roots | length }}"
          - "Test service registered: {{ service_register.status == 200 }}"
          - "Leaf certificate obtained: {{ 'CertPEM' in leaf_cert.json }}"
          - "Certificate has correct SPIFFE ID: {{ 'spiffe://' in cert_details.stdout }}"
          - "Authorization working: {{ auth_check.json.Authorized | default(false) }}"
          - "Intentions functional: {{ intentions_updated.status == 200 }}"
```

## Notes

- Connect automatically handles certificate rotation
- Envoy proxy is the default sidecar proxy
- Intentions provide zero-trust networking
- Gateway patterns enable gradual migration
- Consider using Consul ESM for external services
