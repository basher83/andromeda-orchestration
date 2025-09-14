---
Task: Configure Advanced PKI Monitoring
Task ID: PKI-014
Parent Issue: 100 - Certificate Rotation and Distribution
Priority: P1 - High
Estimated Time: 3 hours
Dependencies: PKI-007, PKI-013
Status: Ready
---

## Objective

Create Ansible playbooks that implement comprehensive PKI monitoring beyond basic expiration tracking, including CA health, certificate chain validation, issuance patterns, and anomaly detection.

## Prerequisites

- [ ] Prometheus and Grafana deployed
- [ ] Basic certificate monitoring in place (PKI-007)
- [ ] Access to Vault metrics endpoint
- [ ] Alert manager configured

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/deploy-advanced-pki-monitoring.yml
- Create: playbooks/infrastructure/vault/configure-pki-anomaly-detection.yml
- Create: playbooks/infrastructure/vault/validate-pki-monitoring.yml
- Create: scripts/pki-anomaly-detector.py (anomaly detection script)
- Create: scripts/check-ca-health.sh (CA health monitoring script)
- Modify: /etc/prometheus/rules/pki.yml (advanced PKI alerting rules)

## Reference Implementations

- Pattern example: playbooks/infrastructure/monitoring/deploy-prometheus-exporters.yml
- Validation pattern: playbooks/assessment/infrastructure-readiness.yml
- Similar task: PKI-007 (Basic certificate monitoring provides foundation)

## Execution Environment

- Target cluster: doggos-homelab (primary), vault-cluster (PKI infrastructure)
- Inventory: inventory/environments/doggos-homelab/proxmox.yml (primary)
- Required secrets (via Infisical):
  - CONSUL_MASTER_TOKEN (path: /apollo-13/consul)
  - VAULT_PROD_ROOT_TOKEN (path: /apollo-13/vault)
- Service addresses: Defined in inventory group_vars

## Dependencies

- PKI-007: Provides the basic certificate monitoring infrastructure that this task extends with advanced metrics and anomaly detection
- PKI-013: Provides the certificate revocation infrastructure that integrates with advanced monitoring for revocation pattern analysis
- Existing: Prometheus, Grafana, and AlertManager must be operational for metrics collection and visualization

## Implementation Steps

1. **Deploy Vault PKI Exporter**

   ```yaml
   - name: Install vault-pki-exporter
     ansible.builtin.copy:
       dest: /opt/vault-pki-exporter/docker-compose.yml
       content: |
         version: '3.8'
         services:
           vault-pki-exporter:
             image: aarnaud/vault-pki-exporter:latest
             ports:
               - "9333:9333"
             environment:
               VAULT_ADDR: "https://vault.service.consul:8200"
               VAULT_TOKEN: "${PKI_EXPORTER_TOKEN}"
               VAULT_SKIP_VERIFY: "false"
               VAULT_CA_CERT: "/certs/ca.pem"
               PKI_MOUNTS: "pki,pki-int,pki-int-connect"
               REFRESH_INTERVAL: "300"  # 5 minutes
             volumes:
               - /opt/vault/tls:/certs:ro
             restart: unless-stopped
             healthcheck:
               test: ["CMD", "curl", "-f", "http://localhost:9333/health"]
               interval: 30s

   - name: Create exporter configuration
     ansible.builtin.copy:
       dest: /opt/vault-pki-exporter/config.yaml
       content: |
         vault:
           address: https://vault.service.consul:8200
           token: {{ pki_exporter_token }}

         pki_mounts:
           - name: pki
             path: pki
             monitor_roles: true
             monitor_certs: false  # Root CA, skip individual certs
           - name: pki-int
             path: pki-int
             monitor_roles: true
             monitor_certs: true
             alert_days_before_expiry: 30
           - name: pki-int-connect
             path: pki-int-connect
             monitor_roles: true
             monitor_certs: true
             alert_days_before_expiry: 7  # Short-lived Connect certs

         metrics:
           include_cert_details: true
           include_san_details: true
           track_issuance_rate: true

   - name: Start PKI exporter
     ansible.builtin.docker_compose:
       project_src: /opt/vault-pki-exporter
       state: present
   ```

