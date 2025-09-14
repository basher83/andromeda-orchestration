---
Task: Implement Certificate Revocation Infrastructure
Task ID: PKI-013
Parent Issue: 100 - Certificate Rotation and Distribution
Priority: P1 - High
Estimated Time: 3 hours
Dependencies: PKI-001, PKI-007
Status: Ready
---

## Objective

Create Ansible playbooks that deploy a comprehensive certificate revocation infrastructure including OCSP responder and CRL distribution to handle compromised certificates and maintain security posture.

## Prerequisites

- [ ] Vault PKI engine operational with CAs configured
- [ ] Web server available for CRL distribution
- [ ] Database for revocation tracking
- [ ] Monitoring infrastructure in place

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/configure-certificate-revocation.yml
- Create: playbooks/infrastructure/vault/deploy-ocsp-responder.yml
- Create: playbooks/infrastructure/vault/validate-certificate-revocation.yml
- Create: scripts/cert-revoke (certificate revocation management script)
- Create: scripts/emergency-ca-revoke (emergency CA revocation script)

## Reference Implementations

- Pattern example: playbooks/infrastructure/vault/configure-pki-intermediate.yml
- Validation pattern: playbooks/infrastructure/vault/validate-pki-basic.yml
- Similar task: PKI-007 (Certificate monitoring provides foundation for revocation alerts)

## Execution Environment

- Target cluster: doggos-homelab (for Nomad/Consul services)
- Inventory: inventory/environments/doggos-homelab/proxmox.yml
- Required secrets (via Infisical):
  - CONSUL_MASTER_TOKEN (path: /apollo-13/consul)
  - VAULT_PROD_ROOT_TOKEN (path: /apollo-13/vault)
- Service addresses: Defined in inventory group_vars

## Dependencies

- PKI-001: Provides the root and intermediate PKI infrastructure required for CRL generation and OCSP response signing
- PKI-007: Provides the certificate monitoring infrastructure that integrates with revocation status checking
- Existing: Web server infrastructure must be available for CRL distribution endpoints

## Implementation Steps

1. **Configure CRL Distribution Points**

   ```yaml
   - name: Configure CRL settings in Vault PKI
     community.hashi_vault.vault_write:
       path: pki-int/config/crl
       data:
         expiry: "72h" # CRL validity period
         disable: false

   - name: Set CRL distribution points
     community.hashi_vault.vault_write:
       path: pki-int/config/urls
       data:
         issuing_certificates:
           - "https://vault.spaceships.work:8200/v1/pki-int/ca"
         crl_distribution_points:
           - "https://pki.spaceships.work/crl/intermediate.crl"
           - "ldap://ldap.spaceships.work/cn=crl,dc=spaceships,dc=work"
         ocsp_servers:
           - "https://ocsp.spaceships.work"

   - name: Configure automatic CRL building
     ansible.builtin.cron:
       name: "Build and publish CRL"
       minute: "0"
       hour: "*/6" # Every 6 hours
       job: |
         vault read -format=pem pki-int/cert/crl > /tmp/intermediate.crl
         cp /tmp/intermediate.crl /var/www/pki/crl/intermediate.crl
         chmod 644 /var/www/pki/crl/intermediate.crl
       user: vault
   ```

2. **Deploy OCSP Responder**

   ```yaml
   - name: Install OCSP responder container
     ansible.builtin.copy:
       dest: /opt/ocsp/docker-compose.yml
       content: |
         version: '3.8'
         services:
           ocsp-responder:
             image: vault-ocsp:latest
             build:
               context: .
               dockerfile: Dockerfile.ocsp
             ports:
               - "8888:8888"
             environment:
               VAULT_ADDR: "https://vault.service.consul:8200"
               VAULT_TOKEN: "${OCSP_VAULT_TOKEN}"
               OCSP_PORT: "8888"
             volumes:
               - ./config:/config
               - ./certs:/certs
             restart: unless-stopped
             healthcheck:
               test: ["CMD", "curl", "-f", "http://localhost:8888/health"]
               interval: 30s
               timeout: 10s
               retries: 3

   - name: Create OCSP responder Dockerfile
     ansible.builtin.copy:
       dest: /opt/ocsp/Dockerfile.ocsp
       content: |
         FROM golang:1.21-alpine AS builder

         RUN apk add --no-cache git

         WORKDIR /app
         RUN git clone https://github.com/T-Systems-MMS/vault-ocsp.git .
         RUN go build -o vault-ocsp ./cmd/vault-ocsp

         FROM alpine:latest
         RUN apk add --no-cache ca-certificates

         COPY --from=builder /app/vault-ocsp /usr/local/bin/

         EXPOSE 8888
         CMD ["vault-ocsp", "serve"]

   - name: Configure OCSP responder
     ansible.builtin.copy:
       dest: /opt/ocsp/config/ocsp.yaml
       content: |
         vault:
           address: "https://vault.service.consul:8200"
           token: "{{ ocsp_vault_token }}"
           pki_mount: "pki-int"

         server:
           address: ":8888"
           tls:
             enabled: true
             cert_file: "/certs/ocsp.crt"
             key_file: "/certs/ocsp.key"

         cache:
           enabled: true
           ttl: 300  # 5 minutes
           max_size: 10000

         logging:
           level: "info"
           format: "json"

   - name: Start OCSP responder
     ansible.builtin.docker_compose:
       project_src: /opt/ocsp
       state: present
   ```

