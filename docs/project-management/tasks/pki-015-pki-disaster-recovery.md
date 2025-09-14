---
Task: Implement PKI Disaster Recovery
Task ID: PKI-015
Parent Issue: 100 - Certificate Rotation and Distribution
Priority: P0 - Critical
Estimated Time: 4 hours
Dependencies: PKI-001 through PKI-006
Status: Ready
---

## Objective

Establish comprehensive disaster recovery procedures for the PKI infrastructure, including automated backups, recovery testing, and CA compromise response plans.

## Prerequisites

- [ ] Backup infrastructure available (storage, scheduling)
- [ ] Offline storage for root CA backup
- [ ] Test environment for recovery validation
- [ ] Documentation of all PKI dependencies

## Implementation Steps

1. **Implement Automated PKI Backup**

   ```yaml
   - name: Create PKI backup script
     ansible.builtin.copy:
       dest: /usr/local/bin/backup-pki.sh
       mode: "0700"
       owner: root
       content: |
         #!/bin/bash
         set -euo pipefail

         BACKUP_DIR="/var/backups/pki"
         TIMESTAMP=$(date +%Y%m%d-%H%M%S)
         BACKUP_PATH="${BACKUP_DIR}/${TIMESTAMP}"

         # Create backup directory
         mkdir -p "${BACKUP_PATH}"

         # Backup Vault PKI configuration
         echo "Backing up PKI configuration..."
         for mount in pki pki-int pki-int-connect; do
           mkdir -p "${BACKUP_PATH}/${mount}"

           # Export CA certificates
           vault read -format=json ${mount}/cert/ca > \
             "${BACKUP_PATH}/${mount}/ca.json" 2>/dev/null || true

           # Export CA chain
           vault read -format=json ${mount}/cert/ca-chain > \
             "${BACKUP_PATH}/${mount}/ca-chain.json" 2>/dev/null || true

           # Export CRL
           vault read -format=json ${mount}/cert/crl > \
             "${BACKUP_PATH}/${mount}/crl.json" 2>/dev/null || true

           # Export roles
           for role in $(vault list -format=json ${mount}/roles 2>/dev/null | jq -r '.[]' || true); do
             vault read -format=json ${mount}/roles/${role} > \
               "${BACKUP_PATH}/${mount}/role-${role}.json"
           done

           # Export configuration
           vault read -format=json ${mount}/config/urls > \
             "${BACKUP_PATH}/${mount}/config-urls.json" 2>/dev/null || true
         done

         # Backup critical metadata
         cat > "${BACKUP_PATH}/metadata.json" << EOF
         {
           "timestamp": "${TIMESTAMP}",
           "vault_version": "$(vault version | head -1)",
           "backup_host": "$(hostname -f)",
           "backup_user": "${USER}",
           "checksum": ""
         }
         EOF

         # Generate checksums
         find "${BACKUP_PATH}" -type f -exec sha256sum {} \; > \
           "${BACKUP_PATH}/checksums.sha256"

         # Compress backup
         tar czf "${BACKUP_PATH}.tar.gz" -C "${BACKUP_DIR}" "${TIMESTAMP}"

         # Encrypt backup
         openssl enc -aes-256-cbc -salt \
           -in "${BACKUP_PATH}.tar.gz" \
           -out "${BACKUP_PATH}.tar.gz.enc" \
           -pass file:/etc/pki-backup.key

         # Upload to offsite storage
         aws s3 cp "${BACKUP_PATH}.tar.gz.enc" \
           s3://backup-bucket/pki/${TIMESTAMP}.tar.gz.enc \
           --storage-class GLACIER

         # Clean up local files
         rm -rf "${BACKUP_PATH}" "${BACKUP_PATH}.tar.gz"

         # Keep only last 7 days locally
         find "${BACKUP_DIR}" -name "*.tar.gz.enc" -mtime +7 -delete

         echo "Backup completed: ${TIMESTAMP}"

   - name: Schedule PKI backups
     ansible.builtin.cron:
       name: "PKI backup"
       minute: "0"
       hour: "2,14" # Twice daily
       job: "/usr/local/bin/backup-pki.sh"
       user: root
   ```