2. **Configure Comprehensive Metrics Collection**

   ```yaml
   - name: Configure Prometheus scrape config for PKI
     ansible.builtin.blockinfile:
       path: /etc/prometheus/prometheus.yml
       marker: "# {mark} PKI MONITORING"
       block: |
         - job_name: 'vault-pki'
           static_configs:
             - targets: ['localhost:9333']
           metrics_path: /metrics
           scrape_interval: 60s

         - job_name: 'vault-metrics'
           static_configs:
             - targets: ['vault.service.consul:8200']
           metrics_path: /v1/sys/metrics
           params:
             format: ['prometheus']
           bearer_token: '{{ vault_metrics_token }}'
           scheme: https
           tls_config:
             ca_file: /opt/prometheus/certs/vault-ca.pem

         - job_name: 'ocsp-responder'
           static_configs:
             - targets: ['ocsp.spaceships.work:8888']
           metrics_path: /metrics

   - name: Create PKI metrics rules
     ansible.builtin.copy:
       dest: /etc/prometheus/rules/pki.yml
       content: |
         groups:
           - name: pki_health
             interval: 60s
             rules:
               # Certificate expiration tracking
               - record: pki:cert_days_remaining
                 expr: |
                   (vault_pki_cert_expiry_timestamp - time()) / 86400

               # Certificate issuance rate
               - record: pki:issuance_rate_1h
                 expr: |
                   rate(vault_pki_certificates_issued_total[1h])

               # CA chain health
               - record: pki:ca_chain_valid
                 expr: |
                   vault_pki_ca_chain_valid == 1

               # Revocation rate
               - record: pki:revocation_rate_24h
                 expr: |
                   increase(vault_pki_certificates_revoked_total[24h])

           - name: pki_alerts
             rules:
               - alert: CertificateExpiringSoon
                 expr: pki:cert_days_remaining < 30
                 for: 1h
                 labels:
                   severity: warning
                 annotations:
                   summary: "Certificate expiring soon"
                   description: "{{ $labels.common_name }} expires in {{ $value }} days"

               - alert: CertificateExpiryCritical
                 expr: pki:cert_days_remaining < 7
                 for: 10m
                 labels:
                   severity: critical
                 annotations:
                   summary: "Certificate expiring critically soon"
                   description: "{{ $labels.common_name }} expires in {{ $value }} days"

               - alert: HighCertificateIssuanceRate
                 expr: pki:issuance_rate_1h > 100
                 for: 5m
                 labels:
                   severity: warning
                 annotations:
                   summary: "Unusually high certificate issuance rate"
                   description: "{{ $value }} certificates/hour (normal: < 100)"

               - alert: CAChainInvalid
                 expr: pki:ca_chain_valid != 1
                 for: 1m
                 labels:
                   severity: critical
                 annotations:
                   summary: "CA certificate chain is invalid"
                   description: "PKI mount {{ $labels.mount }} has invalid chain"

               - alert: HighRevocationRate
                 expr: pki:revocation_rate_24h > 10
                 for: 10m
                 labels:
                   severity: warning
                 annotations:
                   summary: "High certificate revocation rate"
                   description: "{{ $value }} certificates revoked in 24h"

               - alert: OCSPResponderDown
                 expr: up{job="ocsp-responder"} != 1
                 for: 5m
                 labels:
                   severity: critical
                 annotations:
                   summary: "OCSP responder is down"
                   description: "OCSP responder has been down for 5 minutes"
   ```

