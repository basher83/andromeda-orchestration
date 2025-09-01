# Smoke Testing Procedures

## Overview

This guide provides operational procedures for running, interpreting, and troubleshooting smoke tests across all infrastructure components. Following industry best practices for Infrastructure as Code (IaC), smoke tests serve as mandatory validation gates that verify basic functionality and connectivity of provisioned infrastructure immediately after deployment.

## Quick Start

### Running Smoke Tests

```bash
# Using mise tasks (recommended)
mise run smoke-vault        # Test Vault infrastructure
mise run smoke-consul       # Test Consul cluster (pending)
mise run smoke-nomad        # Test Nomad cluster (pending)
mise run smoke-dns          # Test DNS/IPAM (pending)

# Direct execution
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
      -i inventory/environments/vault-cluster/production.yaml

# With verbose output for troubleshooting
mise run smoke-vault-verbose

# Test recovery keys (Vault-specific, requires authorization)
mise run smoke-vault-recovery
```

## Component-Specific Procedures

### Vault Smoke Testing

#### Standard Run

```bash
mise run smoke-vault
```

Expected output:

```text
🔥 Running Vault smoke tests...
PLAY [Comprehensive Vault Smoke Tests] *************************

TASK [SMOKE TEST 1: Verify Infisical environment variables] ****
ok: [localhost] => ✅ PASSED: Infisical environment variables loaded

[... 12 test categories ...]

TASK [SMOKE TEST SUMMARY] ***************************************
ok: [localhost] =>
  🎯 SMOKE TEST COMPLETE
  ✅ 12/12 tests passed
  🚀 Vault infrastructure is ready for operations
```

#### Troubleshooting Failed Tests

#### Test 1 Failed: Infisical Variables

```text
❌ FAILED: Infisical environment variables not found
```

Resolution:

1. Check `.mise.local.toml` contains Infisical configuration
2. Verify Infisical CLI is authenticated: `infisical auth status`
3. Reload environment: `mise trust && eval "$(mise env)"`

#### Test 3 Failed: SSH Connectivity

```text
❌ FAILED: Cannot connect to vault-master-lloyd via SSH
```

Resolution:

1. Verify SSH key is loaded: `ssh-add -l`
2. Test manual connection: `ssh ubuntu@vault-master-lloyd`
3. Check network connectivity: `ping vault-master-lloyd`
4. Verify Tailscale status: `tailscale status`

#### Test 6 Failed: Vault API Access

```text
❌ FAILED: Cannot access Vault API
```

Resolution:

1. Check Vault service status: `ssh vault-master-lloyd 'sudo systemctl status vault'`
2. Verify port accessibility: `nc -zv vault-master-lloyd 8200`
3. Check TLS certificates if HTTPS is configured
4. Review Vault logs: `ssh vault-master-lloyd 'sudo journalctl -u vault -n 50'`

### Consul Smoke Testing (Pending Implementation)

Expected test categories:

- Consul agent connectivity
- Cluster health status
- ACL token validity
- DNS resolution
- Service discovery
- Key-value store access

### Nomad Smoke Testing (Pending Implementation)

Expected test categories:

- Nomad server connectivity
- Cluster status
- Job submission capability
- Docker driver availability
- Volume plugin status
- Consul integration

## Interpreting Results

### Success Indicators

✅ **All Green**: Ready for production operations

```text
✅ 12/12 tests passed
🚀 Infrastructure is ready for operations
```

### Warning Indicators

⚠️ **Non-Critical Failures**: May proceed with caution

- Recovery key verification skipped (expected in standard run)
- Optional features not configured
- Performance warnings

### Failure Indicators

❌ **Critical Failures**: Block all operations

- Authentication failures
- Network connectivity issues
- Service unavailability
- Permission denied errors

## CI/CD Integration

### GitHub Actions

```yaml
name: Infrastructure Validation

on:
  pull_request:
    paths:
      - 'playbooks/infrastructure/**'
      - 'inventory/**'

jobs:
  smoke-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup mise
        run: |
          curl -fsSL https://mise.run | sh
          mise install

      - name: Run Vault Smoke Tests
        run: mise run smoke-vault
        env:
          INFISICAL_UNIVERSAL_AUTH_CLIENT_ID: ${{ secrets.INFISICAL_CLIENT_ID }}
          INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET: ${{ secrets.INFISICAL_CLIENT_SECRET }}

      - name: Upload Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: smoke-test-results
          path: smoke-test-results.json
```

