# Task: Implement Service Reload Handlers for Certificate Updates

**Task ID**: PKI-009
**Parent Issue**: #100 (Certificate Rotation and Distribution)
**Priority**: P0 - Critical
**Estimated Time**: 2 hours
**Dependencies**: PKI-008

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
         - vault  # Reload Vault first (PKI source)
         - consul # Then Consul (service discovery)
         - nomad  # Finally Nomad (workload orchestrator)

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
           max_parallel: 1  # One service at a time
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

```bash
# Test Consul reload
consul reload && consul members

# Test Nomad TLS reload
nomad operator reload-tls

# Test Vault reload
kill -HUP $(pidof vault) && vault status

# Verify no dropped connections during reload
while true; do curl -k https://localhost:8501/v1/status/leader; sleep 0.5; done
```

## Notes

- Consul uses native reload command
- Nomad has dedicated TLS reload operator command
- Vault responds to SIGHUP for configuration reload
- Always validate health before and after reload
- Rollback prepared for each service
