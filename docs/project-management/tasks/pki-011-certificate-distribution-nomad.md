---
Task: Configure Certificate Distribution to Nomad Jobs
Task ID: PKI-011
Parent Issue: 98 - mTLS for Service Communication
Priority: P0 - Critical
Estimated Time: 4 hours
Dependencies: PKI-001, PKI-003
Status: Ready
---

## Objective

Create an Ansible playbook that implements automated certificate distribution to Nomad jobs using Vault agent sidecars and template stanzas, enabling workloads to obtain and renew certificates dynamically.

## Prerequisites

- [ ] Vault PKI roles configured (PKI-001)
- [ ] Nomad TLS enabled (PKI-003)
- [ ] Vault policies created for job certificate access
- [ ] Nomad integration with Vault configured

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/configure-nomad-certificate-distribution.yml
- Create: playbooks/infrastructure/vault/validate-certificate-distribution.yml
- Modify: nomad-jobs/examples/service-with-certs.nomad.hcl (example job with certificates)

## Reference Implementations

- Pattern example: playbooks/infrastructure/vault/configure-pki-intermediate.yml
- Validation pattern: playbooks/infrastructure/vault/validate-pki-basic.yml
- Similar task: PKI-003 (Nomad TLS configuration provides foundation)

## Execution Environment

- Target cluster: doggos-homelab (for Nomad/Consul services)
- Inventory: inventory/environments/doggos-homelab/proxmox.yml
- Required secrets (via Infisical):
  - CONSUL_MASTER_TOKEN (path: /apollo-13/consul)
  - VAULT_PROD_ROOT_TOKEN (path: /apollo-13/vault)
- Service addresses: Defined in inventory group_vars

## Dependencies

- PKI-001: Provides the root and intermediate PKI infrastructure that this task extends for job certificate distribution
- PKI-003: Provides the Nomad TLS configuration that enables secure communication between Nomad and Vault for certificate requests
- Existing: Nomad cluster must be operational and integrated with Vault

## Implementation Steps

1. **Create Nomad Job Certificate Role**

   ```yaml
   - name: Create Nomad job certificate role
     community.hashi_vault.vault_write:
       path: pki-int/roles/nomad-job
       data:
         allowed_domains:
           - "*.service.consul"
           - "*.nomad.local"
         allow_subdomains: true
         allow_bare_domains: false
         allow_localhost: false
         client_flag: true
         server_flag: false
         max_ttl: "168h" # 7 days for job certificates
         ttl: "24h" # Short-lived for security
   ```

2. **Configure Vault Agent Sidecar Template**

   ```hcl
   # Vault agent configuration for Nomad jobs
   job "service-with-tls" {
     group "app" {
       vault {
         policies = ["nomad-job-pki"]
         change_mode = "restart"
       }

       task "vault-agent" {
         driver = "docker"

         config {
           image = "vault:latest"
           command = "vault"
           args = ["agent", "-config=/local/agent.hcl"]
         }

         template {
           data = <<EOF
           auto_auth {
             method {
               type = "jwt"
               config {
                 path = "nomad"
                 remove_jwt_after_reading = false
               }
             }
             sink {
               type = "file"
               config {
                 path = "/secrets/vault-token"
               }
             }
           }

           template {
             source      = "/local/cert.tpl"
             destination = "/secrets/cert.pem"
           }

           template {
             source      = "/local/key.tpl"
             destination = "/secrets/key.pem"
           }
           EOF
           destination = "local/agent.hcl"
         }

         template {
           data = <<EOF
           {{ with secret "pki-int/issue/nomad-job"
              "common_name={{ env "NOMAD_JOB_NAME" }}.service.consul"
              "ttl=24h" }}
           {{ .Data.certificate }}
           {{ .Data.ca_chain }}
           {{ end }}
           EOF
           destination = "local/cert.tpl"
         }

         template {
           data = <<EOF
           {{ with secret "pki-int/issue/nomad-job"
              "common_name={{ env "NOMAD_JOB_NAME" }}.service.consul"
              "ttl=24h" }}
           {{ .Data.private_key }}
           {{ end }}
           EOF
           destination = "local/key.tpl"
           perms = "0600"
         }

         lifecycle {
           hook = "prestart"
           sidecar = true
         }
       }

       task "app" {
         driver = "docker"

         config {
           image = "app:latest"
           volumes = [
             "/secrets/cert.pem:/etc/ssl/cert.pem",
             "/secrets/key.pem:/etc/ssl/key.pem"
           ]
         }

         env {
           TLS_CERT = "/etc/ssl/cert.pem"
           TLS_KEY  = "/etc/ssl/key.pem"
         }
       }
     }
   }
   ```

