---
Task: Implement Service Reload Handlers for Certificate Updates
Task ID: PKI-009
Parent Issue: 100 - Certificate Rotation and Distribution
Priority: P0 - Critical
Estimated Time: 2 hours
Dependencies: PKI-008
Status: Ready
---

## Objective

Create intelligent service reload handlers that gracefully reload services after certificate updates without disrupting active connections or causing downtime.

## Prerequisites

- [ ] Services configured for graceful reload
- [ ] Health check endpoints available
- [ ] Load balancer or service mesh for traffic management

## Implementation Steps

1. **Create Consul Reload Handler**

   ```yaml
   # roles/cert_rotation/handlers/consul.yml
   ---
   - name: Consul certificate reload handler
     block:
       - name: Validate new Consul certificate
         ansible.builtin.command: |
           consul tls cert verify \
             -ca-file=/opt/consul/tls/ca.crt \
             -cert-file=/opt/consul/tls/consul.crt
         register: cert_validation

       - name: Reload Consul configuration
         ansible.builtin.command: consul reload
         when: cert_validation.rc == 0

       - name: Wait for Consul to be healthy
         ansible.builtin.uri:
           url: "https://{{ ansible_default_ipv4.address }}:8501/v1/status/leader"
           client_cert: /opt/consul/tls/consul.crt
           client_key: /opt/consul/tls/consul.key
           validate_certs: yes
         retries: 10
         delay: 2

       - name: Verify cluster membership
         ansible.builtin.command: consul members
         register: members
         failed_when: inventory_hostname not in members.stdout
     rescue:
       - name: Rollback on failure
         ansible.builtin.copy:
           src: "{{ backup_dir }}/consul/{{ ansible_date_time.date }}/consul.crt"
           dest: /opt/consul/tls/consul.crt
           remote_src: yes

       - name: Restart Consul after rollback
         ansible.builtin.systemd:
           name: consul
           state: restarted
   ```

2. **Create Nomad Reload Handler**

   ```yaml
   # roles/cert_rotation/handlers/nomad.yml
   ---
   - name: Nomad certificate reload handler
     block:
       - name: Check Nomad job status before reload
         ansible.builtin.command: nomad job status -json
         register: jobs_before

       - name: Reload Nomad TLS configuration
         ansible.builtin.command: |
           nomad operator reload-tls \
             -ca-file=/opt/nomad/tls/ca.crt \
             -cert-file=/opt/nomad/tls/nomad.crt \
             -key-file=/opt/nomad/tls/nomad.key
         register: reload_result

       - name: Wait for Nomad API availability
         ansible.builtin.wait_for:
           port: 4646
           host: "{{ ansible_default_ipv4.address }}"
           delay: 2
           timeout: 30

       - name: Verify no job disruptions
         ansible.builtin.command: nomad job status -json
         register: jobs_after

       - name: Compare job states
         ansible.builtin.assert:
           that:
             - jobs_before.stdout == jobs_after.stdout
           fail_msg: "Job states changed after certificate reload!"
     rescue:
       - name: Report reload failure
         ansible.builtin.debug:
           msg: "Nomad TLS reload failed, manual intervention required"
   ```

3. **Create Vault Reload Handler**

   ```yaml
   # roles/cert_rotation/handlers/vault.yml
   ---
   - name: Vault certificate reload handler
     block:
       - name: Check Vault seal status
         ansible.builtin.uri:
           url: "https://{{ ansible_default_ipv4.address }}:8200/v1/sys/seal-status"
           validate_certs: no
         register: seal_status

       - name: Send SIGHUP to Vault for reload
         ansible.builtin.shell: |
           kill -HUP $(cat /var/run/vault/vault.pid)
         when: not seal_status.json.sealed

       - name: Wait for Vault to reload
         ansible.builtin.pause:
           seconds: 5

       - name: Verify Vault is responding
         ansible.builtin.uri:
           url: "https://{{ ansible_default_ipv4.address }}:8200/v1/sys/health"
           client_cert: /opt/vault/tls/vault.crt
           client_key: /opt/vault/tls/vault.key
           validate_certs: yes
         retries: 5
         delay: 2

       - name: Verify Vault is unsealed
         ansible.builtin.assert:
           that:
             - not seal_status.json.sealed
           fail_msg: "Vault sealed after certificate reload!"
     rescue:
       - name: Attempt Vault unseal
         ansible.builtin.include_tasks: unseal-vault.yml
         when: seal_status.json.sealed
   ```

