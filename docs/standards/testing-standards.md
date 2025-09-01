# Testing Standards

## Purpose

Define testing strategies that ensure infrastructure readiness, prevent deployment failures, and maintain reliability through comprehensive smoke testing before any production operations.

## Background

Infrastructure as Code (IaC) requires the same rigorous testing as application code, but with unique challenges specific to infrastructure provisioning and configuration management:

- Infrastructure changes can have cascading failures across dependent resources
- Partial deployments can leave systems in inconsistent states
- Authentication and network issues are common failure points
- Manual pre-flight checks are error-prone and not scalable
- The gap between infrastructure provisioning (Terraform) and configuration (Ansible) requires multi-layer validation

### Industry Context

In modern IaC deployments, smoke tests serve as **lightweight, automated validation checks** that verify basic functionality and connectivity of provisioned infrastructure immediately after deployment. This approach is standard practice across:

- **Terraform Deployments**: Validating resource creation, network connectivity, and service endpoints
- **Ansible Configuration**: Verifying service status, application functionality, and system state
- **Combined Workflows**: Testing the complete infrastructure-to-application pipeline

Our solution: **Comprehensive Smoke Testing** as the mandatory first-line validation for all infrastructure operations, following industry best practices for IaC testing.

## Standard

### Smoke Testing Framework

Every major infrastructure component MUST have a comprehensive smoke test playbook that validates ALL prerequisites before production operations can proceed.

#### Mandatory Test Categories

All smoke tests must include these categories:

1. **Core Infrastructure Tests**
   - Network connectivity (SSH and API)
   - Authentication verification
   - Service state validation

2. **Authorization & Secrets**
   - Token/credential validity
   - Required permissions/capabilities
   - Secret availability (with appropriate handling)

3. **Operational Readiness**
   - Write/read operations
   - Port accessibility
   - Disk space and resources

4. **Dependencies**
   - Related service availability
   - Required infrastructure components
   - Version compatibility

#### Implementation Requirements

1. **Always perform actual tests** - Never simulate or use check mode
2. **Provide actionable feedback** - Each failure must include specific remediation steps
3. **Handle sensitive data appropriately**:
   - Operational secrets: Test retrieval and validity
   - Recovery secrets: Verify existence only (unless explicitly requested)
4. **Single command execution** - Integrate with mise tasks
5. **Comprehensive summary** - Clear pass/fail status with next steps

### When to Run Smoke Tests

Smoke tests are MANDATORY before:

- Running any production playbook
- After infrastructure changes or restarts
- After updating configuration or credentials
- During CI/CD pipeline execution
- When onboarding new team members
- When troubleshooting issues

### Test Naming Conventions

- Playbook: `smoke-test.yml` in component directory
- Mise task: `smoke-<component>` (e.g., `smoke-vault`, `smoke-consul`)
- Test names: `SMOKE TEST N: <Description>` with sequential numbering

### Coverage Requirements

- 100% of critical prerequisites must be tested
- Each component must have at least 10 test categories
- All authentication paths must be validated
- All required secrets must be verified (existence or retrieval)

### Pre-deployment Testing Checklist

Before ANY production deployment:

1. ✅ Run component smoke test
2. ✅ Verify all tests pass
3. ✅ Review any warnings
4. ✅ Address identified issues
5. ✅ Re-run if changes were made
6. ✅ Document any exceptions

### Testing in CI/CD

Smoke tests must be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Vault Smoke Tests
  run: mise run smoke-vault

- name: Verify Results
  run: |
    if [ $? -ne 0 ]; then
      echo "Smoke tests failed - blocking deployment"
      exit 1
    fi
```

### Test Types

#### Smoke Tests (Primary)

- **Purpose**: Validate all prerequisites before operations
- **Scope**: Comprehensive infrastructure validation across three layers:
  - **Infrastructure Layer**: Network connectivity, DNS resolution, security groups (Terraform focus)
  - **Platform Layer**: OS services, package installations, user configurations (Ansible focus)
  - **Application Layer**: Service availability, API functionality, health endpoints (Combined validation)
- **Execution**: Always run actual tests - never simulate or use check mode
- **Output**: Actionable diagnostic information with specific remediation steps
- **Timing**: Fast execution (< 60 seconds) for rapid feedback

#### Unit Tests

- For individual Ansible roles and modules
- Test specific functionality in isolation
- **Molecule Framework**: Primary tool for Ansible role testing
- **Terraform Tests**: Native `terraform test` for infrastructure modules

#### Integration Tests

- Validate multi-component interactions
- Run after smoke tests pass
- End-to-end workflow validation

#### Syntax Checks

- Pre-commit hooks for YAML/HCL validation
- Ansible playbook syntax validation
- Terraform format and validate checks

#### Security Scans

- Credential scanning (no hardcoded secrets)
- Policy compliance checks
- Infrastructure drift detection

## Rationale

Comprehensive smoke testing provides:

- **Early detection** of issues before they impact production
- **Reduced MTTR** through clear diagnostic output
- **Improved reliability** by catching configuration drift
- **Better onboarding** with self-documenting prerequisites
- **Audit compliance** through mandatory validation gates

## Examples

### Good Example - Vault Smoke Test

```yaml
# playbooks/infrastructure/vault/smoke-test.yml
- name: "SMOKE TEST 1: Verify Infisical environment variables are loaded"
  assert:
    that:
      - lookup('env', 'INFISICAL_UNIVERSAL_AUTH_CLIENT_ID') | length > 0
    fail_msg: "❌ FAILED: Infisical environment variables not found. Check .mise.local.toml"
    success_msg: "✅ PASSED: Infisical environment variables loaded"