3. **Implement Template Stanza Pattern**

   ```hcl
   # Direct template stanza without sidecar
   task "service" {
     driver = "docker"

     vault {
       policies = ["nomad-job-pki"]
     }

     template {
       data = <<EOF
       {{ with secret "pki-int/issue/nomad-job"
          (printf "common_name=%s.service.consul" (env "NOMAD_JOB_NAME"))
          "ttl=24h" }}
       {{ .Data.certificate }}
       {{ .Data.ca_chain }}
       {{ end }}
       EOF
       destination   = "secrets/cert.pem"
       change_mode   = "signal"
       change_signal = "SIGHUP"
       perms         = "0644"
     }

     template {
       data = <<EOF
       {{ with secret "pki-int/issue/nomad-job"
          (printf "common_name=%s.service.consul" (env "NOMAD_JOB_NAME"))
          "ttl=24h" }}
       {{ .Data.private_key }}
       {{ end }}
       EOF
       destination   = "secrets/key.pem"
       change_mode   = "signal"
       change_signal = "SIGHUP"
       perms         = "0600"
     }

     config {
       image = "app:latest"
       mount {
         type   = "bind"
         source = "secrets"
         target = "/etc/ssl"
       }
     }
   }
   ```

4. **Create Certificate Renewal Handler**

   ```yaml
   - name: Deploy certificate renewal handler script
     ansible.builtin.copy:
       dest: /usr/local/bin/nomad-cert-handler.sh
       mode: "0755"
       content: |
         #!/bin/bash
         # Script to handle certificate renewal in Nomad jobs

         SERVICE_NAME=$1
         CERT_PATH=$2
         KEY_PATH=$3

         # Function to reload service
         reload_service() {
           # Check if service supports SIGHUP
           if kill -0 $(cat /var/run/${SERVICE_NAME}.pid) 2>/dev/null; then
             kill -HUP $(cat /var/run/${SERVICE_NAME}.pid)
             echo "Reloaded ${SERVICE_NAME} with new certificate"
           else
             echo "Service ${SERVICE_NAME} restart required"
             systemctl restart ${SERVICE_NAME}
           fi
         }

         # Monitor certificate changes
         inotifywait -m -e modify ${CERT_PATH} |
         while read path action file; do
           echo "Certificate updated: ${file}"
           reload_service
         done
   ```

5. **Implement Batch Job Certificate Distribution**

   ```hcl
   # For batch/periodic jobs that need certificates
   job "batch-with-certs" {
     type = "batch"

     group "batch" {
       vault {
         policies = ["nomad-job-pki"]
       }

       task "cert-init" {
         driver = "docker"

         lifecycle {
           hook = "prestart"
         }

         config {
           image = "vault:latest"
           command = "sh"
           args = ["-c", <<EOF
             vault login -method=jwt
             vault write -format=json pki-int/issue/nomad-job \
               common_name="${NOMAD_JOB_NAME}.service.consul" \
               ttl="1h" > /alloc/data/cert.json

             cat /alloc/data/cert.json | jq -r '.data.certificate' > /alloc/data/cert.pem
             cat /alloc/data/cert.json | jq -r '.data.private_key' > /alloc/data/key.pem
             cat /alloc/data/cert.json | jq -r '.data.ca_chain' > /alloc/data/ca.pem
           EOF
           ]
         }
       }

       task "batch-work" {
         driver = "docker"

         config {
           image = "batch-processor:latest"
           mount {
             type   = "bind"
             source = "/alloc/data"
             target = "/certs"
           }
         }

         env {
           CERT_PATH = "/certs/cert.pem"
           KEY_PATH  = "/certs/key.pem"
           CA_PATH   = "/certs/ca.pem"
         }
       }
     }
   }
   ```