3. **Implement Certificate Anomaly Detection**

   ```yaml
   - name: Deploy anomaly detection script
     ansible.builtin.copy:
       dest: /usr/local/bin/pki-anomaly-detector.py
       mode: "0755"
       content: |
         #!/usr/bin/env python3
         import json
         import requests
         import statistics
         from datetime import datetime, timedelta
         from collections import defaultdict

         VAULT_ADDR = "https://vault.service.consul:8200"
         VAULT_TOKEN = "{{ anomaly_detector_token }}"

         def get_recent_certificates(hours=24):
             """Fetch certificates issued in the last N hours"""
             headers = {"X-Vault-Token": VAULT_TOKEN}
             certs = []

             # Get certificate list
             resp = requests.get(
                 f"{VAULT_ADDR}/v1/pki-int/certs",
                 headers=headers,
                 verify="/opt/vault/tls/ca.pem"
             )

             if resp.status_code == 200:
                 for serial in resp.json()["data"]["keys"]:
                     cert_resp = requests.get(
                         f"{VAULT_ADDR}/v1/pki-int/cert/{serial}",
                         headers=headers,
                         verify="/opt/vault/tls/ca.pem"
                     )
                     if cert_resp.status_code == 200:
                         certs.append(cert_resp.json()["data"])

             return certs

         def detect_anomalies(certs):
             """Detect unusual patterns in certificate issuance"""
             anomalies = []

             # Check for unusual CN patterns
             cn_counts = defaultdict(int)
             for cert in certs:
                 cn = cert.get("common_name", "")
                 cn_counts[cn] += 1

             # Flag if same CN requested too many times
             for cn, count in cn_counts.items():
                 if count > 10:  # Threshold
                     anomalies.append({
                         "type": "excessive_requests",
                         "common_name": cn,
                         "count": count
                     })

             # Check for unusual TTLs
             ttls = [cert.get("ttl", 0) for cert in certs]
             if ttls:
                 mean_ttl = statistics.mean(ttls)
                 std_ttl = statistics.stdev(ttls) if len(ttls) > 1 else 0

                 for cert in certs:
                     ttl = cert.get("ttl", 0)
                     if abs(ttl - mean_ttl) > 2 * std_ttl:
                         anomalies.append({
                             "type": "unusual_ttl",
                             "serial": cert.get("serial_number"),
                             "ttl": ttl,
                             "expected": mean_ttl
                         })

             # Check for certificates with suspicious SANs
             for cert in certs:
                 sans = cert.get("alt_names", [])
                 if len(sans) > 20:  # Threshold
                     anomalies.append({
                         "type": "excessive_sans",
                         "serial": cert.get("serial_number"),
                         "san_count": len(sans)
                     })

             return anomalies

         def send_alerts(anomalies):
             """Send anomalies to monitoring system"""
             for anomaly in anomalies:
                 # Send to Consul event
                 requests.put(
                     "http://localhost:8500/v1/event/fire/pki-anomaly",
                     json=anomaly
                 )

                 # Log to file
                 with open("/var/log/pki-anomalies.log", "a") as f:
                     f.write(f"{datetime.now().isoformat()} - {json.dumps(anomaly)}\n")

         if __name__ == "__main__":
             certs = get_recent_certificates(24)
             anomalies = detect_anomalies(certs)

             if anomalies:
                 print(f"Detected {len(anomalies)} anomalies")
                 send_alerts(anomalies)
             else:
                 print("No anomalies detected")

   - name: Schedule anomaly detection
     ansible.builtin.cron:
       name: "PKI anomaly detection"
       minute: "*/30"
       job: "/usr/local/bin/pki-anomaly-detector.py"
       user: monitoring
   ```

4. **Create PKI Health Dashboard**

   ```yaml
   - name: Deploy Grafana PKI dashboard
     ansible.builtin.copy:
       dest: /etc/grafana/dashboards/pki-health.json
       content: |
         {
           "dashboard": {
             "title": "PKI Infrastructure Health",
             "panels": [
               {
                 "title": "Certificate Expiration Timeline",
                 "type": "graph",
                 "targets": [{
                   "expr": "pki:cert_days_remaining",
                   "legendFormat": "{{ common_name }}"
                 }]
               },
               {
                 "title": "Issuance Rate",
                 "type": "graph",
                 "targets": [{
                   "expr": "pki:issuance_rate_1h",
                   "legendFormat": "Certificates/hour"
                 }]
               },
               {
                 "title": "CA Chain Status",
                 "type": "stat",
                 "targets": [{
                   "expr": "pki:ca_chain_valid",
                   "legendFormat": "{{ mount }}"
                 }]
               },
               {
                 "title": "Revocation Events",
                 "type": "table",
                 "targets": [{
                   "expr": "increase(vault_pki_certificates_revoked_total[24h])",
                   "format": "table"
                 }]
               },
               {
                 "title": "Certificate Distribution by Type",
                 "type": "piechart",
                 "targets": [{
                   "expr": "count by (role) (vault_pki_cert_expiry_timestamp)",
                   "legendFormat": "{{ role }}"
                 }]
               },
               {
                 "title": "OCSP Response Times",
                 "type": "graph",
                 "targets": [{
                   "expr": "histogram_quantile(0.95, ocsp_response_duration_seconds_bucket)",
                   "legendFormat": "95th percentile"
                 }]
               },
               {
                 "title": "Anomaly Detection Events",
                 "type": "logs",
                 "targets": [{
                   "expr": "{filename=\"/var/log/pki-anomalies.log\"}"
                 }]
               }
             ]
           }
         }
   ```

