# Domain Migration Troubleshooting Guide

This guide covers issues specific to the `.local` → `spaceships.work` domain migration process.

## Table of Contents

1. [HCL2 Variable Issues](#hcl2-variable-issues)
2. [Service Registration Problems](#service-registration-problems)
3. [Environment Configuration](#environment-configuration)
4. [DNS Resolution Issues](#dns-resolution-issues)
5. [Migration Validation](#migration-validation)

---

## HCL2 Variable Issues

### Issue: Nomad Parse API Returns 400 Bad Request

**Symptoms:**

```text
Warning: Failed to parse job with variables. Falling back to direct deployment.
Error: HTTP Error 400: Bad Request
```

**Root Cause:**

- HCL2 variable syntax not properly formatted
- Variable names don't match between playbook and HCL file
- Missing variable definitions in job file

**Solution:**

1. **Verify HCL2 variable syntax in job file:**

```hcl
# At the top of .nomad.hcl file
variable "homelab_domain" {
  type        = string
  default     = "spaceships.work"
  description = "The domain for the homelab environment"
}

# Usage in the job
tags = [
  "traefik.http.routers.api.rule=Host(`traefik.${var.homelab_domain}`)"
]
```

1. **Check playbook variable passing:**

```yaml
Variables:
  homelab_domain: "{{ homelab_domain }}"
  cluster_subdomain: "{{ cluster_subdomain | default('', true) }}"
  fqdn_suffix: "{{ fqdn_suffix | default('', true) }}"
```

1. **Validate manually:**

```bash
# Test HCL parsing directly
NOMAD_VAR_homelab_domain=spaceships.work nomad job plan traefik.nomad.hcl
```

**Prevention:**

- Always validate HCL syntax before deployment
- Use consistent variable names between Ansible and HCL
- Test with fallback to direct deployment (without variables)

---

## Service Registration Problems

### Issue: Services Not Appearing in Consul

**Symptoms:**

- Job shows as "running" in Nomad
- Services missing from `consul catalog services`
- Only old services (like `netdata-child`) visible

**Diagnostic Steps:**

1. **Check job allocation status:**

```bash
nomad job status traefik
nomad alloc status <allocation-id>
```

1. **Verify Consul integration:**

```bash
# Check if job has Consul service blocks
nomad job inspect traefik | grep -A 10 -B 5 service

# Test Consul connectivity from job
nomad alloc exec <allocation-id> consul members
```

1. **Check allocation logs:**

```bash
nomad alloc logs <allocation-id>
```

**Common Causes:**

1. **Missing service blocks in job:**

```hcl
# Ensure job has service registration
service {
  name = "traefik"
  port = "admin"

  check {
    name     = "traefik-api-ping"
    type     = "http"
    path     = "/ping"
    port     = "admin"
    interval = "10s"
    timeout  = "2s"
  }
}
```

1. **Consul connection issues:**

```hcl
# Check consul stanza in Nomad config
consul {
  address = "127.0.0.1:8500"
  token   = "your-token"

  auto_advertise      = true
  server_auto_join    = true
  client_auto_join    = true
  server_service_name = "nomad"
  client_service_name = "nomad-client"
}
```

**Solution:**

- Ensure service blocks are properly defined
- Verify Consul connectivity from Nomad agents
- Check Nomad-Consul integration configuration

---

## Environment Configuration

### Issue: Environment Variables Not Set After Migration

**Symptoms:**

```bash
echo $NOMAD_ADDR     # Shows old IP or empty
echo $CONSUL_HTTP_ADDR # Shows old IP or empty
```

**Root Cause:**
Environment files (`.mise.local.toml`) not properly activated or loaded.

**Solution:**

1. **Verify mise environment setup:**

```bash
# Check current environment
export MISE_ENV=local
eval "$(mise env)"

# Verify variables are set
echo "NOMAD_ADDR: ${NOMAD_ADDR}"
echo "CONSUL_HTTP_ADDR: ${CONSUL_HTTP_ADDR}"
echo "VAULT_ADDR: ${VAULT_ADDR}"
```

1. **Check mise configuration files:**

```bash
# Main config
cat .mise.toml

# Local environment config
cat .mise.local.toml
```

1. **Verify file structure:**

```toml
# .mise.local.toml should have:
[env]
NOMAD_ADDR = "http://192.168.11.11:4646"
CONSUL_HTTP_ADDR = "http://192.168.11.11:8500"
VAULT_ADDR = "http://192.168.11.11:8200"
```

**Prevention:**

- Always run `export MISE_ENV=local && eval "$(mise env)"` before operations
- Verify environment variables before running playbooks
- Use mise tasks for environment switching

---

## DNS Resolution Issues

### Issue: Services Still Resolving to Old Domains

**Symptoms:**

- Services accessible via old `.local` addresses
- New `spaceships.work` addresses not resolving
- Mixed resolution between old/new domains

**Diagnostic Steps:**

1. **Test DNS resolution:**

```bash
# Test new domain resolution
dig traefik.spaceships.work
nslookup traefik.spaceships.work

# Test from different clients
dig @192.168.11.11 traefik.doggos.spaceships.work
```

1. **Check DNS server configuration:**

```bash
# Verify DNS server settings
dig @192.168.11.11 spaceships.work SOA
dig @192.168.11.11 ns1.spaceships.work A
```

1. **Cache clearing:**

```bash
# Clear local DNS cache (macOS)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Clear cache (Linux)
sudo systemctl restart systemd-resolved
```

**Solution:**

- Verify DNS zones are properly configured in NetBox/PowerDNS
- Update client DNS server settings to point to infrastructure DNS
- Clear DNS caches on all client machines
- Test resolution from multiple client types (macOS, Linux, Windows)

---

## Migration Validation

### Issue: Uncertain Migration Status

**Symptoms:**

- Unclear which services are using new vs old domains
- Mixed environment state
- Partial migration completion

**Validation Checklist:**

1. **Verify job status:**

```bash
# Check all running jobs
uv run ansible-playbook playbooks/assessment/nomad-job-status.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e ansible_become=false
```

1. **Check service registration:**

```bash
# Count services in Consul
consul catalog services | wc -l

# Expected services after full migration:
# - consul
# - nomad, nomad-client
# - traefik, traefik-http, traefik-https, traefik-metrics
# - postgres
# - vault
# - netdata-child
# - powerdns-auth (if deployed)
```

1. **Verify domain usage:**

```bash
# Search for remaining .local references
rg '\.local' --type yaml --type hcl nomad-jobs/
rg '\.local' --type yaml playbooks/ inventory/

# Check job configurations
nomad job inspect traefik | grep -i domain
```

1. **Test connectivity:**

```bash
# Test service endpoints
curl -I http://192.168.11.11:8080/ping  # Traefik health
consul members                           # Consul cluster
nomad node status                        # Nomad cluster
```

**Success Criteria:**

- ✅ All Nomad jobs showing as "running"
- ✅ 10+ services registered in Consul
- ✅ No `.local` references in active configurations
- ✅ New domain resolution working
- ✅ All infrastructure endpoints accessible

---

## Common Migration Pitfalls

| Issue | Cause | Prevention |
|-------|--------|------------|
| Jobs fail to start after migration | Old IP addresses in config | Use variables, not hardcoded IPs |
| Services not in Consul | Missing service blocks | Always include service registration |
| DNS not resolving | Zones not propagated | Verify DNS infrastructure first |
| Mixed old/new domains | Incomplete migration | Use search tools to find all references |
| Environment not switching | Mise config issues | Test environment switching process |

---

## Post-Migration Verification

Run this complete verification sequence after migration:

```bash
# 1. Environment setup
export MISE_ENV=local
eval "$(mise env)"

# 2. Check all jobs are running
uv run ansible-playbook playbooks/assessment/nomad-job-status.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml \
  -e ansible_become=false

# 3. Verify service count
echo "Services in Consul: $(consul catalog services | wc -l)"

# 4. Test key service endpoints
curl -f http://192.168.11.11:8080/ping || echo "Traefik health check failed"
consul members > /dev/null && echo "Consul cluster healthy"
nomad node status > /dev/null && echo "Nomad cluster healthy"

# 5. Check for remaining .local references
rg '\.local' nomad-jobs/ || echo "No .local references found in jobs"

echo "✅ Migration verification complete"
```

This should confirm that your domain migration is successful and the infrastructure is running with the new `spaceships.work` domain configuration.
