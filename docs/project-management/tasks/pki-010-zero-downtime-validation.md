# Task: Validate Zero-Downtime Certificate Rotation

**Task ID**: PKI-010
**Parent Issue**: #100 (Certificate Rotation and Distribution)
**Priority**: P0 - Critical
**Estimated Time**: 3 hours
**Dependencies**: PKI-007, PKI-008, PKI-009

## Objective

Implement comprehensive validation to ensure certificate rotation occurs without any service downtime, connection drops, or job disruptions.

## Prerequisites

- [ ] Certificate renewal automation deployed
- [ ] Service reload handlers configured
- [ ] Test environment available
- [ ] Load testing tools installed

## Implementation Steps

1. **Create Continuous Availability Monitor**

   ```yaml
   # playbooks/infrastructure/vault/validate-zero-downtime.yml
   ---
   - name: Zero-Downtime Certificate Rotation Validation
     hosts: localhost
     vars:
       test_duration_seconds: 300  # 5 minutes
       probe_interval_ms: 500
       services:
         - { name: consul, port: 8501, endpoint: "/v1/status/leader" }
         - { name: nomad, port: 4646, endpoint: "/v1/status/leader" }
         - { name: vault, port: 8200, endpoint: "/v1/sys/health" }

     tasks:
       - name: Start availability monitoring
         ansible.builtin.shell: |
           cat > /tmp/availability-monitor.sh << 'EOF'
           #!/bin/bash
           SERVICE=$1
           PORT=$2
           ENDPOINT=$3
           DURATION=$4
           INTERVAL=$5

           START=$(date +%s)
           END=$((START + DURATION))
           SUCCESS=0
           FAILURE=0

           while [[ $(date +%s) -lt $END ]]; do
             if curl -k -f -s --max-time 1 \
                --cert /opt/${SERVICE}/tls/${SERVICE}.crt \
                --key /opt/${SERVICE}/tls/${SERVICE}.key \
                https://localhost:${PORT}${ENDPOINT} > /dev/null 2>&1; then
               SUCCESS=$((SUCCESS + 1))
             else
               FAILURE=$((FAILURE + 1))
               echo "$(date '+%Y-%m-%d %H:%M:%S.%3N') - ${SERVICE} probe failed" >> /tmp/${SERVICE}-failures.log
             fi
             sleep $(echo "scale=3; ${INTERVAL}/1000" | bc)
           done

           echo "{\"service\":\"${SERVICE}\",\"success\":${SUCCESS},\"failure\":${FAILURE},\"uptime\":$(echo "scale=2; ${SUCCESS}*100/(${SUCCESS}+${FAILURE})" | bc)}"
           EOF
           chmod +x /tmp/availability-monitor.sh

       - name: Start monitors in background
         ansible.builtin.shell: |
           nohup /tmp/availability-monitor.sh {{ item.name }} {{ item.port }} \
             {{ item.endpoint }} {{ test_duration_seconds }} {{ probe_interval_ms }} \
             > /tmp/{{ item.name }}-monitor.json 2>&1 &
           echo $! > /tmp/{{ item.name }}-monitor.pid
         loop: "{{ services }}"
         async: "{{ test_duration_seconds + 10 }}"
         poll: 0
         register: monitor_jobs
   ```

2. **Trigger Certificate Rotation During Monitoring**

   ```yaml
   - name: Wait for monitors to stabilize
     ansible.builtin.pause:
       seconds: 10

   - name: Trigger certificate rotation
     ansible.builtin.include_role:
       name: cert_rotation
     vars:
       force_renewal: true
       services_to_rotate:
         - consul
         - nomad
         - vault

   - name: Record rotation timestamp
     ansible.builtin.set_fact:
       rotation_timestamp: "{{ ansible_date_time.iso8601 }}"
   ```