## Success Criteria

- [ ] All Nomad jobs can request and receive certificates
- [ ] Certificates auto-renew before expiration
- [ ] Service reload occurs without downtime
- [ ] Vault agent sidecars working for long-running services
- [ ] Template stanzas working for simpler deployments
- [ ] Batch jobs can obtain short-lived certificates
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/configure-nomad-certificate-distribution.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/configure-nomad-certificate-distribution.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-certificate-distribution.yml
```

Expected output:

```yaml
# Validation playbook
- name: Validate Nomad certificate distribution
  hosts: localhost
  vars:
    test_job_name: "cert-test-job"
    test_alloc_timeout: 300

  tasks:
    - name: Deploy test job with certificate requirements
      ansible.builtin.command:
        cmd: uv run nomad job run -
        stdin: |
          job "{{ test_job_name }}" {
            type = "batch"
            group "test" {
              vault {
                policies = ["nomad-job-pki"]
              }
              task "cert-test" {
                driver = "docker"
                config {
                  image = "alpine:latest"
                  command = "sh"
                  args = ["-c", "ls -la /secrets/ && sleep 30"]
                }
                template {
                  data = <<EOF
{{ with secret "pki-int/issue/nomad-job" "common_name=test.service.consul" "ttl=1h" }}
{{ .Data.certificate }}
{{ end }}
EOF
                  destination = "secrets/cert.pem"
                }
              }
            }
          }
      changed_when: false
      register: job_deploy

    - name: Wait for allocation to be running
      ansible.builtin.command:
        cmd: uv run nomad job status {{ test_job_name }}
      register: job_status
      until: "'running' in job_status.stdout"
      retries: "{{ test_alloc_timeout // 10 }}"
      delay: 10
      changed_when: false

    - name: Get allocation ID
      ansible.builtin.shell:
        cmd: uv run nomad job status {{ test_job_name }} | grep -E "^[a-f0-9]{8}" | head -1 | awk '{print $1}'
      register: alloc_id
      changed_when: false

    - name: Verify certificate files exist in allocation
      ansible.builtin.command:
        cmd: uv run nomad alloc exec {{ alloc_id.stdout }} ls -la /secrets/
      register: cert_files
      changed_when: false
      failed_when: "'cert.pem' not in cert_files.stdout"

    - name: Validate certificate details
      ansible.builtin.command:
        cmd: uv run nomad alloc exec {{ alloc_id.stdout }} openssl x509 -in /secrets/cert.pem -text -noout
      register: cert_details
      changed_when: false
      failed_when: "'test.service.consul' not in cert_details.stdout"

    - name: Check template rendering worked
      ansible.builtin.command:
        cmd: uv run nomad job status -verbose {{ test_job_name }}
      register: job_verbose
      changed_when: false
      failed_when: "'Template' not in job_verbose.stdout"

    - name: Verify certificate expiration
      ansible.builtin.command:
        cmd: uv run nomad alloc exec {{ alloc_id.stdout }} openssl x509 -in /secrets/cert.pem -dates -noout
      register: cert_dates
      changed_when: false

    - name: Clean up test job
      ansible.builtin.command:
        cmd: uv run nomad job stop -purge {{ test_job_name }}
      changed_when: false
      when: job_deploy is succeeded

    - name: Display validation results
      ansible.builtin.debug:
        msg:
          - "Certificate files present: {{ 'cert.pem' in cert_files.stdout }}"
          - "Certificate CN valid: {{ 'test.service.consul' in cert_details.stdout }}"
          - "Template rendering: {{ 'Template' in job_verbose.stdout }}"
          - "Certificate dates: {{ cert_dates.stdout }}"
```

## Notes

- Template stanzas are simpler but less flexible than sidecars
- Vault agent sidecars provide better observability
- Short-lived certificates (24h) enhance security
- Consider using Consul Connect for service mesh mTLS (see PKI-012)
- Batch jobs should use even shorter TTLs (1h)