2. **Create Recovery Procedures**

   ```yaml
   - name: Deploy PKI recovery script
     ansible.builtin.copy:
       dest: /usr/local/bin/recover-pki.sh
       mode: "0700"
       owner: root
       content: |
         #!/bin/bash
         set -euo pipefail

         BACKUP_FILE=$1

         if [[ ! -f "$BACKUP_FILE" ]]; then
           echo "Backup file not found: $BACKUP_FILE"
           exit 1
         fi

         # Create recovery directory
         RECOVERY_DIR="/var/recovery/pki-$(date +%Y%m%d-%H%M%S)"
         mkdir -p "$RECOVERY_DIR"

         # Decrypt backup
         openssl enc -aes-256-cbc -d \
           -in "$BACKUP_FILE" \
           -out "${RECOVERY_DIR}/backup.tar.gz" \
           -pass file:/etc/pki-backup.key

         # Extract backup
         tar xzf "${RECOVERY_DIR}/backup.tar.gz" -C "$RECOVERY_DIR"

         # Verify checksums
         BACKUP_NAME=$(basename "$BACKUP_FILE" .tar.gz.enc)
         cd "${RECOVERY_DIR}/${BACKUP_NAME}"
         sha256sum -c checksums.sha256 || {
           echo "Checksum verification failed!"
           exit 1
         }

         # Restore PKI mounts
         for mount in pki pki-int pki-int-connect; do
           if [[ -d "${mount}" ]]; then
             echo "Restoring ${mount}..."

             # Disable if exists, then re-enable
             vault secrets disable ${mount} 2>/dev/null || true
             vault secrets enable -path=${mount} pki

             # Restore CA certificate
             if [[ -f "${mount}/ca.json" ]]; then
               # For root CA, we need to import
               if [[ "$mount" == "pki" ]]; then
                 cert=$(jq -r '.data.certificate' ${mount}/ca.json)
                 key=$(jq -r '.data.private_key' ${mount}/ca.json)

                 vault write ${mount}/config/ca \
                   pem_bundle="${cert}\n${key}"
               fi
             fi

             # Restore roles
             for role_file in ${mount}/role-*.json; do
               if [[ -f "$role_file" ]]; then
                 role_name=$(basename "$role_file" .json | sed 's/role-//')
                 jq -r '.data' "$role_file" | \
                   vault write ${mount}/roles/${role_name} -
               fi
             done

             # Restore URLs configuration
             if [[ -f "${mount}/config-urls.json" ]]; then
               jq -r '.data' "${mount}/config-urls.json" | \
                 vault write ${mount}/config/urls -
             fi
           fi
         done

         echo "Recovery completed. Verify with: vault secrets list"

   - name: Create recovery validation playbook
     ansible.builtin.copy:
       dest: /opt/ansible/playbooks/validate-pki-recovery.yml
       content: |
         ---
         - name: Validate PKI Recovery
           hosts: localhost
           tasks:
             - name: Check PKI mounts
               community.hashi_vault.vault_read:
                 path: sys/mounts
               register: mounts

             - name: Verify PKI mounts exist
               ansible.builtin.assert:
                 that:
                   - "'pki/' in mounts.data.data"
                   - "'pki-int/' in mounts.data.data"
                 fail_msg: "Required PKI mounts not found"

             - name: Test certificate issuance
               community.hashi_vault.vault_pki_generate_certificate:
                 role_name: test
                 common_name: "test-recovery.spaceships.work"
                 mount_point: pki-int
               register: test_cert

             - name: Verify certificate valid
               ansible.builtin.assert:
                 that:
                   - test_cert.data.certificate is defined
                   - test_cert.data.private_key is defined
   ```