```

**Why it's good:**

- Clear test numbering and description
- Actual validation (not simulation)
- Specific failure message with remediation
- Visual indicators (✅/❌)

### Good Example - Mise Integration

```toml
# .mise.toml
[tasks.smoke-vault]
description = "Run smoke tests for Vault"
run = '''
echo "🔥 Running smoke tests..."
uv run ansible-playbook playbooks/infrastructure/vault/smoke-test.yml \
      -i inventory/environments/vault-cluster/production.yaml
'''
```

**Why it's good:**

- Single command execution
- Clear description
- Consistent naming pattern

### Bad Example - Insufficient Testing

```yaml
- name: Check if service is running
  shell: ps aux | grep vault
  register: result
  ignore_errors: yes
```

**Why it's bad:**

- Doesn't test actual functionality
- No actionable feedback
- Can produce false positives
- Ignores errors without handling

## Implementation Status

| Component | Smoke Test Status | Mise Task | Documentation |
|-----------|------------------|-----------|---------------|
| Vault | ✅ Complete | ✅ `smoke-vault` | ✅ Complete |
| Consul | 🔜 Pending | 🔜 Pending | 🔜 Pending |
| Nomad | 🔜 Pending | 🔜 Pending | 🔜 Pending |
| DNS/IPAM | 🔜 Pending | 🔜 Pending | 🔜 Pending |
| Proxmox | 🔜 Pending | 🔜 Pending | 🔜 Pending |

## Industry Best Practices

### IaC Testing Principles

- **Fast Execution**: Keep tests lightweight for rapid feedback cycles
- **Critical Path Focus**: Test only essential functionality required for basic operation
- **Idempotent Tests**: Ensure tests can run multiple times without side effects
- **Clear Failure Messages**: Provide actionable error messages with remediation steps
- **Environment-Specific Tests**: Adapt tests for dev, staging, and production environments

### Tool-Specific Approaches

#### Ansible with Molecule

- Automated testing framework for Ansible roles and playbooks
- Multi-platform testing across different OS and container platforms
- Integration with CI/CD pipelines for continuous validation

#### Terraform Native Testing

- `check` blocks for post-apply validation without affecting resource lifecycle
- `postcondition` blocks in resources to verify infrastructure state
- `terraform test` framework for ephemeral infrastructure validation

#### Combined Workflow Testing

1. **Terraform Apply**: Provision infrastructure resources
2. **Infrastructure Smoke Tests**: Validate connectivity and resource availability
3. **Ansible Playbook Execution**: Configure provisioned resources
4. **Configuration Smoke Tests**: Verify services and applications
5. **End-to-End Validation**: Test complete workflow functionality

## References

### Internal Documentation

- [ADR-2025-08-31: Playbook Smoke Tests](../project-management/decisions/ADR-2025-08-31-playbook-smoke-tests.md)
- [Vault Smoke Test Implementation](../../playbooks/infrastructure/vault/smoke-test.yml)
- [Vault Documentation](../../playbooks/infrastructure/vault/README.md)
- [IaC Smoke Testing Theory](iac-smoke-testing-theory.md)

### External Resources

- [Google SRE: Testing for Reliability](https://sre.google/sre-book/testing-reliability/)
- [HashiCorp: Testing Terraform](https://www.hashicorp.com/blog/testing-hashicorp-terraform)
- [Ansible Molecule Documentation](https://ansible.readthedocs.io/projects/molecule/)
- [Infrastructure Testing with Ansible](https://www.augmentedmind.de/2022/12/11/infrastructure-testing-ansible/)
- [AWS: Terraform CI/CD and Testing](https://aws.amazon.com/blogs/devops/terraform-ci-cd-and-testing-on-aws-with-the-new-terraform-test-framework/)