3. **Implement Revocation Management Interface**

   ```yaml
   - name: Deploy revocation management script
     ansible.builtin.copy:
       dest: /usr/local/bin/cert-revoke
       mode: "0755"
       content: |
         #!/bin/bash
         set -euo pipefail

         SERIAL=$1
         REASON=${2:-unspecified}

         VALID_REASONS="unspecified keyCompromise caCompromise affiliationChanged superseded cessationOfOperation certificateHold"

         if [[ ! " $VALID_REASONS " =~ " $REASON " ]]; then
           echo "Invalid revocation reason. Valid reasons: $VALID_REASONS"
           exit 1
         fi

         # Record revocation request
         echo "$(date '+%Y-%m-%d %H:%M:%S'),${SERIAL},${REASON},${USER}" >> /var/log/cert-revocations.log

         # Revoke certificate in Vault
         vault write pki-int/revoke serial_number="${SERIAL}" revocation_reason="${REASON}"

         # Rebuild CRL immediately
         vault read -format=pem pki-int/cert/crl > /tmp/intermediate.crl
         cp /tmp/intermediate.crl /var/www/pki/crl/intermediate.crl

         # Send notification
         consul event -name=cert-revoked -payload="{\"serial\":\"${SERIAL}\",\"reason\":\"${REASON}\"}"

         echo "Certificate ${SERIAL} revoked successfully"

   - name: Create revocation audit log rotation
     ansible.builtin.copy:
       dest: /etc/logrotate.d/cert-revocations
       content: |
         /var/log/cert-revocations.log {
           monthly
           rotate 12
           compress
           notifempty
           create 0600 vault vault
         }
   ```

4. **Configure Certificate Status Checking**

   ```yaml
   - name: Deploy certificate status checker
     ansible.builtin.copy:
       dest: /usr/local/bin/check-cert-status
       mode: "0755"
       content: |
         #!/bin/bash

         CERT_FILE=$1

         if [[ ! -f "$CERT_FILE" ]]; then
           echo "Certificate file not found: $CERT_FILE"
           exit 1
         fi

         # Extract serial number
         SERIAL=$(openssl x509 -serial -noout -in "$CERT_FILE" | cut -d= -f2)

         # Check OCSP status
         echo "Checking OCSP status for serial: $SERIAL"
         openssl ocsp \
           -CAfile /opt/vault/tls/ca-chain.pem \
           -url https://ocsp.spaceships.work \
           -issuer /opt/vault/tls/intermediate-ca.pem \
           -cert "$CERT_FILE" \
           -header "Host=ocsp.spaceships.work"

         # Check CRL
         echo "Checking CRL for serial: $SERIAL"
         curl -s https://pki.spaceships.work/crl/intermediate.crl | \
           openssl crl -inform DER -text -noout | \
           grep -q "$SERIAL" && echo "REVOKED" || echo "VALID"

   - name: Integrate status checking with monitoring
     ansible.builtin.copy:
       dest: /etc/consul.d/cert-status-check.json
       content: |
         {
           "check": {
             "id": "cert-revocation-status",
             "name": "Certificate Revocation Status",
             "args": ["/usr/local/bin/check-cert-status", "/opt/consul/tls/consul.crt"],
             "interval": "1h",
             "timeout": "10s"
           }
         }
   ```