3. **Implement CA Compromise Response**

   ```yaml
   - name: Create CA compromise response plan
     ansible.builtin.copy:
       dest: /usr/local/bin/ca-compromise-response.sh
       mode: "0700"
       owner: root
       content: |
         #!/bin/bash
         set -euo pipefail

         echo "=== CA COMPROMISE RESPONSE INITIATED ==="
         echo "Time: $(date)"
         echo "Operator: ${USER}"

         # Step 1: Immediate containment
         echo "Step 1: Disabling PKI mounts..."
         vault secrets disable pki-int
         vault secrets disable pki-int-connect

         # Step 2: Revoke compromised CA
         echo "Step 2: Revoking intermediate CA..."
         vault write pki/root/revoke \
           serial_number="${COMPROMISED_CA_SERIAL}"

         # Step 3: Generate new intermediate CA
         echo "Step 3: Generating new intermediate CA..."
         vault secrets enable -path=pki-int-new pki
         vault secrets tune -max-lease-ttl=43800h pki-int-new

         vault write -format=json pki-int-new/intermediate/generate/internal \
           common_name="HomeLab Intermediate CA (Emergency)" \
           | jq -r '.data.csr' > /tmp/pki_intermediate_new.csr

         vault write -format=json pki/root/sign-intermediate \
           csr=@/tmp/pki_intermediate_new.csr \
           format=pem_bundle ttl="43800h" \
           | jq -r '.data.certificate' > /tmp/intermediate_new.cert.pem

         vault write pki-int-new/intermediate/set-signed \
           certificate=@/tmp/intermediate_new.cert.pem

         # Step 4: Recreate roles
         echo "Step 4: Recreating PKI roles..."
         for role in consul-agent nomad-agent vault-agent client-auth; do
           vault write pki-int-new/roles/${role} \
             allowed_domains="*.spaceships.work" \
             allow_subdomains=true \
             max_ttl="720h"
         done

         # Step 5: Update CRL distribution
         echo "Step 5: Publishing revocation..."
         vault read -format=pem pki/cert/crl > /var/www/pki/crl/root.crl
         vault read -format=pem pki-int-new/cert/crl > /var/www/pki/crl/intermediate.crl

         # Step 6: Trigger certificate renewal
         echo "Step 6: Triggering mass certificate renewal..."
         consul event -name=ca-compromised
         ansible-playbook /opt/ansible/playbooks/emergency-cert-renewal.yml

         echo "=== RESPONSE COMPLETE ==="
         echo "Next steps:"
         echo "1. Monitor certificate renewal progress"
         echo "2. Update all systems to trust new CA"
         echo "3. Investigate compromise source"
         echo "4. File incident report"

   - name: Create incident response checklist
     ansible.builtin.copy:
       dest: /opt/pki/INCIDENT_RESPONSE.md
       content: |
         # PKI Incident Response Checklist

         ## Immediate Actions (< 5 minutes)
         - [ ] Isolate affected systems
         - [ ] Disable compromised CA in Vault
         - [ ] Notify security team
         - [ ] Start incident log

         ## Containment (< 30 minutes)
         - [ ] Revoke compromised certificates
         - [ ] Update CRL and OCSP
         - [ ] Block network access if needed
         - [ ] Enable enhanced monitoring

         ## Recovery (< 2 hours)
         - [ ] Generate new CA certificates
         - [ ] Update all trust stores
         - [ ] Reissue all certificates
         - [ ] Verify service connectivity

         ## Post-Incident (< 24 hours)
         - [ ] Root cause analysis
         - [ ] Update security controls
         - [ ] Document lessons learned
         - [ ] Test improved procedures
   ```

