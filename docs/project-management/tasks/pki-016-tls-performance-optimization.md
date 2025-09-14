---
Task: Optimize TLS Performance
Task ID: PKI-016
Parent Issue: 100 - Certificate Rotation and Distribution
Priority: P2 - Medium
Estimated Time: 2 hours
Dependencies: PKI-001 through PKI-006
Status: Ready
---

## Objective

Create Ansible playbooks and scripts that implement TLS performance optimizations including session resumption, OCSP stapling, certificate caching, and cipher suite optimization to minimize latency and CPU overhead.

## Prerequisites

- [ ] mTLS fully deployed across services
- [ ] Performance baseline metrics collected
- [ ] Load testing tools available
- [ ] CPU and memory monitoring in place

## Files to Create/Modify

- Create: playbooks/infrastructure/vault/configure-tls-performance-optimization.yml
- Create: playbooks/infrastructure/vault/deploy-certificate-caching.yml
- Create: playbooks/infrastructure/vault/validate-tls-performance.yml
- Create: scripts/enable-ocsp-stapling.sh (OCSP stapling configuration script)
- Create: scripts/monitor-tls-performance.sh (TLS performance monitoring script)
- Create: scripts/cached-cert-request.py (certificate caching integration script)
- Modify: /etc/consul.d/tls-performance.hcl (Consul TLS optimization)
- Modify: /etc/nomad.d/nomad.hcl (Nomad TLS optimization)
- Modify: /etc/vault.d/vault.hcl (Vault TLS optimization)

## Reference Implementations

- Pattern example: playbooks/infrastructure/consul/configure-consul-cluster.yml
- Validation pattern: playbooks/assessment/infrastructure-readiness.yml
- Similar task: PKI-002, PKI-003 (Basic TLS configurations provide foundation for optimization)

## Dependencies

- PKI-001 through PKI-006: Provides the complete mTLS infrastructure that this task optimizes for performance
- Existing: All services must have mTLS operational before performance optimization, monitoring infrastructure must be in place for baseline and improvement metrics

## Implementation Steps

1. **Enable TLS Session Resumption**

   ```yaml
   - name: Configure TLS session caching in Consul
     ansible.builtin.blockinfile:
       path: /etc/consul.d/tls-performance.hcl
       block: |
         # TLS session resumption settings
         performance {
           rpc_hold_timeout = "7s"

           # Enable session ticket keys
           tls_session_cache_size = 8192
           tls_session_timeout = "86400s"  # 24 hours
         }

         ports {
           https = 8501
           grpc_tls = 8503
         }

         tls {
           defaults {
             # Enable TLS 1.3 for better performance
             tls_min_version = "TLSv1.2"
             tls_max_version = "TLSv1.3"

             # Session resumption
             session_tickets_disabled = false
             session_cache_enabled = true

             # Optimize cipher suites for performance
             tls_cipher_suites = [
               "TLS_AES_128_GCM_SHA256",           # TLS 1.3
               "TLS_AES_256_GCM_SHA384",           # TLS 1.3
               "TLS_CHACHA20_POLY1305_SHA256",     # TLS 1.3
               "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",  # TLS 1.2
               "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"   # TLS 1.2
             ]

             # Prefer server cipher order
             tls_prefer_server_cipher_suites = true
           }
         }

   - name: Configure Nomad TLS session caching
     ansible.builtin.blockinfile:
       path: /etc/nomad.d/nomad.hcl
       marker: "# {mark} TLS PERFORMANCE"
       block: |
         tls {
           http = true
           rpc = true

           # Session resumption
           session_cache_size = 8192
           session_timeout = "24h"

           # Performance optimizations
           tls_min_version = "tls12"
           tls_prefer_server_cipher_suites = true

           # Hardware acceleration if available
           tls_cipher_suites = [
             "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
             "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
             "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256"
           ]
         }

   - name: Configure Vault TLS optimization
     ansible.builtin.blockinfile:
       path: /etc/vault.d/vault.hcl
       marker: "# {mark} TLS PERFORMANCE"
       insertafter: 'listener "tcp"'
       block: |
         listener "tcp" {
           address = "0.0.0.0:8200"

           # TLS configuration
           tls_cert_file = "/opt/vault/tls/vault.crt"
           tls_key_file = "/opt/vault/tls/vault.key"

           # Session resumption
           tls_disable_session_tickets = false
           tls_session_cache_size = 8192

           # Performance settings
           tls_min_version = "tls12"
           tls_max_version = "tls13"

           # Optimized cipher suites
           tls_cipher_suites = [
             "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
             "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
           ]

           # HTTP/2 support
           http2 = true
           http2_max_concurrent_streams = 250
         }
   ```

