---
Task: Implement Certificate Expiration Monitoring
Task ID: PKI-007
Parent Issue: 100 - Certificate Rotation and Distribution
Priority: P0 - Critical
Estimated Time: 3 hours
Dependencies: PKI-001 through PKI-004
Status: Ready
---

## Objective

Create an Ansible playbook that deploys comprehensive certificate expiration monitoring to track all certificates across the infrastructure and provide early warning before expiration. This includes monitoring scripts, Consul health checks, and Prometheus exporters.

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/implement-certificate-monitoring.yml
- Create: playbooks/infrastructure/vault/validate-certificate-monitoring.yml
- Create: /usr/local/bin/check-cert-expiry.sh (via playbook)
- Create: /etc/consul.d/cert-monitor.json (via playbook)
- Create: /etc/systemd/system/x509-certificate-exporter.service (via playbook)

## Reference Implementations

- Pattern example: playbooks/infrastructure/vault/setup-pki-monitoring.yml
- Validation pattern: playbooks/infrastructure/vault/smoke-test.yml
- Similar task: playbooks/infrastructure/vault/monitor-pki-certificates.yml

## Dependencies

- PKI-001 through PKI-004: Provided certificate files at /opt/*/tls/ that this task needs to monitor
- Existing: Consul service registration capability for health checks
- Existing: Systemd for service management and cron for scheduling

## Prerequisites

- [ ] Certificates deployed to all services
- [ ] Access to certificate locations on all nodes
- [ ] Prometheus/Grafana stack available (optional but recommended)

## Implementation Steps

1. **Deploy Certificate Monitoring Script**

   ```yaml
   - name: Create certificate monitoring script
     ansible.builtin.copy:
       dest: /usr/local/bin/check-cert-expiry.sh
       mode: "0755"
       content: |
         #!/bin/bash
         WARN_DAYS=30
         CRIT_DAYS=7

         check_cert() {
           local cert_file=$1
           local service=$2

           if [[ ! -f "$cert_file" ]]; then
             echo "UNKNOWN: Certificate file not found: $cert_file"
             return 3
           fi

           expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
           expiry_epoch=$(date -d "$expiry_date" +%s)
           current_epoch=$(date +%s)
           days_remaining=$(( ($expiry_epoch - $current_epoch) / 86400 ))

           if [[ $days_remaining -lt $CRIT_DAYS ]]; then
             echo "CRITICAL: $service cert expires in $days_remaining days"
             return 2
           elif [[ $days_remaining -lt $WARN_DAYS ]]; then
             echo "WARNING: $service cert expires in $days_remaining days"
             return 1
           else
             echo "OK: $service cert valid for $days_remaining days"
             return 0
           fi
         }

         # Check all service certificates
         check_cert "/opt/consul/tls/consul.crt" "Consul"
         check_cert "/opt/nomad/tls/nomad.crt" "Nomad"
         check_cert "/opt/vault/tls/vault.crt" "Vault"
   ```

2. **Configure Consul Health Checks**

   ```yaml
   - name: Register certificate expiry health check
     ansible.builtin.copy:
       dest: /etc/consul.d/cert-monitor.json
       content: |
         {
           "service": {
             "name": "certificate-monitor",
             "tags": ["monitoring", "pki"],
             "port": 9090,
             "checks": [
               {
                 "id": "cert-expiry-consul",
                 "name": "Consul Certificate Expiry",
                 "args": ["/usr/local/bin/check-cert-expiry.sh", "/opt/consul/tls/consul.crt", "Consul"],
                 "interval": "1h",
                 "timeout": "10s"
               },
               {
                 "id": "cert-expiry-nomad",
                 "name": "Nomad Certificate Expiry",
                 "args": ["/usr/local/bin/check-cert-expiry.sh", "/opt/nomad/tls/nomad.crt", "Nomad"],
                 "interval": "1h",
                 "timeout": "10s"
               },
               {
                 "id": "cert-expiry-vault",
                 "name": "Vault Certificate Expiry",
                 "args": ["/usr/local/bin/check-cert-expiry.sh", "/opt/vault/tls/vault.crt", "Vault"],
                 "interval": "1h",
                 "timeout": "10s"
               }
             ]
           }
         }
     notify: reload consul
   ```

3. **Deploy Prometheus Certificate Exporter**

   ```yaml
   - name: Install x509-certificate-exporter
     ansible.builtin.get_url:
       url: https://github.com/enix/x509-certificate-exporter/releases/download/v3.13.0/x509-certificate-exporter_3.13.0_linux_amd64.tar.gz
       dest: /tmp/x509-exporter.tar.gz

   - name: Extract exporter
     ansible.builtin.unarchive:
       src: /tmp/x509-exporter.tar.gz
       dest: /usr/local/bin/
       remote_src: yes

   - name: Create exporter configuration
     ansible.builtin.copy:
       dest: /etc/x509-certificate-exporter.yaml
       content: |
         watchDirectories:
           - /opt/consul/tls
           - /opt/nomad/tls
           - /opt/vault/tls
         watchFiles:
           - /opt/traefik/tls/cert.pem
         watchKubeconfigs: []
         secretsNamespaces: []

   - name: Create systemd service for exporter
     ansible.builtin.copy:
       dest: /etc/systemd/system/x509-certificate-exporter.service
       content: |
         [Unit]
         Description=X.509 Certificate Exporter
         After=network.target

         [Service]
         Type=simple
         User=prometheus
         ExecStart=/usr/local/bin/x509-certificate-exporter \
           --config=/etc/x509-certificate-exporter.yaml \
           --listen-address=:9793
         Restart=on-failure

         [Install]
         WantedBy=multi-user.target

   - name: Start certificate exporter
     ansible.builtin.systemd:
       name: x509-certificate-exporter
       state: started
       enabled: yes
       daemon_reload: yes
   ```

4. **Create Certificate Inventory**

   ```yaml
   - name: Generate certificate inventory
     ansible.builtin.shell: |
       cat > /var/lib/cert-inventory.json << EOF
       {
         "certificates": [
           {
             "service": "consul",
             "path": "/opt/consul/tls/consul.crt",
             "type": "server",
             "renewal_threshold_days": 30
           },
           {
             "service": "nomad",
             "path": "/opt/nomad/tls/nomad.crt",
             "type": "server",
             "renewal_threshold_days": 30
           },
           {
             "service": "vault",
             "path": "/opt/vault/tls/vault.crt",
             "type": "server",
             "renewal_threshold_days": 30
           }
         ],
         "ca_certificates": [
           {
             "name": "intermediate-ca",
             "path": "/opt/vault/tls/intermediate-ca.crt",
             "renewal_threshold_days": 90
           }
         ]
       }
       EOF
   ```

5. **Set Up Daily Certificate Report**

   ```yaml
   - name: Create daily certificate report script
     ansible.builtin.copy:
       dest: /usr/local/bin/cert-daily-report.sh
       mode: "0755"
       content: |
         #!/bin/bash
         REPORT_FILE="/var/log/cert-report-$(date +%Y%m%d).txt"

         echo "=== Daily Certificate Status Report ===" > $REPORT_FILE
         echo "Generated: $(date)" >> $REPORT_FILE
         echo "" >> $REPORT_FILE

         for cert_path in /opt/*/tls/*.crt; do
           if [[ -f "$cert_path" ]]; then
             service=$(basename $(dirname $(dirname $cert_path)))
             expiry=$(openssl x509 -enddate -noout -in "$cert_path" | cut -d= -f2)
             days_left=$(( ($(date -d "$expiry" +%s) - $(date +%s)) / 86400 ))

             echo "Service: $service" >> $REPORT_FILE
             echo "  Certificate: $cert_path" >> $REPORT_FILE
             echo "  Expires: $expiry" >> $REPORT_FILE
             echo "  Days remaining: $days_left" >> $REPORT_FILE

             if [[ $days_left -lt 30 ]]; then
               echo "  Status: NEEDS RENEWAL" >> $REPORT_FILE
             else
               echo "  Status: OK" >> $REPORT_FILE
             fi
             echo "" >> $REPORT_FILE
           fi
         done

         # Send report via Consul event
         consul event -name=cert-report -payload="$(cat $REPORT_FILE)"

   - name: Schedule daily report
     ansible.builtin.cron:
       name: "Daily certificate report"
       minute: "0"
       hour: "8"
       job: "/usr/local/bin/cert-daily-report.sh"
       user: root
   ```

## Success Criteria

- [ ] Certificate monitoring script deployed and functional
- [ ] Consul health checks reporting certificate status
- [ ] Prometheus exporter collecting certificate metrics
- [ ] Certificate inventory maintained and current
- [ ] Daily reports generated and accessible
- [ ] Alerts triggered for certificates approaching expiry
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/implement-certificate-monitoring.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/implement-certificate-monitoring.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-certificate-monitoring.yml
```

Validation playbook content:

```yaml
---
- name: Validate Certificate Monitoring
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Execute certificate monitoring script
      ansible.builtin.command: /usr/local/bin/check-cert-expiry.sh
      register: cert_script_output
      changed_when: false

    - name: Verify Consul health checks for certificate monitoring
      ansible.builtin.uri:
        url: "http://consul.service.consul:8500/v1/catalog/services"
        method: GET
      register: consul_services
      changed_when: false

    - name: Check if certificate-monitor service is registered
      ansible.builtin.set_fact:
        cert_monitor_registered: "{{ 'certificate-monitor' in consul_services.json.keys() }}"

    - name: Query Prometheus metrics from certificate exporter
      ansible.builtin.uri:
        url: "http://localhost:9793/metrics"
        method: GET
      register: prometheus_metrics
      changed_when: false
      failed_when: false

    - name: Filter x509 certificate metrics
      ansible.builtin.set_fact:
        x509_metrics: "{{ prometheus_metrics.content.split('\n') | select('match', '.*x509.*') | list }}"
      when: prometheus_metrics.status == 200

    - name: Read certificate inventory
      ansible.builtin.slurp:
        src: /var/lib/cert-inventory.json
      register: cert_inventory_raw

    - name: Parse certificate inventory
      ansible.builtin.set_fact:
        cert_inventory: "{{ cert_inventory_raw.content | b64decode | from_json }}"

    - name: Find latest daily report
      ansible.builtin.find:
        paths: /var/log
        patterns: "cert-report-*.txt"
        age: -1d
      register: daily_reports

    - name: Read latest daily report
      ansible.builtin.slurp:
        src: "{{ daily_reports.files | sort(attribute='mtime') | last | default({}) | dict2items | selectattr('key', 'equalto', 'path') | list | first | default({'value': '/dev/null'}) | dict2items | selectattr('key', 'equalto', 'value') | list | first | default({'value': '/dev/null'}).value }}"
      register: latest_report
      when: daily_reports.files | length > 0

    - name: Display validation results
      ansible.builtin.debug:
        msg: |
          Certificate Script Status: {{ 'SUCCESS' if cert_script_output.rc == 0 else 'FAILED' }}
          Consul Service Registered: {{ 'YES' if cert_monitor_registered else 'NO' }}
          Prometheus Exporter Status: {{ 'RUNNING' if prometheus_metrics.status == 200 else 'DOWN' }}
          X509 Metrics Count: {{ x509_metrics | length if x509_metrics is defined else 0 }}
          Certificate Inventory Entries: {{ cert_inventory.certificates | length + cert_inventory.ca_certificates | length }}
          Daily Reports Found: {{ daily_reports.files | length }}

    - name: Verify certificate expiry thresholds
      ansible.builtin.command: |
        openssl x509 -enddate -noout -in {{ item.path }}
      loop: "{{ cert_inventory.certificates }}"
      register: cert_expiry_checks
      changed_when: false
      failed_when: false

    - name: Calculate days until expiry for each certificate
      ansible.builtin.set_fact:
        cert_expiry_status: |
          {% set results = [] %}
          {% for check in cert_expiry_checks.results %}
          {% set expiry_date = check.stdout.split('=')[1] %}
          {% set expiry_epoch = expiry_date | to_datetime('%b %d %H:%M:%S %Y %Z') | int %}
          {% set current_epoch = ansible_date_time.epoch | int %}
          {% set days_remaining = ((expiry_epoch - current_epoch) / 86400) | int %}
          {% set _ = results.append({
            'path': cert_inventory.certificates[loop.index0].path,
            'service': cert_inventory.certificates[loop.index0].service,
            'days_remaining': days_remaining,
            'status': 'CRITICAL' if days_remaining < 7 else ('WARNING' if days_remaining < 30 else 'OK')
          }) %}
          {% endfor %}
          {{ results }}

    - name: Display certificate status
      ansible.builtin.debug:
        msg: "Service: {{ item.service }}, Days remaining: {{ item.days_remaining }}, Status: {{ item.status }}"
      loop: "{{ cert_expiry_status }}"
      when: cert_expiry_status is defined

    - name: Verify monitoring is working correctly
      ansible.builtin.assert:
        that:
          - cert_script_output.rc == 0
          - cert_monitor_registered
          - cert_inventory.certificates | length > 0
        fail_msg: "Certificate monitoring validation failed"
        success_msg: "Certificate monitoring is working correctly"

    - name: Check Consul health check status
      ansible.builtin.uri:
        url: "http://consul.service.consul:8500/v1/health/checks/certificate-monitor"
        method: GET
      register: consul_health_checks
      changed_when: false
      failed_when: false

    - name: Display Consul health check results
      ansible.builtin.debug:
        msg: "Consul health checks: {{ consul_health_checks.json | length }} checks found"
      when: consul_health_checks.status == 200
```

## Notes

- Warning threshold: 30 days before expiry
- Critical threshold: 7 days before expiry
- Monitoring runs hourly via Consul checks
- Prometheus exporter provides real-time metrics
- Daily reports provide summary for operations team
