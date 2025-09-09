# ADR-2025-08-31: Comprehensive Smoke Testing Framework for Infrastructure Playbooks

![Status](https://img.shields.io/badge/Status-Accepted-green)
![Date](https://img.shields.io/badge/Date-2025--08--31-lightgrey)
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration?path=docs%2Fproject-management%2Fdecisions%2FADR-2025-08-31-playbook-smoke-tests.md&display_timestamp=author&style=plastic&logo=github)

## Status

Accepted

## Context

As our infrastructure automation grows more complex with HashiCorp Vault, Consul, Nomad, and other critical services, we need a standardized way to verify that all prerequisites are met before running production playbooks. Currently, operators must manually check multiple conditions:

- Network connectivity to target hosts
- Authentication credentials availability and validity
- Service states (sealed/unsealed, initialized, running)
- Required permissions and policies
- Infrastructure dependencies
- Available disk space and resources

Running production playbooks without these checks can lead to:

- Failed deployments that leave infrastructure in inconsistent states
- Time wasted troubleshooting issues that could have been detected early
- Potential security risks from partial configurations
- Difficulty onboarding new team members who don't know all prerequisites

## Decision

We will implement comprehensive smoke test playbooks for each major infrastructure component that verify all prerequisites before allowing production operations to proceed. These smoke tests will:

1. **Always perform actual tests** - Never simulate or skip tests, even in check mode
2. **Provide actionable feedback** - Each failure must include specific next steps
3. **Test both connectivity AND authentication** - Verify not just that services are reachable, but that we can authenticate and perform operations
4. **Handle sensitive data appropriately** - Differentiate between operational secrets (test regularly) and recovery secrets (verify existence only)
5. **Be easily executable** - Integrate with mise tasks for single-command execution

The Vault smoke test implementation serves as the reference pattern with:

- 12+ comprehensive test categories
- Smart handling of recovery keys (existence check by default, retrieval optional)
- Integration with Infisical for secrets management
- Clear pass/fail reporting with actionable next steps

## Consequences

### Positive

- **Early detection of issues** - Problems are caught before production playbooks run, preventing partial deployments
- **Reduced debugging time** - Clear diagnostic output identifies exactly what's wrong
- **Better onboarding** - New operators can quickly verify their environment is properly configured
- **Standardized validation** - Consistent approach across all infrastructure components
- **CI/CD ready** - Smoke tests can be integrated into automated pipelines
- **Single command execution** - `mise run smoke-vault` provides instant infrastructure validation

### Negative

- **Additional maintenance** - Smoke tests must be updated when infrastructure changes
- **Increased execution time** - Adds 30-60 seconds before production playbooks
- **Potential for false positives** - Overly strict tests might block valid operations

### Risks

- **Security exposure** - Smoke tests that are too verbose might leak sensitive information
- **Test drift** - Smoke tests might not keep pace with infrastructure changes
- **Over-reliance** - Teams might skip manual verification assuming smoke tests catch everything

Mitigation strategies:

- Use `no_log` for sensitive operations
- Include smoke test updates in PR reviews
- Document that smoke tests are first-line, not only-line, validation

## Alternatives Considered

### Alternative 1: Manual Checklists

- Description: Maintain documentation with manual pre-flight checklists
- Why we didn't choose it: Prone to human error, not enforceable, difficult to maintain

### Alternative 2: Simple Connectivity Tests Only

- Description: Just test network connectivity with basic ping/curl commands
- Why we didn't choose it: Doesn't validate authentication, permissions, or service states

### Alternative 3: Integrated Pre-Flight Checks in Each Playbook

- Description: Add validation tasks at the beginning of each production playbook
- Why we didn't choose it: Leads to duplication, makes playbooks longer, harder to maintain

### Alternative 4: External Monitoring Solution

- Description: Use Prometheus/Grafana or similar to monitor prerequisites
- Why we didn't choose it: Adds infrastructure dependency, doesn't test actual authentication

## Implementation

Key steps to implement this decision:

1. **Create smoke test playbook template** based on Vault implementation
2. **Implement smoke tests for each major component**:
   - ✅ Vault (completed as reference implementation)
   - Consul (pending)
   - Nomad (pending)
   - DNS/IPAM (pending)
   - Proxmox (pending)
3. **Add mise tasks** for easy execution
4. **Document in component READMEs** with usage examples
5. **Integrate into CI/CD pipelines** for automated validation
6. **Create troubleshooting guides** for common smoke test failures

### Smoke Test Structure Pattern

```yaml
# Standard structure for all smoke tests
- Core connectivity tests (network, SSH)
- Authentication verification (tokens, credentials)
- Service state validation (running, initialized, sealed/unsealed)
- Permission checks (required capabilities)
- Secret availability (operational vs recovery)
- Operational tests (write/read, API calls)
- Infrastructure dependencies (disk space, ports, related services)
- Comprehensive summary with actionable next steps
```

## References

- [Vault Smoke Test Implementation](../../../playbooks/infrastructure/vault/smoke-test.yml)
- [Vault README with Smoke Test Documentation](../../../playbooks/infrastructure/vault/README.md)
- [Infisical Integration Guide](../../implementation/infisical/infisical-complete-guide.md)
- [GitHub Issue #99: Migrate vault-master-lloyd to Production Mode](https://github.com/basher83/andromeda-orchestration/issues/99)
- Industry best practice: [Google SRE Book - Testing for Reliability](https://sre.google/sre-book/testing-reliability/)