2. **Implement OCSP Stapling**

   ```yaml
   - name: Configure OCSP stapling for services
     ansible.builtin.copy:
       dest: /usr/local/bin/enable-ocsp-stapling.sh
       mode: "0755"
       content: |
         #!/bin/bash
         set -euo pipefail

         SERVICE=$1
         CERT_PATH="/opt/${SERVICE}/tls/${SERVICE}.crt"
         OCSP_PATH="/opt/${SERVICE}/tls/ocsp.resp"

         # Fetch OCSP response
         OCSP_URL=$(openssl x509 -in "$CERT_PATH" -noout -ocsp_uri)

         if [[ -n "$OCSP_URL" ]]; then
           openssl ocsp \
             -issuer /opt/vault/tls/intermediate-ca.pem \
             -cert "$CERT_PATH" \
             -url "$OCSP_URL" \
             -respout "$OCSP_PATH" \
             -noverify \
             -no_nonce

           # Make response available to service
           chown ${SERVICE}:${SERVICE} "$OCSP_PATH"
           chmod 644 "$OCSP_PATH"
         fi

   - name: Configure Traefik with OCSP stapling
     ansible.builtin.copy:
       dest: /etc/traefik/traefik.yml
       content: |
         tls:
           options:
             default:
               minVersion: VersionTLS12
               maxVersion: VersionTLS13
               # OCSP stapling
               ocspStapling: true
               ocspStaplingVerifyInterval: 3600
               # Session tickets
               sessionTicketsDisabled: false
               sessionTicketKeys:
                 - /etc/traefik/session-ticket-key-1
                 - /etc/traefik/session-ticket-key-2
               # Cipher suites
               cipherSuites:
                 - TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256
                 - TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
                 - TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256

   - name: Schedule OCSP response updates
     ansible.builtin.cron:
       name: "Update OCSP responses"
       minute: "0"
       hour: "*/6"
       job: |
         for service in consul nomad vault; do
           /usr/local/bin/enable-ocsp-stapling.sh $service
         done
       user: root
   ```

