# ADR-2025-08-27: HashiCorp Service Status Check Implementation Strategy

![Status](https://img.shields.io/badge/Status-Accepted-green)
![Date](https://img.shields.io/badge/Date-2025--08--27-lightgrey)
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/docs/project-management/decisions/ADR-2025-08-27-hashicorp-service-status-checks.md)

## Status

Accepted

## Context

The project needs reliable status checks for HashiCorp services (Consul, Nomad, Vault) to ensure developers can verify connectivity and authentication before beginning work. Currently:

1. **Authentication is required**: All three services have ACLs/authentication enabled
   - Consul: ACL system with tokens (403 errors on `consul info` without token)
   - Nomad: ACL system planned/enabled
   - Vault: Token-based authentication required

2. **Current implementation has issues**:
   - Mise tasks use unauthenticated commands that fail or hang
   - Logic errors cause false negatives (reporting "cannot connect" when actually connected)
   - No distinction between "service is up" vs "I can authenticate"

3. **Secrets are managed via Infisical**:
   - Tokens stored at paths like `/apollo-13/consul/`, `/apollo-13/vault/`
   - Ansible playbooks already retrieve these tokens successfully
   - Developer machines need these tokens for authenticated operations

## Decision

We will implement a **dual-approach strategy**:

1. **Quick connectivity checks** via mise tasks (unauthenticated)
   - Fast feedback for basic "is the service reachable?" questions
   - Uses commands that don't require authentication
   - Sub-second response times

2. **Full authenticated checks** via Ansible playbooks
   - Comprehensive verification including authentication
   - Leverages existing Infisical integration patterns
   - Provides detailed health assessment from multiple perspectives

## Consequences

### Positive

- **Clear separation of concerns**: Connectivity vs authentication checks
- **Security**: Authentication tokens remain in Infisical, never exposed in shell environment
- **Consistency**: Single authentication pattern across all infrastructure code
- **Fast developer feedback**: Quick checks for iterative development
- **Comprehensive validation**: Full checks when preparing for deployments
- **Future-proof**: Pattern scales as more services are added

### Negative

- **Two patterns to maintain**: Both mise tasks and Ansible playbooks
- **Slightly more complex**: Developers need to understand when to use which approach
- **Ansible dependency**: Full checks require working Ansible environment

### Risks

- **Confusion about which to use**: Mitigated by clear documentation and naming
- **Drift between approaches**: Mitigated by regular testing of both patterns
- **Performance of Ansible checks**: Accepted trade-off for security and consistency

## Alternatives Considered

### Alternative 1: Pure Mise/Binary Approach

- **Description**: Fetch tokens from Infisical directly in mise tasks, use authenticated binary commands
- **Why we didn't choose it**:
  - Would require token management in shell environment (security risk)
  - Each service has different auth patterns to handle
  - Duplicates existing working Ansible patterns

### Alternative 2: Pure Ansible Approach

- **Description**: All status checks through Ansible playbooks only
- **Why we didn't choose it**:
  - Too slow for quick iterative development checks (5-10 second overhead)
  - Overkill for simple "is it up?" questions
  - Poor developer experience for rapid feedback

### Alternative 3: Custom Status Check Tool

- **Description**: Write a dedicated Go/Python tool for status checks
- **Why we didn't choose it**:
  - Adds another tool to maintain
  - Doesn't leverage existing infrastructure
  - Increases project complexity unnecessarily

## Implementation

Key steps to implement this decision:

1. **Fix mise status tasks**:
   - Use `consul members` instead of `consul info` (no auth required)
   - Correct logic errors in connectivity checks
   - Add clear comments about unauthenticated nature

2. **Create authenticated assessment playbook**:
   - `playbooks/assessment/quick-status.yml` for all three services
   - Use existing Infisical lookup patterns
   - Provide both summary and detailed output options

3. **Update mise configuration**:
   - Rename current tasks to `status:quick:*` for clarity
   - Add `status:full` task that runs Ansible playbook
   - Document both approaches in task descriptions

4. **Update documentation**:
   - CLAUDE.md with usage examples
   - README with quick start for status checks
   - Inline comments in affected files

## References

- [Consul ACL Documentation](https://developer.hashicorp.com/consul/docs/security/acl)
- [Nomad ACL Documentation](https://developer.hashicorp.com/nomad/docs/concepts/acl)
- [Vault Authentication Documentation](https://developer.hashicorp.com/vault/docs/auth)
- [Infisical Ansible Collection](https://galaxy.ansible.com/infisical/vault)
- Existing implementation: `playbooks/assessment/consul-assessment.yml`
