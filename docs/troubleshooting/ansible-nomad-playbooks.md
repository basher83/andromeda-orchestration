# Ansible-Nomad Playbook Troubleshooting Guide

This guide documents common issues encountered when running Ansible playbooks for Nomad deployment and their solutions.

## Table of Contents

1. [Dependency Issues](#dependency-issues)
2. [Privilege Escalation Problems](#privilege-escalation-problems)
3. [Variable Recursion Errors](#variable-recursion-errors)
4. [API Response Structure Issues](#api-response-structure-issues)
5. [Environment and Path Issues](#environment-and-path-issues)
6. [Quick Reference Commands](#quick-reference-commands)

---

## Dependency Issues

### Issue: Missing Python Dependencies

**Symptoms:**
```
Failed to import the required Python library (python-nomad) on [host]'s Python
```

**Root Cause:**
Missing required Python libraries for Ansible modules like `community.general.nomad_job`.

**Solution:**
Always ensure project dependencies are properly installed from `pyproject.toml`:

```bash
# Correct approach - sync all project dependencies
uv sync

# Verify key dependencies
uv run python -c "import nomad; print('python-nomad available')"
uv run python -c "import infisicalsdk; print('infisicalsdk available')"
```

**Prevention:**
- Use `uv sync` instead of manually adding individual packages
- All required dependencies are defined in `pyproject.toml`
- Dependencies include:
  - `python-nomad>=2.1.0` (for Nomad API interaction)
  - `infisicalsdk>=1.0.9` (for secrets management)

---

## Privilege Escalation Problems

### Issue: Unexpected sudo Prompts for localhost Operations

**Symptoms:**
```
Task failed: Premature end of stream waiting for become success.
>>> Standard Error
sudo: a password is required
```

**Root Cause:**
Inventory group variables set `ansible_become: true` globally, affecting localhost API operations that shouldn't require sudo.

**Solution:**
Override privilege escalation for localhost operations:

```bash
# Add to playbook command
uv run ansible-playbook playbook.yml -e ansible_become=false

# Or in playbook vars section:
vars:
  ansible_become: false
```

**Why This Happens:**
- `inventory/doggos-homelab/group_vars/all/ansible.yml` sets `ansible_become: true` by default
- This is correct for infrastructure management on remote hosts
- But localhost API calls (Nomad, Consul, Vault) don't need sudo
- Playbook-level `become: false` doesn't always override inventory settings

**Best Practice:**
- Keep `ansible_become: true` in inventory for infrastructure tasks
- Explicitly override with `-e ansible_become=false` for API-only playbooks
- Consider creating separate inventory groups for API vs infrastructure operations

---

## Variable Recursion Errors

### Issue: Recursive Template Variables

**Symptoms:**
```
Recursive loop detected in template: maximum recursion depth exceeded
```

**Root Cause:**
Variable definitions that reference themselves:

```yaml
# ❌ WRONG - causes recursion
homelab_domain: "{{ homelab_domain | default('spaceships.work', true) }}"
job_name: "{{ job_name | default('', true) }}"
```

**Solution:**
Use `hostvars` to access variables from different scopes:

```yaml
# ✅ CORRECT - no recursion
homelab_domain: "{{ hostvars[inventory_hostname]['homelab_domain'] | default('spaceships.work', true) }}"
job_name: "{{ hostvars[inventory_hostname]['job_name'] | default('', true) }}"
```

**Prevention:**
- Never define a variable in terms of itself
- Use `hostvars[inventory_hostname]['var_name']` for extra variables
- Test playbooks with and without `-e` parameters
- Be careful with `default()` filters on same-named variables

---

## API Response Structure Issues

### Issue: Incorrect Nomad API Response Handling

**Symptoms:**
```
Error while resolving value: object of type 'list' has no attribute 'Name'
```

**Root Cause:**
Assuming `nomad_job_info` returns a single object, when it actually returns a list of objects.

**API Response Structure:**
```json
// nomad_job_info always returns a list
[
  {
    "Name": "traefik",
    "Status": "running",
    "Type": "service",
    "JobSummary": {
      "Summary": {
        "traefik": {
          "Running": 1,
          "Failed": 0,
          "Queued": 0
        }
      }
    }
  }
]
```

**Solution:**
Always access the first item in the list for specific job queries:

```yaml
# ✅ CORRECT - handle list response
Status: "{{ specific_job_result.result[0].Status | default('Unknown') }}"
Running: "{{ specific_job_result.result[0].JobSummary.Summary | default({}) | json_query('*.Running') | sum | default(0) }}"

# For multiple jobs, iterate the list
{% for job in all_jobs_result.result %}
| {{ job.Name }} | {{ job.Status }} |
{% endfor %}
```

**Key Points:**
- `nomad_job_info` without `name` parameter returns all jobs (list)
- `nomad_job_info` with `name` parameter returns single job in a list `[job]`
- Always use `result[0]` for specific job data
- Use `result` directly for iteration over multiple jobs

---

## Environment and Path Issues

### Issue: Job File Not Found

**Symptoms:**
```
Task failed: Action failed: Unknown error.
stat: {"exists": false}
```

**Root Cause:**
Relative paths don't work when playbook execution directory differs from repository root.

**Solution:**
Use absolute paths for job files:

```bash
# ✅ CORRECT - absolute path
uv run ansible-playbook deploy-job.yml \
  -e job="$(pwd)/nomad-jobs/core-infrastructure/traefik.nomad.hcl"

# ❌ WRONG - relative path may fail
uv run ansible-playbook deploy-job.yml \
  -e job="nomad-jobs/core-infrastructure/traefik.nomad.hcl"
```

**Prevention:**
- Always use `$(pwd)/path/to/file` for job file parameters
- Validate file existence in playbooks with `stat` module
- Consider using `playbook_dir` variable for relative paths in playbooks

---

## Quick Reference Commands

### Environment Setup
```bash
# Set local environment
export MISE_ENV=local
eval "$(mise env)"

# Verify environment variables
echo "NOMAD_ADDR: ${NOMAD_ADDR}"
echo "CONSUL_HTTP_ADDR: ${CONSUL_HTTP_ADDR}"
echo "VAULT_ADDR: ${VAULT_ADDR}"
```

### Dependency Management
```bash
# Sync all project dependencies
uv sync

# Verify key dependencies
uv run python -c "import nomad, infisicalsdk; print('All dependencies available')"
```

### Deployment Commands
```bash
# Deploy job with proper overrides
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job="$(pwd)/nomad-jobs/core-infrastructure/traefik.nomad.hcl" \
  -e ansible_become=false

# Check specific job status
uv run ansible-playbook playbooks/assessment/nomad-job-status.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e job_name=traefik \
  -e ansible_become=false

# Check all jobs
uv run ansible-playbook playbooks/assessment/nomad-job-status.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e ansible_become=false
```

### Testing Connectivity
```bash
# Test simple localhost connection
uv run ansible localhost \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -m ping \
  --extra-vars "ansible_become=false"

# Verify services in Consul
consul catalog services

# Check Nomad job status directly
nomad job status
nomad job status traefik
```

---

## Debugging Tips

### Enable Verbose Output
```bash
# Add -v for basic verbosity
uv run ansible-playbook playbook.yml -v

# Add -vvv for detailed debugging
uv run ansible-playbook playbook.yml -vvv
```

### Test Variable Resolution
```bash
# Test variable access
uv run ansible localhost -m debug -a "var=homelab_domain" \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### Validate Inventory
```bash
# List inventory hosts
uv run ansible-inventory -i inventory/doggos-homelab/infisical.proxmox.yml --list

# Test inventory connectivity
uv run ansible all -i inventory/doggos-homelab/infisical.proxmox.yml -m ping
```

---

## Common Error Patterns

| Error Message | Likely Cause | Solution |
|---------------|--------------|----------|
| `sudo: a password is required` | Global `ansible_become=true` | Add `-e ansible_become=false` |
| `Recursive loop detected` | Variable self-reference | Use `hostvars[inventory_hostname]` |
| `object of type 'list' has no attribute` | Wrong API response structure | Use `result[0]` for single job |
| `Failed to import python-nomad` | Missing dependencies | Run `uv sync` |
| `stat: {"exists": false}` | Wrong file path | Use absolute paths with `$(pwd)` |
| `infisicalsdk not found` | Missing secrets dependency | Ensure `uv sync` completed |

---

## Lessons Learned

1. **Dependency Management**: Always use `pyproject.toml` and `uv sync` instead of manual package installation
2. **Privilege Escalation**: Inventory-level settings override playbook settings; use explicit overrides
3. **Variable Scoping**: Avoid recursive variable definitions; use `hostvars` for clarity
4. **API Structures**: Always check API documentation for response formats; Nomad returns lists
5. **Path Resolution**: Use absolute paths for cross-directory operations
6. **Testing Strategy**: Test both success and failure cases; test with and without parameters

This troubleshooting guide should help resolve most common issues when working with Ansible-Nomad playbooks in this infrastructure.