3. **Implement Certificate Caching**

   ```yaml
   - name: Deploy certificate cache with Redis
     ansible.builtin.copy:
       dest: /opt/cert-cache/docker-compose.yml
       content: |
         version: '3.8'
         services:
           redis:
             image: redis:7-alpine
             ports:
               - "6379:6379"
             volumes:
               - ./data:/data
             command: >
               redis-server
               --maxmemory 256mb
               --maxmemory-policy allkeys-lru
               --save 60 1
               --appendonly yes

   - name: Create certificate caching layer
     ansible.builtin.copy:
       dest: /usr/local/lib/python3.9/site-packages/cert_cache.py
       content: |
         import redis
         import hashlib
         import json
         import base64
         from datetime import datetime, timedelta

         class CertificateCache:
             def __init__(self, redis_host='localhost', redis_port=6379):
                 self.redis = redis.Redis(
                     host=redis_host,
                     port=redis_port,
                     decode_responses=True
                 )
                 self.ttl = 3600  # 1 hour cache

             def get_cache_key(self, common_name, sans=None):
                 """Generate cache key for certificate request"""
                 key_data = f"{common_name}:{','.join(sans or [])}"
                 return f"cert:{hashlib.sha256(key_data.encode()).hexdigest()}"

             def get_certificate(self, common_name, sans=None):
                 """Retrieve certificate from cache"""
                 key = self.get_cache_key(common_name, sans)
                 cached = self.redis.get(key)

                 if cached:
                     cert_data = json.loads(cached)
                     # Check if still valid
                     expires = datetime.fromisoformat(cert_data['expires'])
                     if expires > datetime.now() + timedelta(hours=1):
                         return cert_data
                 return None

             def set_certificate(self, common_name, cert_data, sans=None):
                 """Cache certificate"""
                 key = self.get_cache_key(common_name, sans)

                 # Extract expiration from certificate
                 # ... certificate parsing logic ...

                 cache_data = {
                     'certificate': cert_data['certificate'],
                     'private_key': cert_data['private_key'],
                     'ca_chain': cert_data['ca_chain'],
                     'expires': cert_data['expiration'].isoformat(),
                     'cached_at': datetime.now().isoformat()
                 }

                 self.redis.setex(
                     key,
                     self.ttl,
                     json.dumps(cache_data)
                 )

             def invalidate(self, pattern="*"):
                 """Invalidate cached certificates"""
                 for key in self.redis.scan_iter(f"cert:{pattern}"):
                     self.redis.delete(key)

   - name: Integrate cache with Vault certificate requests
     ansible.builtin.copy:
       dest: /usr/local/bin/cached-cert-request.py
       mode: "0755"
       content: |
         #!/usr/bin/env python3
         import sys
         import hvac
         from cert_cache import CertificateCache

         def request_certificate(common_name, role, ttl="24h"):
             cache = CertificateCache()

             # Check cache first
             cached_cert = cache.get_certificate(common_name)
             if cached_cert:
                 print(f"Certificate retrieved from cache")
                 return cached_cert

             # Request from Vault
             client = hvac.Client(url='https://vault.service.consul:8200')
             client.token = os.environ['VAULT_TOKEN']

             response = client.secrets.pki.generate_certificate(
                 name=role,
                 common_name=common_name,
                 ttl=ttl,
                 mount_point='pki-int'
             )

             # Cache the response
             cache.set_certificate(common_name, response['data'])

             return response['data']

         if __name__ == "__main__":
             cert = request_certificate(sys.argv[1], sys.argv[2])
             print(cert['certificate'])
   ```

4. **Configure Connection Pooling**

   ```yaml
   - name: Configure connection pooling for Consul
     ansible.builtin.blockinfile:
       path: /etc/consul.d/performance.hcl
       block: |
         limits {
           # Connection limits
           http_max_conns_per_client = 200
           rpc_max_conns_per_client = 100

           # Rate limiting
           rpc_rate = -1  # Disable rate limiting
           rpc_max_burst = 1000
         }

         performance {
           # Connection pool settings
           rpc_hold_timeout = "7s"
           leave_drain_time = "5s"

           # Raft performance
           raft_multiplier = 1  # Lower for better performance
         }

   - name: Configure Nomad connection pooling
     ansible.builtin.blockinfile:
       path: /etc/nomad.d/performance.hcl
       block: |
         limits {
           # HTTP connection pooling
           http_max_conns_per_client = 100

           # RPC connection pooling
           rpc_max_conns_per_client = 100
         }

         client {
           # Connection pool to servers
           server_join {
             retry_max = 3
             retry_interval = "15s"
           }

           # Keep connections alive
           heartbeat_grace = "10s"
         }
   ```