### GitLab CI

```yaml
smoke-tests:
  stage: validate
  script:
    - mise run smoke-vault
    - mise run smoke-consul
    - mise run smoke-nomad
  only:
    changes:
      - playbooks/infrastructure/**
      - inventory/**
  artifacts:
    reports:
      junit: smoke-test-results.xml
```

## Advanced Usage

### Custom Test Selection

```bash
# Run specific test categories
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
      -i inventory/environments/vault-cluster/production.yaml \
      --tags "connectivity,authentication"

# Skip certain tests
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
      -i inventory/environments/vault-cluster/production.yaml \
      --skip-tags "recovery_keys"
```

### Parallel Testing

```bash
# Test multiple components concurrently
parallel -j 3 ::: \
  "mise run smoke-vault" \
  "mise run smoke-consul" \
  "mise run smoke-nomad"
```

### JSON Output for Automation

```bash
# Generate machine-readable output
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
      -i inventory/environments/vault-cluster/production.yaml \
      -e "output_format=json" > smoke-results.json
```

## Industry Best Practices Integration

### IaC Testing Layers

Our smoke tests validate across three critical layers as per industry standards:

1. **Infrastructure Layer** (Post-Terraform/OpenTofu)
   - Resource existence and accessibility
   - Network connectivity and routing
   - Security group and firewall rules
   - DNS resolution

2. **Platform Layer** (Post-Ansible)
   - Service installation and status
   - Configuration file integrity
   - User and permission setup
   - Package dependencies

3. **Application Layer** (End-to-End)
   - API endpoint availability
   - Health check responses
   - Inter-service communication
   - Data flow validation

### Testing Patterns

#### Pattern: Progressive Enhancement

```yaml
# Start simple, add complexity
Level 1: Basic connectivity (ping, port check)
Level 2: Authentication (token validation)
Level 3: Operations (read/write tests)
Level 4: Integration (service interactions)
```

#### Pattern: Fail-Fast with Context

```yaml
# Fail quickly but provide maximum information
- Quick timeout (5-10 seconds)
- Detailed error messages
- Suggested remediation steps
- Related diagnostic commands
```

### Molecule Integration (Future)

For Ansible role testing, we plan to integrate Molecule:

```yaml
# Future: molecule/default/molecule.yml
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: vault-test
    image: ubuntu:22.04
provisioner:
  name: ansible
verifier:
  name: ansible
  directory: ./tests
```

### Terraform Test Integration (Future)

For infrastructure validation, we plan to use Terraform's native testing:

```hcl
# Future: tests/smoke.tftest.hcl
run "validate_vault_infrastructure" {
  command = apply

  assert {
    condition     = module.vault.instance_state == "running"
    error_message = "Vault instance is not running"
  }
}
```

## Maintenance Procedures

### Updating Smoke Tests

When infrastructure changes:

1. **Identify affected tests**

   ```bash
   grep -r "affected_component" playbooks/infrastructure/*/smoke-test.yml
   ```

2. **Update test logic**
   - Modify assertions for new requirements
   - Add new test categories if needed
   - Update success/failure messages

3. **Test the tests**

   ```bash
   # Run in check mode first
   uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
         -i inventory/environments/vault-cluster/production.yaml \
         --check
   ```

4. **Document changes**
   - Update this guide if procedures change
   - Update component README
   - Note in CHANGELOG

### Creating New Smoke Tests

For new components:

1. **Copy template structure** from Vault implementation
2. **Identify test categories** (minimum 10 required)
3. **Implement test playbook** at `playbooks/infrastructure/<component>/smoke-test.yml`
4. **Add mise task** in `.mise.toml`
5. **Update documentation**:
   - Component README
   - This operations guide
   - Testing standards tracker

## Troubleshooting Guide

### Common Issues

#### Environment Variables Not Loading

**Symptom**: Multiple Infisical-related test failures

**Solution**:

