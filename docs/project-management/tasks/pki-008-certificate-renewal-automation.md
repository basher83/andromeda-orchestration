---
Task: Implement Automated Certificate Renewal
Task ID: PKI-008
Parent Issue: 100 - Certificate Rotation and Distribution
Priority: P0 - Critical
Estimated Time: 4 hours
Dependencies: PKI-007 (Monitoring must be in place)
Status: Ready
---

## Objective

Create an Ansible playbook that implements automated certificate renewal, triggering 30 days before expiration, requesting new certificates from Vault, and safely replacing existing certificates without service disruption. This includes systemd timers, renewal scripts, and validation mechanisms.

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/certificate-renewal-automation.yml
- Create: playbooks/infrastructure/vault/validate-certificate-renewal.yml
- Create: playbooks/infrastructure/vault/tasks/renew-single-certificate.yml
- Create: /etc/systemd/system/cert-renewal.timer (via playbook)
- Create: /etc/systemd/system/cert-renewal.service (via playbook)
- Create: /usr/local/bin/renew-cert (via playbook)

## Reference Implementations

- Pattern example: playbooks/infrastructure/vault/automated-certificate-renewal.yml
- Validation pattern: playbooks/infrastructure/vault/smoke-test.yml
- Similar task: playbooks/infrastructure/vault/deploy-tls-certificates.yml

## Dependencies

- PKI-007: Provides certificate monitoring that this task needs to determine renewal timing
- Existing: Vault PKI roles and authentication mechanisms for certificate issuance
- Existing: Service configuration and reload capabilities for certificate updates

## Prerequisites

- [ ] Certificate monitoring operational (PKI-007)
- [ ] Vault PKI roles configured
- [ ] Service reload handlers prepared
- [ ] Backup strategy defined

## Implementation Steps

1. **Create Certificate Renewal Playbook**

   ```yaml
   # playbooks/infrastructure/vault/renew-certificates.yml
   ---
   - name: Automated Certificate Renewal
     hosts: all
     vars:
       renewal_threshold_days: 30
       backup_dir: /opt/certificate-backups

     tasks:
       - name: Check certificate expiration
         community.crypto.x509_certificate_info:
           path: "{{ item }}"
         register: cert_info
         loop:
           - /opt/consul/tls/consul.crt
           - /opt/nomad/tls/nomad.crt
           - /opt/vault/tls/vault.crt
         when: item is exists

       - name: Determine certificates needing renewal
         ansible.builtin.set_fact:
           certs_to_renew: >-
             {{ cert_info.results |
                selectattr('not_after', 'defined') |
                selectattr('not_after', '<', (ansible_date_time.epoch | int + (renewal_threshold_days * 86400)) | string) |
                list }}

       - name: Renew certificates
         include_tasks: renew-single-certificate.yml
         vars:
           cert_path: "{{ item.item }}"
           service_name: "{{ item.item | regex_replace('.*/opt/(.*)/tls/.*', '\\1') }}"
         loop: "{{ certs_to_renew }}"
         when: certs_to_renew | length > 0
   ```