5. **Implement Emergency Revocation Procedures**

   ```yaml
   - name: Create emergency CA revocation script
     ansible.builtin.copy:
       dest: /usr/local/bin/emergency-ca-revoke
       mode: "0700"
       owner: root
       content: |
         #!/bin/bash
         set -euo pipefail

         echo "=== EMERGENCY CA REVOCATION PROCEDURE ==="
         echo "This will revoke ALL certificates issued by the intermediate CA"
         read -p "Are you absolutely sure? Type 'REVOKE ALL' to continue: " confirmation

         if [[ "$confirmation" != "REVOKE ALL" ]]; then
           echo "Aborted"
           exit 1
         fi

         # Backup current state
         BACKUP_DIR="/var/backups/pki-emergency-$(date +%Y%m%d-%H%M%S)"
         mkdir -p "$BACKUP_DIR"
         vault read -format=json pki-int/cert/ca > "$BACKUP_DIR/ca.json"
         vault list -format=json pki-int/certs > "$BACKUP_DIR/certs.json"

         # Revoke intermediate CA
         vault write pki/root/revoke \
           certificate=@/opt/vault/tls/intermediate-ca.pem

         # Generate new intermediate CA
         vault write pki-int/intermediate/generate/internal \
           common_name="HomeLab Intermediate CA (Renewed)" \
           ttl="43800h"

         # Sign with root
         vault write pki/root/sign-intermediate \
           csr=@pki_intermediate.csr \
           format=pem_bundle \
           ttl="43800h"

         # Trigger all services to renew certificates
         consul event -name=ca-revoked

         echo "Emergency revocation complete. All services must renew certificates."

   - name: Create revocation recovery playbook
     ansible.builtin.copy:
       dest: /opt/ansible/playbooks/emergency-ca-recovery.yml
       content: |
         ---
         - name: Emergency CA Recovery
           hosts: all
           serial: 1
           vars:
             force_renewal: true

           tasks:
             - name: Stop all services
               ansible.builtin.systemd:
                 name: "{{ item }}"
                 state: stopped
               loop:
                 - consul
                 - nomad
                 - vault

             - name: Clear old certificates
               ansible.builtin.file:
                 path: "/opt/{{ item }}/tls"
                 state: absent
               loop:
                 - consul
                 - nomad
                 - vault

             - name: Request new certificates
               include_role:
                 name: cert_rotation
               vars:
                 emergency_mode: true

             - name: Start services
               ansible.builtin.systemd:
                 name: "{{ item }}"
                 state: started
               loop:
                 - vault
                 - consul
                 - nomad
   ```

## Success Criteria