5. **Implement Performance Monitoring**

   ```yaml
   - name: Deploy TLS performance monitoring
     ansible.builtin.copy:
       dest: /usr/local/bin/monitor-tls-performance.sh
       mode: "0755"
       content: |
         #!/bin/bash
         set -euo pipefail

         OUTPUT="/var/log/tls-performance-$(date +%Y%m%d-%H%M).log"

         echo "=== TLS Performance Report ===" > "$OUTPUT"
         echo "Timestamp: $(date)" >> "$OUTPUT"

         # Test handshake time
         echo -e "\n## Handshake Performance ##" >> "$OUTPUT"
         for service in consul:8501 nomad:4646 vault:8200; do
           HOST=$(echo $service | cut -d: -f1)
           PORT=$(echo $service | cut -d: -f2)

           # Measure handshake time
           TIME=$(echo | openssl s_client -connect localhost:$PORT 2>/dev/null | \
                  openssl s_time -connect localhost:$PORT -time 1 2>/dev/null | \
                  grep "connections" | awk '{print $1/$6}')

           echo "$HOST: ${TIME}ms per handshake" >> "$OUTPUT"
         done

         # Check session resumption
         echo -e "\n## Session Resumption ##" >> "$OUTPUT"
         for service in consul nomad vault; do
           SESSION_ID=$(echo | openssl s_client -connect localhost:8501 -sess_out /tmp/session 2>/dev/null | \
                       grep "Session-ID:" | cut -d: -f2)

           RESUMED=$(echo | openssl s_client -connect localhost:8501 -sess_in /tmp/session 2>/dev/null | \
                    grep "Reused")

           if [[ -n "$RESUMED" ]]; then
             echo "$service: Session resumption WORKING" >> "$OUTPUT"
           else
             echo "$service: Session resumption NOT WORKING" >> "$OUTPUT"
           fi
         done

         # Check cipher usage
         echo -e "\n## Cipher Suite Usage ##" >> "$OUTPUT"
         for service in consul:8501 nomad:4646 vault:8200; do
           CIPHER=$(echo | openssl s_client -connect localhost:${service#*:} 2>/dev/null | \
                   grep "Cipher" | cut -d: -f2)
           echo "$service: $CIPHER" >> "$OUTPUT"
         done

         # Cache hit rate
         echo -e "\n## Certificate Cache Stats ##" >> "$OUTPUT"
         redis-cli INFO stats | grep -E "keyspace_hits|keyspace_misses" >> "$OUTPUT"

         cat "$OUTPUT"

   - name: Create performance dashboard
     ansible.builtin.copy:
       dest: /etc/grafana/dashboards/tls-performance.json
       content: |
         {
           "dashboard": {
             "title": "TLS Performance Metrics",
             "panels": [
               {
                 "title": "TLS Handshake Duration",
                 "targets": [{
                   "expr": "histogram_quantile(0.95, tls_handshake_duration_seconds_bucket)"
                 }]
               },
               {
                 "title": "Session Resumption Rate",
                 "targets": [{
                   "expr": "rate(tls_session_resumptions_total[5m]) / rate(tls_connections_total[5m])"
                 }]
               },
               {
                 "title": "Certificate Cache Hit Rate",
                 "targets": [{
                   "expr": "rate(cert_cache_hits_total[5m]) / (rate(cert_cache_hits_total[5m]) + rate(cert_cache_misses_total[5m]))"
                 }]
               },
               {
                 "title": "OCSP Stapling Success Rate",
                 "targets": [{
                   "expr": "rate(ocsp_stapling_success_total[5m]) / rate(ocsp_stapling_attempts_total[5m])"
                 }]
               }
             ]
           }
         }
   ```

## Success Criteria

- [ ] TLS 1.3 enabled where supported
- [ ] Session resumption working (>90% reuse rate)
- [ ] OCSP stapling operational
- [ ] Certificate caching reducing Vault load
- [ ] Handshake time < 10ms for resumed sessions
- [ ] CPU usage reduced by >20%
- [ ] Playbook passes syntax check
- [ ] No linting errors reported
- [ ] Validation playbook executes successfully

## Validation

Syntax and lint checks:

```bash
# Syntax check
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/configure-tls-performance-optimization.yml
uv run ansible-playbook --syntax-check playbooks/infrastructure/vault/deploy-certificate-caching.yml

# Lint check
uv run ansible-lint playbooks/infrastructure/vault/configure-tls-performance-optimization.yml
uv run ansible-lint playbooks/infrastructure/vault/deploy-certificate-caching.yml
```

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-tls-performance.yml
```

Validation playbook performs:

```yaml
---
- name: Validate TLS Performance Optimization
  hosts: localhost
  tasks:
    - name: Test TLS session resumption
      ansible.builtin.shell: |
        set -euo pipefail
        echo | openssl s_client -connect localhost:8501 -sess_out /tmp/session 2>/dev/null
        RESUMED=$(echo | openssl s_client -connect localhost:8501 -sess_in /tmp/session -reconnect 2>/dev/null | grep "Reused")
        if [[ -n "$RESUMED" ]]; then
          echo "Session resumption working"
        else
          echo "Session resumption not working"
          exit 1
        fi
      register: session_test
      changed_when: false

    - name: Verify OCSP stapling
      ansible.builtin.shell: |
        set -euo pipefail
        OCSP_STATUS=$(echo | openssl s_client -connect localhost:8501 -status 2>/dev/null | grep "OCSP Response Status")
        if [[ -n "$OCSP_STATUS" ]]; then
          echo "OCSP stapling enabled"
        else
          echo "OCSP stapling not found"
          exit 1
        fi
      register: ocsp_test
      changed_when: false

    - name: Check TLS 1.3 support
      ansible.builtin.shell: |
        set -euo pipefail
        TLS_VERSION=$(echo | openssl s_client -connect localhost:8501 -tls1_3 2>/dev/null | grep "Protocol" | awk '{print $3}')
        if [[ "$TLS_VERSION" == "TLSv1.3" ]]; then
          echo "TLS 1.3 supported"
        else
          echo "TLS 1.3 not available, using $TLS_VERSION"
        fi
      register: tls_version_test
      changed_when: false
      failed_when: false

    - name: Check Redis certificate cache status
      ansible.builtin.command:
        cmd: redis-cli ping
      register: redis_status
      changed_when: false
      failed_when: false

    - name: Get cache hit rate statistics
      ansible.builtin.shell: |
        set -euo pipefail
        redis-cli INFO stats | grep -E "keyspace_hits|keyspace_misses" || echo "No cache stats available"
      register: cache_stats
      changed_when: false
      when: redis_status.rc == 0

    - name: Run TLS performance monitoring
      ansible.builtin.command:
        cmd: /usr/local/bin/monitor-tls-performance.sh
      register: performance_test
      changed_when: false

    - name: Display performance results
      ansible.builtin.debug:
        msg: "{{ performance_test.stdout_lines }}"

    - name: Perform load test with ApacheBench
      ansible.builtin.shell: |
        set -euo pipefail
        timeout 30 ab -n 1000 -c 10 -g /tmp/tls-performance.tsv https://localhost:8501/v1/status/leader 2>/dev/null || true
        if [[ -f /tmp/tls-performance.tsv ]]; then
          echo "Load test completed successfully"
          tail -5 /tmp/tls-performance.tsv
        else
          echo "Load test not available or failed"
        fi
      register: load_test
      changed_when: false
      failed_when: false

    - name: Verify cipher suite optimization
      ansible.builtin.shell: |
        set -euo pipefail
        for service in consul:8501 nomad:4646 vault:8200; do
          HOST=$(echo $service | cut -d: -f1)
          PORT=$(echo $service | cut -d: -f2)
          CIPHER=$(echo | openssl s_client -connect localhost:$PORT 2>/dev/null | grep "Cipher" | cut -d: -f2 | tr -d ' ')
          echo "$HOST: $CIPHER"
        done
      register: cipher_test
      changed_when: false
      failed_when: false

    - name: Display cipher suite results
      ansible.builtin.debug:
        msg: "{{ cipher_test.stdout_lines }}"

    - name: Verify performance dashboard exists
      ansible.builtin.stat:
        path: /etc/grafana/dashboards/tls-performance.json
      register: perf_dashboard

    - name: Assert performance dashboard configured
      ansible.builtin.assert:
        that:
          - perf_dashboard.stat.exists
        fail_msg: "TLS performance dashboard not found"

    - name: Summary of validation results
      ansible.builtin.debug:
        msg:
          - "Session Resumption: {{ 'WORKING' if session_test.rc == 0 else 'FAILED' }}"
          - "OCSP Stapling: {{ 'ENABLED' if ocsp_test.rc == 0 else 'DISABLED' }}"
          - "TLS 1.3 Support: {{ tls_version_test.stdout }}"
          - "Redis Cache: {{ 'AVAILABLE' if redis_status.rc == 0 else 'UNAVAILABLE' }}"
          - "Performance Dashboard: CONFIGURED"
```

## Notes

- TLS 1.3 provides best performance with 0-RTT resumption
- Session tickets should rotate every 24 hours for security
- Monitor cache memory usage to prevent OOM
- Consider hardware acceleration for high-traffic services
- OCSP stapling reduces client latency significantly