2. **Create Single Certificate Renewal Task**

   ```yaml
   # playbooks/infrastructure/vault/tasks/renew-single-certificate.yml
   ---
   - name: Create backup directory
     ansible.builtin.file:
       path: "{{ backup_dir }}/{{ service_name }}/{{ ansible_date_time.date }}"
       state: directory
       mode: "0700"

   - name: Backup existing certificate
     ansible.builtin.copy:
       src: "{{ cert_path }}"
       dest: "{{ backup_dir }}/{{ service_name }}/{{ ansible_date_time.date }}/"
       remote_src: yes
       backup: yes

   - name: Generate new certificate from Vault
     community.hashi_vault.vault_pki_generate_certificate:
       role_name: "{{ service_name }}-agent"
       common_name: "{{ inventory_hostname }}.{{ service_name }}.spaceships.work"
       alt_names:
         - "{{ service_name }}.service.consul"
         - "{{ inventory_hostname }}"
       ip_sans:
         - "{{ ansible_default_ipv4.address }}"
         - "127.0.0.1"
       ttl: "720h"
     register: new_cert

   - name: Validate new certificate
     community.crypto.x509_certificate:
       path: /tmp/new_cert.pem
       content: "{{ new_cert.data.certificate }}"
       provider: assertonly
       has_expired: no
       valid_at: "+30d"
     register: cert_valid

   - name: Deploy new certificate
     block:
       - name: Write new certificate
         ansible.builtin.copy:
           content: "{{ new_cert.data.certificate }}"
           dest: "{{ cert_path }}"
           owner: "{{ service_name }}"
           group: "{{ service_name }}"
           mode: "0644"
           backup: yes

       - name: Write new private key
         ansible.builtin.copy:
           content: "{{ new_cert.data.private_key }}"
           dest: "{{ cert_path | replace('.crt', '.key') }}"
           owner: "{{ service_name }}"
           group: "{{ service_name }}"
           mode: "0600"
           backup: yes

       - name: Update CA bundle if needed
         ansible.builtin.copy:
           content: "{{ new_cert.data.ca_chain }}"
           dest: "{{ cert_path | replace(service_name + '.crt', 'ca-bundle.crt') }}"
           owner: "{{ service_name }}"
           group: "{{ service_name }}"
           mode: "0644"
         when: new_cert.data.ca_chain is defined
     when: cert_valid is succeeded

   - name: Reload service
     ansible.builtin.systemd:
       name: "{{ service_name }}"
       state: reloaded
     register: service_reload

   - name: Verify service health after reload
     ansible.builtin.uri:
       url: "https://localhost:{{ service_ports[service_name] }}/health"
       client_cert: "{{ cert_path }}"
       client_key: "{{ cert_path | replace('.crt', '.key') }}"
       validate_certs: yes
     retries: 3
     delay: 5
     vars:
       service_ports:
         consul: 8501
         nomad: 4646
         vault: 8200
   ```

3. **Create Renewal Scheduler**

   ```yaml
   - name: Deploy certificate renewal timer
     ansible.builtin.copy:
       dest: /etc/systemd/system/cert-renewal.timer
       content: |
         [Unit]
         Description=Daily Certificate Renewal Check
         Requires=cert-renewal.service

         [Timer]
         OnCalendar=daily
         OnCalendar=*-*-* 02:00:00
         RandomizedDelaySec=1h
         Persistent=true

         [Install]
         WantedBy=timers.target

   - name: Deploy certificate renewal service
     ansible.builtin.copy:
       dest: /etc/systemd/system/cert-renewal.service
       content: |
         [Unit]
         Description=Certificate Renewal Service
         After=network.target

         [Service]
         Type=oneshot
         User=root
         ExecStart=/usr/local/bin/ansible-playbook \
           -i /etc/ansible/hosts \
           /opt/ansible/playbooks/infrastructure/vault/renew-certificates.yml \
           --limit localhost
         StandardOutput=journal
         StandardError=journal

   - name: Enable and start renewal timer
     ansible.builtin.systemd:
       name: cert-renewal.timer
       state: started
       enabled: yes
       daemon_reload: yes
   ```

4. **Implement Manual Renewal Command**

   ```yaml
   - name: Create manual renewal script
     ansible.builtin.copy:
       dest: /usr/local/bin/renew-cert
       mode: "0755"
       content: |
         #!/bin/bash
         set -e

         SERVICE=$1
         FORCE=${2:-false}

         if [[ -z "$SERVICE" ]]; then
           echo "Usage: renew-cert <service> [force]"
           echo "Services: consul, nomad, vault, all"
           exit 1
         fi

         if [[ "$SERVICE" == "all" ]]; then
           ansible-playbook /opt/ansible/playbooks/infrastructure/vault/renew-certificates.yml
         else
           ansible-playbook /opt/ansible/playbooks/infrastructure/vault/renew-certificates.yml \
             --extra-vars "target_service=$SERVICE force_renewal=$FORCE"
         fi
   ```