```bash
# Reload mise environment
mise trust
eval "$(mise env)"

# Verify variables are set
env | grep INFISICAL

# Re-authenticate if needed
infisical login
```

#### SSH Key Issues

**Symptom**: SSH connectivity tests fail

**Solution**:

```bash
# Add SSH key to agent
ssh-add ~/.ssh/id_ed25519

# Verify key is loaded
ssh-add -l

# Test connection manually
ssh -v ubuntu@target-host
```

#### Network Connectivity

**Symptom**: API access tests fail despite services running

**Solution**:

```bash
# Check Tailscale connectivity
tailscale status
tailscale ping target-host

# Verify DNS resolution
nslookup target-host
dig target-host

# Test port accessibility
nc -zv target-host 8200
```

### Debug Mode

Enable maximum verbosity for troubleshooting:

```bash
# Ansible debug output
ANSIBLE_VERBOSITY=4 mise run smoke-vault

# With specific test output
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
      -i inventory/environments/vault-cluster/production.yaml \
      -vvvv \
      -e "verbose_output=true"
```

## Performance Considerations

### Timeout Settings

Default timeouts:

- SSH connection: 10 seconds
- API requests: 5 seconds
- Service checks: 30 seconds

Adjust for slow networks:

```yaml
-e "ssh_timeout=30" \
-e "api_timeout=10"
```

### Caching

Smoke tests may cache certain results:

- Infisical token: 1 hour
- Network connectivity: Not cached
- Service status: Not cached

Clear cache if needed:

```bash
rm -rf ~/.ansible/tmp/smoke-test-cache/
```

## Security Considerations

### Sensitive Data Handling

- **Never log tokens or passwords** - All sensitive operations use `no_log: true`
- **Recovery keys** - Only test existence by default
- **Audit logs** - Smoke test runs are logged to audit trail
- **Minimal permissions** - Use read-only tokens where possible

### Authorization Requirements

Different test levels require different permissions:

| Test Level | Required Permission | Use Case |
|------------|-------------------|----------|
| Basic | Read-only access | Daily validation |
| Standard | Operator access | Pre-deployment |
| Full | Admin access | Recovery key tests |

## Reporting

### Generate Reports

```bash
# HTML report
mise run smoke-vault-report

# JSON for monitoring systems
mise run smoke-vault-json > /var/log/smoke-tests/vault-$(date +%Y%m%d).json

# Send to monitoring
mise run smoke-vault-json | curl -X POST https://monitoring.example.com/api/smoke-tests \
  -H "Content-Type: application/json" \
  -d @-
```

### Metrics to Track

- Test execution time
- Pass/fail rate per category
- Frequency of specific failures
- Time to resolution
- False positive rate

## References

### Internal Documentation

- [Testing Standards](../standards/testing-standards.md)
- [IaC Smoke Testing Theory](../standards/iac-smoke-testing-theory.md)
- [ADR: Smoke Testing Framework](../project-management/decisions/ADR-2025-08-31-playbook-smoke-tests.md)
- [Vault Smoke Test Implementation](../../playbooks/infrastructure/vault/smoke-test.yml)
- [Vault Operations README](../../playbooks/infrastructure/vault/README.md)

### Industry Resources

- [HashiCorp: Testing Terraform](https://www.hashicorp.com/blog/testing-hashicorp-terraform)
- [Ansible Molecule Documentation](https://ansible.readthedocs.io/projects/molecule/)
- [AWS: Terraform CI/CD and Testing](https://aws.amazon.com/blogs/devops/terraform-ci-cd-and-testing-on-aws-with-the-new-terraform-test-framework/)
- [Google SRE: Testing for Reliability](https://sre.google/sre-book/testing-reliability/)

## Quick Reference Card

```bash
# Most Common Commands
mise run smoke-vault              # Run Vault smoke tests
mise run smoke-vault-verbose      # With detailed output
mise run smoke-vault-recovery     # Include recovery key tests

# Troubleshooting
mise trust && eval "$(mise env)"  # Reload environment
ssh-add ~/.ssh/id_ed25519         # Add SSH key
tailscale status                  # Check VPN status

# Help
mise tasks | grep smoke           # List all smoke test tasks
ansible-playbook --list-tags      # Show available test tags