4. **Create Universal Reload Orchestrator**

   ```yaml
   # playbooks/infrastructure/vault/handlers/reload-orchestrator.yml
   ---
   - name: Orchestrate service reloads
     vars:
       reload_order:
         - vault # Reload Vault first (PKI source)
         - consul # Then Consul (service discovery)
         - nomad # Finally Nomad (workload orchestrator)

     tasks:
       - name: Determine services needing reload
         ansible.builtin.set_fact:
           services_to_reload: >-
             {{ reload_order |
                select('in', updated_certificates.keys()) |
                list }}

       - name: Create reload plan
         ansible.builtin.debug:
           msg: |
             Reload Plan:
             Services to reload: {{ services_to_reload | join(', ') }}
             Order: {{ reload_order | join(' -> ') }}
             Strategy: Rolling reload with health checks

       - name: Execute rolling reload
         include_tasks: "handlers/{{ item }}.yml"
         loop: "{{ services_to_reload }}"
         vars:
           max_parallel: 1 # One service at a time
           health_check_timeout: 60
           rollback_on_failure: true
   ```

5. **Create Health Check Validation**

   ```yaml
   # roles/cert_rotation/tasks/validate-health.yml
   ---
   - name: Comprehensive health validation
     block:
       - name: Check Consul health
         ansible.builtin.uri:
           url: "https://localhost:8501/v1/agent/health/service/name/{{ item }}"
           client_cert: "/opt/consul/tls/consul.crt"
           client_key: "/opt/consul/tls/consul.key"
         loop:
           - consul
           - nomad
           - vault
         register: consul_health

       - name: Check Nomad health
         ansible.builtin.uri:
           url: "https://localhost:4646/v1/agent/health"
           client_cert: "/opt/nomad/tls/nomad.crt"
           client_key: "/opt/nomad/tls/nomad.key"
         register: nomad_health

       - name: Check Vault health
         ansible.builtin.uri:
           url: "https://localhost:8200/v1/sys/health"
           client_cert: "/opt/vault/tls/vault.crt"
           client_key: "/opt/vault/tls/vault.key"
         register: vault_health

       - name: Assert all services healthy
         ansible.builtin.assert:
           that:
             - consul_health.results | selectattr('status', 'equalto', 200) | list | length == 3
             - nomad_health.status == 200
             - vault_health.status == 200
           fail_msg: "Service health checks failed after reload!"
   ```

## Success Criteria

- [ ] Each service has dedicated reload handler
- [ ] Reload completes without dropping connections
- [ ] Health checks pass after reload
- [ ] Rollback mechanism tested and working
- [ ] No job/task disruptions during reload

## Validation

Run validation playbook:

```bash
uv run ansible-playbook playbooks/infrastructure/vault/validate-service-reload-handlers.yml
```

The validation playbook performs these checks:

```yaml
# playbooks/infrastructure/vault/validate-service-reload-handlers.yml
---
- name: Validate Service Reload Handlers
  hosts: all
  tasks:
    - name: Test Consul reload capability
      block:
        - name: Check Consul status before reload
          ansible.builtin.uri:
            url: "https://localhost:8501/v1/status/leader"
            client_cert: /opt/consul/tls/consul.crt
            client_key: /opt/consul/tls/consul.key
            validate_certs: false
          register: consul_before
          changed_when: false

        - name: Test Consul reload
          ansible.builtin.command: consul reload
          register: consul_reload_result
          changed_when: false

        - name: Verify Consul cluster membership
          ansible.builtin.command: consul members
          register: consul_members
          changed_when: false
          failed_when: inventory_hostname not in consul_members.stdout

        - name: Check Consul status after reload
          ansible.builtin.uri:
            url: "https://localhost:8501/v1/status/leader"
            client_cert: /opt/consul/tls/consul.crt
            client_key: /opt/consul/tls/consul.key
            validate_certs: false
          register: consul_after
          changed_when: false

    - name: Test Nomad TLS reload capability
      block:
        - name: Check Nomad status before reload
          ansible.builtin.uri:
            url: "https://localhost:4646/v1/status/leader"
            client_cert: /opt/nomad/tls/nomad.crt
            client_key: /opt/nomad/tls/nomad.key
            validate_certs: false
          register: nomad_before
          changed_when: false

        - name: Test Nomad TLS reload
          ansible.builtin.command: |
            nomad operator reload-tls
          register: nomad_reload_result
          changed_when: false

        - name: Check Nomad status after reload
          ansible.builtin.uri:
            url: "https://localhost:4646/v1/status/leader"
            client_cert: /opt/nomad/tls/nomad.crt
            client_key: /opt/nomad/tls/nomad.key
            validate_certs: false
          register: nomad_after
          changed_when: false

    - name: Test Vault reload capability
      block:
        - name: Check Vault seal status before reload
          ansible.builtin.uri:
            url: "https://localhost:8200/v1/sys/seal-status"
            validate_certs: false
          register: vault_before
          changed_when: false

        - name: Send SIGHUP to Vault for reload
          ansible.builtin.shell: |
            kill -HUP $(pidof vault)
          register: vault_reload_result
          changed_when: false

        - name: Wait for Vault to process reload
          ansible.builtin.pause:
            seconds: 5

        - name: Check Vault status after reload
          ansible.builtin.uri:
            url: "https://localhost:8200/v1/sys/health"
            client_cert: /opt/vault/tls/vault.crt
            client_key: /opt/vault/tls/vault.key
            validate_certs: false
          register: vault_after
          changed_when: false

    - name: Test connection continuity during reload
      block:
        - name: Start continuous connection test
          ansible.builtin.shell: |
            timeout 30s bash -c '
            failures=0
            total=0
            while true; do
              if ! curl -k -s --max-time 1 https://localhost:8501/v1/status/leader >/dev/null 2>&1; then
                failures=$((failures + 1))
              fi
              total=$((total + 1))
              sleep 0.5
            done
            echo "Connection test: $failures failures out of $total attempts"
            '
          register: connection_test
          changed_when: false
          async: 35
          poll: 0

        - name: Trigger test reload during connection monitoring
          ansible.builtin.command: consul reload
          changed_when: false

        - name: Wait for connection test to complete
          ansible.builtin.async_status:
            jid: "{{ connection_test.ansible_job_id }}"
          register: connection_result
          until: connection_result.finished
          retries: 10
          delay: 5

    - name: Validate reload handler functionality
      ansible.builtin.assert:
        that:
          - consul_reload_result.rc == 0
          - nomad_reload_result.rc == 0
          - vault_reload_result.rc == 0
          - consul_before.status == 200
          - consul_after.status == 200
          - nomad_before.status == 200
          - nomad_after.status == 200
          - vault_before.status == 200
          - vault_after.status == 200
        fail_msg: "Service reload handlers validation failed"

    - name: Display validation results
      ansible.builtin.debug:
        msg: |
          === Service Reload Handlers Validation Results ===
          Consul Reload: {{ 'PASSED' if consul_reload_result.rc == 0 else 'FAILED' }}
          Nomad TLS Reload: {{ 'PASSED' if nomad_reload_result.rc == 0 else 'FAILED' }}
          Vault Reload: {{ 'PASSED' if vault_reload_result.rc == 0 else 'FAILED' }}

          Service Health:
          - Consul: {{ consul_after.status }} (Before: {{ consul_before.status }})
          - Nomad: {{ nomad_after.status }} (Before: {{ nomad_before.status }})
          - Vault: {{ vault_after.status }} (Before: {{ vault_before.status }})

          Connection Continuity: {{ connection_result.stdout if connection_result.stdout is defined else 'Test completed' }}
```

## Notes

- Consul uses native reload command
- Nomad has dedicated TLS reload operator command
- Vault responds to SIGHUP for configuration reload
- Always validate health before and after reload
- Rollback prepared for each service