5. **Create Renewal Status Dashboard**

   ```yaml
   - name: Deploy renewal status script
     ansible.builtin.copy:
       dest: /usr/local/bin/cert-renewal-status
       mode: "0755"
       content: |
         #!/bin/bash

         echo "=== Certificate Renewal Status ==="
         echo "Last check: $(systemctl show cert-renewal.service -p ActiveExitTimestamp --value)"
         echo "Next scheduled: $(systemctl show cert-renewal.timer -p NextElapseUSecRealtime --value)"
         echo ""
         echo "Recent renewals:"
         journalctl -u cert-renewal.service --since "7 days ago" | grep "Certificate renewed"
         echo ""
         echo "Upcoming expirations:"
         for cert in /opt/*/tls/*.crt; do
           days_left=$(( ($(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2 | xargs -I {} date -d {} +%s) - $(date +%s)) / 86400 ))
           if [[ $days_left -lt 45 ]]; then
             echo "  $(basename $cert): $days_left days remaining"
           fi
         done
   ```

## Success Criteria

- [ ] Automated renewal triggers 30 days before expiry
- [ ] Certificates renewed without service interruption
- [ ] Backup created before each renewal
- [ ] Service health verified after renewal
- [ ] Manual renewal command available
- [ ] Renewal status easily accessible
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/certificate-renewal-automation.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/certificate-renewal-automation.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-certificate-renewal.yml
```

The validation playbook performs these checks:

```yaml
# playbooks/infrastructure/vault/validate-certificate-renewal.yml
---
- name: Validate Certificate Renewal Automation
  hosts: all
  tasks:
    - name: Check renewal timer status
      ansible.builtin.systemd:
        name: cert-renewal.timer
      register: timer_status
      changed_when: false

    - name: Assert timer is enabled and active
      ansible.builtin.assert:
        that:
          - timer_status.status.ActiveState == "active"
          - timer_status.status.UnitFileState == "enabled"
        fail_msg: "Certificate renewal timer is not properly configured"

    - name: Check renewal service logs
      ansible.builtin.shell: |
        journalctl -u cert-renewal.service -n 10 --no-pager
      register: service_logs
      changed_when: false

    - name: Test renewal playbook (dry-run)
      ansible.builtin.command: |
        uv run ansible-playbook playbooks/infrastructure/vault/renew-certificates.yml --check
      register: dry_run_result
      changed_when: false
      failed_when: dry_run_result.rc != 0

    - name: Check certificate backup directory
      ansible.builtin.stat:
        path: /opt/certificate-backups
      register: backup_dir

    - name: Assert backup directory exists and is accessible
      ansible.builtin.assert:
        that:
          - backup_dir.stat.exists
          - backup_dir.stat.isdir
          - backup_dir.stat.mode == "0700"
        fail_msg: "Certificate backup directory not properly configured"

    - name: Check renewal status script
      ansible.builtin.stat:
        path: /usr/local/bin/cert-renewal-status
      register: status_script

    - name: Assert renewal status script is available
      ansible.builtin.assert:
        that:
          - status_script.stat.exists
          - status_script.stat.executable
        fail_msg: "Certificate renewal status script not available"

    - name: Validate certificate expiration monitoring
      ansible.builtin.shell: |
        for cert in /opt/*/tls/*.crt; do
          if [[ -f "$cert" ]]; then
            days_left=$(( ($(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2 | xargs -I {} date -d {} +%s) - $(date +%s)) / 86400 ))
            echo "$(basename $cert): $days_left days remaining"
          fi
        done
      register: cert_expiry_check
      changed_when: false

    - name: Display validation results
      ansible.builtin.debug:
        msg: |
          === Certificate Renewal Validation Results ===
          Timer Status: {{ timer_status.status.ActiveState }}
          Service Logs: Available ({{ service_logs.stdout_lines | length }} lines)
          Dry Run: {{ 'PASSED' if dry_run_result.rc == 0 else 'FAILED' }}
          Backup Directory: {{ 'OK' if backup_dir.stat.exists else 'MISSING' }}
          Status Script: {{ 'OK' if status_script.stat.exists else 'MISSING' }}

          Certificate Expiry Status:
          {{ cert_expiry_check.stdout }}
```

## Notes

- Renewal checks run daily at 2 AM with random delay
- Certificates renewed 30 days before expiration
- Each renewal creates timestamped backup
- Service reload performed after successful renewal
- Failed renewals trigger alerts (configured in PKI-011)