- [ ] CRL published and accessible via HTTP/LDAP
- [ ] OCSP responder operational and responding to queries
- [ ] Revocation process documented and tested
- [ ] Certificate status checks integrated with monitoring
- [ ] Emergency procedures tested and documented
- [ ] Audit logging for all revocation events
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/configure-certificate-revocation.yml
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/deploy-ocsp-responder.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/configure-certificate-revocation.yml
uv run ansible-lint playbooks/infrastructure/vault/deploy-ocsp-responder.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-certificate-revocation.yml
```

Expected output:

```yaml
# Validation playbook
- name: Validate certificate revocation infrastructure
  hosts: localhost
  vars:
    pki_domain: "pki.spaceships.work"
    ocsp_domain: "ocsp.spaceships.work"
    test_cert_cn: "revocation-test.spaceships.work"
    temp_dir: "/tmp/pki-validation"

  tasks:
    - name: Create temporary directory for certificates
      ansible.builtin.file:
        path: "{{ temp_dir }}"
        state: directory
        mode: "0700"

    - name: Test CRL distribution endpoint availability
      ansible.builtin.uri:
        url: "https://{{ pki_domain }}/crl/intermediate.crl"
        method: HEAD
        status_code: [200, 304]
      register: crl_endpoint
      changed_when: false

    - name: Download current CRL
      ansible.builtin.get_url:
        url: "https://{{ pki_domain }}/crl/intermediate.crl"
        dest: "{{ temp_dir }}/current.crl"
        mode: "0644"
      changed_when: false

    - name: Verify CRL format and content
      ansible.builtin.command:
        cmd: openssl crl -in {{ temp_dir }}/current.crl -inform DER -text -noout
      register: crl_content
      changed_when: false
      failed_when: "'Certificate Revocation List' not in crl_content.stdout"

    - name: Test OCSP responder availability
      ansible.builtin.uri:
        url: "https://{{ ocsp_domain }}/health"
        method: GET
        status_code: 200
      register: ocsp_health
      changed_when: false
      ignore_errors: true

    - name: Issue test certificate for revocation
      community.hashi_vault.vault_write:
        path: pki-int/issue/test
        data:
          common_name: "{{ test_cert_cn }}"
          ttl: "1h"
      register: test_cert_issue
      changed_when: false

    - name: Save test certificate to file
      ansible.builtin.copy:
        content: "{{ test_cert_issue.data.data.certificate }}"
        dest: "{{ temp_dir }}/test-cert.pem"
        mode: "0644"
      changed_when: false

    - name: Save test certificate private key
      ansible.builtin.copy:
        content: "{{ test_cert_issue.data.data.private_key }}"
        dest: "{{ temp_dir }}/test-key.pem"
        mode: "0600"
      changed_when: false

    - name: Save CA certificate
      community.hashi_vault.vault_read:
        path: pki-int/cert/ca
      register: ca_cert
      changed_when: false

    - name: Save CA certificate to file
      ansible.builtin.copy:
        content: "{{ ca_cert.data.data.certificate }}"
        dest: "{{ temp_dir }}/ca.pem"
        mode: "0644"
      changed_when: false

    - name: Test OCSP query for valid certificate (if OCSP available)
      ansible.builtin.command:
        cmd: openssl ocsp -CAfile {{ temp_dir }}/ca.pem -url https://{{ ocsp_domain }} -issuer {{ temp_dir }}/ca.pem -cert {{ temp_dir }}/test-cert.pem -resp_text
      register: ocsp_valid_check
      changed_when: false
      failed_when: false
      when: ocsp_health is succeeded

    - name: Extract certificate serial number
      ansible.builtin.shell:
        cmd: openssl x509 -serial -noout -in {{ temp_dir }}/test-cert.pem | cut -d= -f2
      register: cert_serial
      changed_when: false

    - name: Revoke test certificate
      community.hashi_vault.vault_write:
        path: pki-int/revoke
        data:
          serial_number: "{{ cert_serial.stdout }}"
          revocation_reason: "keyCompromise"
      register: cert_revocation
      changed_when: false

    - name: Force CRL regeneration
      community.hashi_vault.vault_read:
        path: pki-int/cert/crl
      register: updated_crl
      changed_when: false

    - name: Save updated CRL
      ansible.builtin.copy:
        content: "{{ updated_crl.data.data.certificate }}"
        dest: "{{ temp_dir }}/updated.crl"
        mode: "0644"
      changed_when: false

    - name: Verify revocation in updated CRL
      ansible.builtin.command:
        cmd: openssl crl -in {{ temp_dir }}/updated.crl -text -noout
      register: crl_revoked_check
      changed_when: false
      failed_when: "cert_serial.stdout not in crl_revoked_check.stdout"

    - name: Test OCSP query for revoked certificate (if OCSP available)
      ansible.builtin.command:
        cmd: openssl ocsp -CAfile {{ temp_dir }}/ca.pem -url https://{{ ocsp_domain }} -issuer {{ temp_dir }}/ca.pem -cert {{ temp_dir }}/test-cert.pem -resp_text
      register: ocsp_revoked_check
      changed_when: false
      failed_when: false
      when: ocsp_health is succeeded

    - name: Test certificate status checker script
      ansible.builtin.command:
        cmd: /usr/local/bin/check-cert-status {{ temp_dir }}/test-cert.pem
      register: status_check
      changed_when: false
      ignore_errors: true

    - name: Verify CRL distribution point in certificate
      ansible.builtin.command:
        cmd: openssl x509 -in {{ temp_dir }}/test-cert.pem -text -noout
      register: cert_details
      changed_when: false
      failed_when: "'{{ pki_domain }}' not in cert_details.stdout"

    - name: Test emergency revocation script exists and is executable
      ansible.builtin.stat:
        path: /usr/local/bin/emergency-ca-revoke
      register: emergency_script
      failed_when: not emergency_script.stat.exists or not emergency_script.stat.executable

    - name: Verify revocation audit logging
      ansible.builtin.stat:
        path: /var/log/cert-revocations.log
      register: audit_log
      ignore_errors: true

    - name: Clean up test files
      ansible.builtin.file:
        path: "{{ temp_dir }}"
        state: absent
      changed_when: false

    - name: Display validation results
      ansible.builtin.debug:
        msg:
          - "CRL endpoint accessible: {{ crl_endpoint.status == 200 }}"
          - "CRL format valid: {{ 'Certificate Revocation List' in crl_content.stdout }}"
          - "OCSP responder available: {{ ocsp_health.status == 200 if ocsp_health is not skipped else 'Not tested' }}"
          - "Test certificate issued: {{ test_cert_issue is succeeded }}"
          - "Certificate revoked: {{ cert_revocation is succeeded }}"
          - "Revocation in CRL: {{ cert_serial.stdout in crl_revoked_check.stdout }}"
          - "OCSP shows revoked: {{ 'revoked' in (ocsp_revoked_check.stdout | lower) if ocsp_revoked_check is not skipped else 'Not tested' }}"
          - "Status checker working: {{ status_check.rc == 0 if status_check is not skipped else 'Script not found' }}"
          - "Emergency script exists: {{ emergency_script.stat.exists }}"
          - "Audit logging enabled: {{ audit_log.stat.exists if audit_log is not skipped else 'Log file not found' }}"
          - "Certificate serial revoked: {{ cert_serial.stdout }}"
```

## Notes

- CRL should be refreshed before expiry (typically every 6-12 hours)
- OCSP provides real-time revocation status
- Keep revocation reasons accurate for audit purposes
- Emergency procedures should be tested quarterly
- Consider Delta CRLs for large deployments