4. **Implement Backup Verification**

   ```yaml
   - name: Deploy backup verification script
     ansible.builtin.copy:
       dest: /usr/local/bin/verify-pki-backup.sh
       mode: "0755"
       content: |
         #!/bin/bash
         set -euo pipefail

         # Get latest backup
         LATEST_BACKUP=$(ls -t /var/backups/pki/*.tar.gz.enc 2>/dev/null | head -1)

         if [[ -z "$LATEST_BACKUP" ]]; then
           echo "No backups found"
           exit 1
         fi

         echo "Verifying backup: $LATEST_BACKUP"

         # Test decryption
         TEMP_DIR=$(mktemp -d)
         openssl enc -aes-256-cbc -d \
           -in "$LATEST_BACKUP" \
           -out "${TEMP_DIR}/test.tar.gz" \
           -pass file:/etc/pki-backup.key || {
             echo "Decryption failed"
             rm -rf "$TEMP_DIR"
             exit 1
           }

         # Test extraction
         tar tzf "${TEMP_DIR}/test.tar.gz" > /dev/null || {
           echo "Archive corrupted"
           rm -rf "$TEMP_DIR"
           exit 1
         }

         # Extract and verify structure
         tar xzf "${TEMP_DIR}/test.tar.gz" -C "$TEMP_DIR"

         # Check for critical files
         BACKUP_NAME=$(ls "$TEMP_DIR" | grep -v test.tar.gz | head -1)
         for file in \
           "${TEMP_DIR}/${BACKUP_NAME}/metadata.json" \
           "${TEMP_DIR}/${BACKUP_NAME}/checksums.sha256" \
           "${TEMP_DIR}/${BACKUP_NAME}/pki/ca.json"; do
           if [[ ! -f "$file" ]]; then
             echo "Missing critical file: $file"
             rm -rf "$TEMP_DIR"
             exit 1
           fi
         done

         # Verify checksums
         cd "${TEMP_DIR}/${BACKUP_NAME}"
         sha256sum -c checksums.sha256 || {
           echo "Checksum verification failed"
           rm -rf "$TEMP_DIR"
           exit 1
         }

         # Clean up
         rm -rf "$TEMP_DIR"

         echo "Backup verification successful"

         # Test recovery in sandbox
         if [[ "${1:-}" == "--test-recovery" ]]; then
           echo "Testing recovery in sandbox..."
           docker run --rm -v "$LATEST_BACKUP:/backup.enc:ro" \
             -v /etc/pki-backup.key:/etc/pki-backup.key:ro \
             vault:latest \
             /usr/local/bin/recover-pki.sh /backup.enc
         fi

   - name: Schedule backup verification
     ansible.builtin.cron:
       name: "PKI backup verification"
       minute: "30"
       hour: "3"
       weekday: "0" # Weekly on Sunday
       job: "/usr/local/bin/verify-pki-backup.sh"
       user: root
   ```

5. **Create DR Testing Procedures**

   ```yaml
   - name: Deploy DR test playbook
     ansible.builtin.copy:
       dest: /opt/ansible/playbooks/test-pki-dr.yml
       content: |
         ---
         - name: PKI Disaster Recovery Test
           hosts: dr-test-env
           vars:
             test_timestamp: "{{ ansible_date_time.epoch }}"

           tasks:
             - name: Create test environment
               ansible.builtin.docker_container:
                 name: "vault-dr-test-{{ test_timestamp }}"
                 image: vault:latest
                 state: started
                 env:
                   VAULT_DEV_ROOT_TOKEN_ID: "test-root"
                   VAULT_DEV_LISTEN_ADDRESS: "0.0.0.0:8200"

             - name: Wait for Vault to start
               ansible.builtin.wait_for:
                 port: 8200
                 host: localhost
                 delay: 5

             - name: Restore backup to test environment
               ansible.builtin.command:
                 cmd: >
                   docker exec vault-dr-test-{{ test_timestamp }}
                   /usr/local/bin/recover-pki.sh /backup.enc

             - name: Validate recovery
               ansible.builtin.uri:
                 url: "http://localhost:8200/v1/pki-int/ca/pem"
                 headers:
                   X-Vault-Token: "test-root"
               register: ca_test

             - name: Test certificate issuance
               ansible.builtin.uri:
                 url: "http://localhost:8200/v1/pki-int/issue/test"
                 method: POST
                 headers:
                   X-Vault-Token: "test-root"
                 body_format: json
                 body:
                   common_name: "dr-test.spaceships.work"
               register: cert_test

             - name: Verify certificate issued
               ansible.builtin.assert:
                 that:
                   - cert_test.json.data.certificate is defined
                   - cert_test.json.data.private_key is defined

             - name: Clean up test environment
               ansible.builtin.docker_container:
                 name: "vault-dr-test-{{ test_timestamp }}"
                 state: absent

             - name: Generate DR test report
               ansible.builtin.template:
                 src: dr-test-report.j2
                 dest: "/var/log/pki-dr-test-{{ test_timestamp }}.log"
   ```