3. **Validate Workload Continuity**

   ```yaml
   - name: Deploy test workload before rotation
     ansible.builtin.shell: |
       # Deploy test Nomad job
       cat > /tmp/test-job.nomad << 'EOF'
       job "availability-test" {
         datacenters = ["dc1"]
         type = "service"

         group "test" {
           count = 3

           task "probe" {
             driver = "docker"

             config {
               image = "curlimages/curl:latest"
               command = "sh"
               args = ["-c", "while true; do curl -s consul.service.consul:8500/v1/status/leader; sleep 1; done"]
             }

             resources {
               cpu    = 100
               memory = 64
             }
           }
         }
       }
       EOF
       nomad job run /tmp/test-job.nomad
     register: test_job

   - name: Monitor job status during rotation
     ansible.builtin.shell: |
       for i in {1..60}; do
         nomad job status availability-test -json | jq -r '.Status'
         sleep 5
       done
     register: job_status

   - name: Verify job remained running
     ansible.builtin.assert:
       that:
         - "'dead' not in job_status.stdout"
         - "'pending' not in job_status.stdout"
       fail_msg: "Test job was disrupted during certificate rotation!"
   ```

4. **Collect and Analyze Results**

   ```yaml
   - name: Wait for all monitors to complete
     ansible.builtin.async_status:
       jid: "{{ item.ansible_job_id }}"
     loop: "{{ monitor_jobs.results }}"
     register: monitor_results
     until: monitor_results.finished
     retries: "{{ (test_duration_seconds / 10) | int }}"
     delay: 10

   - name: Collect monitoring results
     ansible.builtin.shell: |
       for service in consul nomad vault; do
         if [[ -f /tmp/${service}-monitor.json ]]; then
           cat /tmp/${service}-monitor.json
         fi
       done
     register: availability_results

   - name: Parse and validate results
     ansible.builtin.set_fact:
       validation_results: |
         {% set results = [] %}
         {% for line in availability_results.stdout_lines %}
           {% if line | regex_search('{.*}') %}
             {% set _ = results.append(line | from_json) %}
           {% endif %}
         {% endfor %}
         {{ results }}

   - name: Assert zero-downtime achieved
     ansible.builtin.assert:
       that:
         - item.uptime | float >= 99.9
       fail_msg: "Service {{ item.service }} had {{ 100 - item.uptime | float }}% downtime!"
     loop: "{{ validation_results }}"
   ```

5. **Generate Validation Report**

   ```yaml
   - name: Generate validation report
     ansible.builtin.template:
       src: zero-downtime-report.j2
       dest: /var/log/cert-rotation-validation-{{ ansible_date_time.epoch }}.html
     vars:
       report_data:
         timestamp: "{{ rotation_timestamp }}"
         duration: "{{ test_duration_seconds }}"
         services: "{{ validation_results }}"
         workload_status: "{{ job_status.stdout_lines[-1] | default('unknown') }}"

   - name: Display summary
     ansible.builtin.debug:
       msg: |
         === Zero-Downtime Validation Results ===
         Test Duration: {{ test_duration_seconds }} seconds
         Rotation Time: {{ rotation_timestamp }}

         Service Availability:
         {% for service in validation_results %}
         - {{ service.service }}: {{ service.uptime }}% uptime ({{ service.failure }} failures)
         {% endfor %}

         Workload Impact: {{ 'None' if 'running' in job_status.stdout else 'Disruption detected' }}

         Result: {{ 'PASSED' if validation_results | selectattr('uptime', '<', 99.9) | list | length == 0 else 'FAILED' }}
   ```

## Success Criteria

- [ ] All services maintain 99.9%+ availability during rotation
- [ ] No connection drops detected
- [ ] Running jobs/tasks unaffected
- [ ] Certificate rotation completes successfully
- [ ] Health checks pass throughout process

## Validation

```bash
# Run validation suite
ansible-playbook playbooks/infrastructure/vault/validate-zero-downtime.yml

# Check failure logs
for service in consul nomad vault; do
  echo "=== $service failures ==="
  cat /tmp/${service}-failures.log 2>/dev/null || echo "No failures"
done

# View validation report
ls -la /var/log/cert-rotation-validation-*.html
```

## Performance Benchmarks

- **Availability Target**: 99.9% (allows ~18 seconds downtime in 5 minutes)
- **Maximum Rotation Time**: 30 seconds per service
- **Connection Drop Tolerance**: 0
- **Job Disruption Tolerance**: 0

## Notes

- Run validation in test environment first
- Monitor production closely during first rotation
- Keep validation reports for compliance
- Consider gradual rollout for large clusters
