# Consul KV Templating Issues in Nomad Jobs

## Overview

This guide covers troubleshooting Consul KV access issues in Nomad job templates, particularly the "Template failed: Permission denied" errors.

## Issue Summary

**Symptoms:**

- Nomad jobs fail to deploy with template errors
- Error messages like: `Template failed: kv.block(path/key): Permission denied`
- Jobs that use `{{ key "path/to/key" }}` syntax fail to render templates

**Root Cause:**
Missing `key_prefix` read permissions in Consul ACL policies for Nomad agents.

## Quick Fix (Resolved August 10, 2025)

The issue has been resolved through enhanced Consul ACL policies. If you encounter this issue:

### 1. Verify Current ACL Policies

```bash
# Check if nomad-client policy has KV access
consul acl policy read -name nomad-client

# Check if nomad-server policy has KV access
consul acl policy read -name nomad-server

# Look for this section in both policies:
# key_prefix "" {
#   policy = "read"
# }
```

### 2. Apply the Fix

Use the infrastructure playbook to update ACL policies:

```bash
# Update all Nomad ACL policies with KV access
uv run ansible-playbook playbooks/infrastructure/consul-nomad/update-all-nomad-acl-policies.yml \
  -i inventory/doggos-homelab/infisical.proxmox.yml
```

### 3. Verify the Fix

```bash
# Check that both policies now include KV access
consul acl policy read -name nomad-client | grep -A 3 "key_prefix"
consul acl policy read -name nomad-server | grep -A 3 "key_prefix"

# Test with a simple Nomad job that uses KV templating
nomad job run nomad-jobs/platform-services/powerdns-auth.nomad.hcl
```

## Detailed Troubleshooting

### Check Nomad Allocation Logs

```bash
# Find the failed allocation
nomad job status <job-name>
nomad alloc status <allocation-id>

# Check the specific error
nomad alloc logs <allocation-id>
```

### Verify Consul KV Data Exists

```bash
# Check that the KV keys referenced in templates exist
consul kv get <path/to/key>

# List all keys in a path
consul kv get -recurse <path/>
```

### Test Template Rendering Manually

```bash
# Test Consul template rendering outside of Nomad
consul-template -template="input.tmpl:output.txt:echo done" -once

# Where input.tmpl contains:
# database_host={{ key "pdns/db/host" }}
```

### Check ACL Token Permissions

```bash
# Verify the token being used by Nomad has the right permissions
consul acl token read -id <token-id>

# Check what policies are attached
consul acl token list | grep nomad
```

## Prevention

### Proper ACL Policy Templates

Use the standardized policy templates in the Nomad role:

**Server Policy** (`roles/nomad/files/consul-policies/nomad-server.hcl`):

```hcl
# Allow reading from KV store for templating
key_prefix "" {
  policy = "read"
}
```

**Client Policy** (`roles/nomad/files/consul-policies/nomad-client.hcl`):

```hcl
# CRITICAL: Allow reading from KV store for templating in jobs
key_prefix "" {
  policy = "read"
}
```

### Job Template Best Practices

1. **Always test KV keys exist before deploying:**

```bash
consul kv get pdns/db/host  # Should return a value
```

1. **Use proper template syntax:**

```hcl
template {
  data = <<EOT
    database_host={{ key "pdns/db/host" }}
    database_port={{ key "pdns/db/port" }}
  EOT
  destination = "local/config.env"
}
```

1. **Include error handling in templates:**

```hcl
database_host={{ key_or_default "pdns/db/host" "localhost" }}
```

## Verification Commands

### End-to-End Test

```bash
# 1. Deploy a test job with KV templating
cat > test-kv-job.nomad.hcl <<EOF
job "test-kv" {
  datacenters = ["dc1"]
  type = "batch"

  group "test" {
    task "test" {
      driver = "docker"
      config {
        image = "alpine:latest"
        command = "cat"
        args = ["/local/test.txt"]
      }

      template {
        data = <<EOT
Test KV Value: {{ key "pdns/db/host" }}
        EOT
        destination = "local/test.txt"
      }
    }
  }
}
EOF

# 2. Run the job
nomad job run test-kv-job.nomad.hcl

# 3. Check if it succeeds
nomad job status test-kv

# 4. Clean up
nomad job stop test-kv
```

## Related Issues

- **Service Identity Token Issues**: If you're having broader Consul integration issues, see [Service Identity Issues](service-identity-issues.md)
- **Vault Integration**: For Vault secret templating issues, see the Vault documentation

## Historical Context

This issue was discovered during PowerDNS deployment on August 10, 2025, when jobs using `{{ key "pdns/db/host" }}` syntax failed with permission denied errors. The fix involved:

1. Identifying missing KV permissions in ACL policies
2. Creating standardized policy templates in the Nomad role
3. Building infrastructure playbooks to manage ACL policies
4. Verifying the fix across all 6 Nomad nodes

## References

- [Consul ACL Policies](https://developer.hashicorp.com/consul/docs/security/acl/acl-policies)
- [Nomad Template Stanza](https://developer.hashicorp.com/nomad/docs/job-specification/template)
- [Infrastructure Playbooks](../../playbooks/infrastructure/consul-nomad/)