## Success Criteria

- [ ] Automated backups running twice daily
- [ ] Backups encrypted and stored offsite
- [ ] Recovery procedures tested successfully
- [ ] CA compromise response plan validated
- [ ] Backup verification automated
- [ ] DR testing completed quarterly

## Validation

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-pki-disaster-recovery.yml
```

Validation playbook performs:

```yaml
---
- name: Validate PKI Disaster Recovery
  hosts: localhost
  tasks:
    - name: Run manual backup
      ansible.builtin.command:
        cmd: /usr/local/bin/backup-pki.sh
      register: backup_result
      changed_when: false

    - name: Verify backup files exist
      ansible.builtin.find:
        paths: /var/backups/pki
        patterns: "*.tar.gz.enc"
      register: backup_files

    - name: Assert backup files found
      ansible.builtin.assert:
        that:
          - backup_files.files | length > 0
        fail_msg: "No backup files found in /var/backups/pki"

    - name: Test backup verification
      ansible.builtin.command:
        cmd: /usr/local/bin/verify-pki-backup.sh
      register: verify_result
      changed_when: false

    - name: Assert backup verification passed
      ansible.builtin.assert:
        that:
          - verify_result.rc == 0
          - "'verification successful' in verify_result.stdout"
        fail_msg: "Backup verification failed: {{ verify_result.stderr }}"

    - name: Test recovery in sandbox
      ansible.builtin.command:
        cmd: /usr/local/bin/verify-pki-backup.sh --test-recovery
      register: recovery_test
      changed_when: false
      ignore_errors: true

    - name: Display recovery test results
      ansible.builtin.debug:
        msg: "Recovery test result: {{ recovery_test.stdout }}"

    - name: Run DR test playbook
      ansible.builtin.include:
        file: /opt/ansible/playbooks/test-pki-dr.yml
      when: ansible_env.ENABLE_DR_TESTING is defined

    - name: Check S3 backup status
      amazon.aws.s3_object_info:
        bucket_name: backup-bucket
        object_name: pki/
      register: s3_backups
      when: ansible_env.AWS_ACCESS_KEY_ID is defined

    - name: Display S3 backup count
      ansible.builtin.debug:
        msg: "S3 backup files found: {{ s3_backups.s3_keys | length if s3_backups.s3_keys is defined else 'N/A (AWS not configured)' }}"

    - name: Verify disaster recovery procedures document
      ansible.builtin.stat:
        path: /opt/pki/INCIDENT_RESPONSE.md
      register: incident_doc

    - name: Assert incident response document exists
      ansible.builtin.assert:
        that:
          - incident_doc.stat.exists
        fail_msg: "Incident response document not found"

    - name: Test CA compromise response script exists
      ansible.builtin.stat:
        path: /usr/local/bin/ca-compromise-response.sh
      register: response_script

    - name: Assert CA compromise response script exists
      ansible.builtin.assert:
        that:
          - response_script.stat.exists
          - response_script.stat.executable
        fail_msg: "CA compromise response script missing or not executable"
```

## Notes

- Test recovery procedures quarterly minimum
- Keep offline backup of root CA private key
- Document all personnel with recovery access
- Consider geographic distribution of backups
- Maintain air-gapped backup for critical scenarios