5. **Implement CA Health Checks**

   ```yaml
   - name: Deploy CA health check script
     ansible.builtin.copy:
       dest: /usr/local/bin/check-ca-health.sh
       mode: "0755"
       content: |
         #!/bin/bash
         set -euo pipefail

         STATUS=0
         REPORT="/var/log/ca-health-$(date +%Y%m%d).log"

         echo "=== CA Health Check Report ===" > "$REPORT"
         echo "Timestamp: $(date)" >> "$REPORT"

         # Check root CA
         echo "Root CA Status:" >> "$REPORT"
         vault read pki/cert/ca -format=json | jq -r '.data.certificate' | \
           openssl x509 -text -noout | grep -E "(Subject:|Not After)" >> "$REPORT"

         # Check intermediate CAs
         for mount in pki-int pki-int-connect; do
           echo "${mount} Status:" >> "$REPORT"
           vault read ${mount}/cert/ca -format=json | jq -r '.data.certificate' | \
             openssl x509 -text -noout | grep -E "(Subject:|Not After)" >> "$REPORT"

           # Verify chain
           vault read ${mount}/cert/ca-chain -format=json | jq -r '.data.certificate' | \
             openssl verify -CAfile /opt/vault/tls/root-ca.pem && \
             echo "  Chain: VALID" >> "$REPORT" || \
             { echo "  Chain: INVALID" >> "$REPORT"; STATUS=1; }
         done

         # Check CRL accessibility
         for url in $(vault read -format=json pki-int/config/urls | jq -r '.data.crl_distribution_points[]'); do
           if curl -f -s "$url" > /dev/null; then
             echo "CRL $url: ACCESSIBLE" >> "$REPORT"
           else
             echo "CRL $url: INACCESSIBLE" >> "$REPORT"
             STATUS=1
           fi
         done

         # Send to monitoring
         if [[ $STATUS -ne 0 ]]; then
           consul event -name=ca-health-degraded -payload="$(cat $REPORT)"
         fi

         exit $STATUS

   - name: Schedule CA health checks
     ansible.builtin.cron:
       name: "CA health check"
       minute: "0"
       hour: "*/4"
       job: "/usr/local/bin/check-ca-health.sh"
       user: monitoring
   ```

## Success Criteria

- [ ] PKI exporter collecting all certificate metrics
- [ ] Comprehensive alerting rules configured
- [ ] Anomaly detection identifying unusual patterns
- [ ] Dashboard providing full PKI visibility
- [ ] CA health monitoring automated
- [ ] All metrics flowing to Prometheus
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/deploy-advanced-pki-monitoring.yml
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/configure-pki-anomaly-detection.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/deploy-advanced-pki-monitoring.yml
uv run ansible-lint playbooks/infrastructure/vault/configure-pki-anomaly-detection.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-pki-monitoring.yml
```

Validation playbook performs:

```yaml
---
- name: Validate PKI Monitoring
  hosts: localhost
  tasks:
    - name: Check PKI exporter metrics endpoint
      ansible.builtin.uri:
        url: "http://localhost:9333/metrics"
        method: GET
      register: pki_metrics
      changed_when: false

    - name: Verify PKI metrics are present
      ansible.builtin.assert:
        that:
          - "'vault_pki' in pki_metrics.content"
        fail_msg: "PKI exporter metrics not found"

    - name: Check Prometheus targets
      ansible.builtin.uri:
        url: "http://localhost:9090/api/v1/targets"
        method: GET
      register: prometheus_targets
      changed_when: false

    - name: Verify PKI targets are active
      ansible.builtin.assert:
        that:
          - prometheus_targets.json.data.activeTargets | selectattr('job', 'equalto', 'vault-pki') | list | length > 0
        fail_msg: "PKI targets not found in Prometheus"

    - name: Test anomaly detection
      ansible.builtin.command:
        cmd: /usr/local/bin/pki-anomaly-detector.py
      register: anomaly_test
      changed_when: false

    - name: Run CA health check
      ansible.builtin.command:
        cmd: /usr/local/bin/check-ca-health.sh
      register: ca_health
      changed_when: false

    - name: Verify CA health status
      ansible.builtin.assert:
        that:
          - ca_health.rc == 0
        fail_msg: "CA health check failed: {{ ca_health.stderr }}"

    - name: Check for active alerts
      ansible.builtin.uri:
        url: "http://localhost:9093/api/v1/alerts"
        method: GET
      register: active_alerts
      changed_when: false

    - name: Display certificate-related alerts
      ansible.builtin.debug:
        msg: "Certificate alerts: {{ active_alerts.json | selectattr('labels.alertname', 'match', '.*Certificate.*') | list }}"
      when: active_alerts.json | selectattr('labels.alertname', 'match', '.*Certificate.*') | list | length > 0

    - name: Test Grafana dashboard accessibility
      ansible.builtin.uri:
        url: "https://grafana.spaceships.work/api/dashboards/db/pki-health"
        method: GET
        validate_certs: false
      register: dashboard_test
      changed_when: false
      failed_when: dashboard_test.status != 200
```

## Notes

- Adjust thresholds based on your environment's normal patterns
- Anomaly detection should learn baseline over time
- Consider integrating with SIEM for security events
- Archive metrics for compliance requirements
- Test alert escalation paths regularly
