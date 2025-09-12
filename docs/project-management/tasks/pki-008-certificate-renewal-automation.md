# Task: Implement Automated Certificate Renewal

**Task ID**: PKI-008
**Parent Issue**: #100 (Certificate Rotation and Distribution)
**Priority**: P0 - Critical
**Estimated Time**: 4 hours
**Dependencies**: PKI-007 (Monitoring must be in place)

## Objective

Implement automated certificate renewal that triggers 30 days before expiration, requests new certificates from Vault, and safely replaces existing certificates without service disruption.

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
       mode: '0700'

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
           mode: '0644'
           backup: yes

       - name: Write new private key
         ansible.builtin.copy:
           content: "{{ new_cert.data.private_key }}"
           dest: "{{ cert_path | replace('.crt', '.key') }}"
           owner: "{{ service_name }}"
           group: "{{ service_name }}"
           mode: '0600'
           backup: yes

       - name: Update CA bundle if needed
         ansible.builtin.copy:
           content: "{{ new_cert.data.ca_chain }}"
           dest: "{{ cert_path | replace(service_name + '.crt', 'ca-bundle.crt') }}"
           owner: "{{ service_name }}"
           group: "{{ service_name }}"
           mode: '0644'
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
       mode: '0755'
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
       mode: '0755'
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

## Validation

```bash
# Check renewal timer status
systemctl status cert-renewal.timer

# View renewal service logs
journalctl -u cert-renewal.service -n 50

# Test manual renewal (dry-run)
ansible-playbook /opt/ansible/playbooks/infrastructure/vault/renew-certificates.yml --check

# Check renewal status
/usr/local/bin/cert-renewal-status

# Verify backups
ls -la /opt/certificate-backups/
```

## Notes

- Renewal checks run daily at 2 AM with random delay
- Certificates renewed 30 days before expiration
- Each renewal creates timestamped backup
- Service reload performed after successful renewal
- Failed renewals trigger alerts (configured in PKI-011)
