# ADR-2025-01-27: Infrastructure Repository Separation Strategy

![Status](https://img.shields.io/badge/Status-Accepted-green)
![Date](https://img.shields.io/badge/Date-2025--01--27-lightgrey)
![Last Updated](https://img.shields.io/github/last-commit/basher83/andromeda-orchestration/main/docs/project-management/decisions/ADR-2025-01-27-infrastructure-repository-separation.md)

## Status

Accepted

## Context

The infrastructure management was becoming complex with multiple tools and layers:

- Terraform for infrastructure provisioning (VMs, networks, storage)
- Ansible for configuration management and service deployment
- Nomad for container orchestration
- Scalr for Terraform workflow automation

Initially, infrastructure and configuration were mixed across repositories, leading to:

- Unclear boundaries between provisioning and configuration
- Difficult to track which repository manages what
- Complex dependencies between repositories
- Confusion about where changes should be made

## Decision

Implement a clear separation of concerns across repositories:

### Repository Responsibilities

1. **Infrastructure Repositories (Terraform)**
   - **Purpose**: VM provisioning, network setup, storage allocation
   - **Management**: Scalr with VCS-driven workflow
   - **Current Repos**:
     - `Hercules-Vault-Infra`: Vault cluster (4 VMs)
     - `terraform-homelab`: Nomad/Consul cluster (6 VMs)
   - **Pattern**: One repo per logical infrastructure unit

2. **Configuration Repository (Ansible)**
   - **Purpose**: Service configuration, application deployment
   - **Management**: Direct execution with Ansible
   - **Current Repo**: `andromeda-orchestration`
   - **Includes**: All Ansible playbooks, roles, and Nomad job specs

### Workflow Separation

```text
Terraform (Infrastructure) → Ansible (Configuration) → Nomad (Orchestration)
         ↓                            ↓                        ↓
    Provision VMs              Configure Services      Deploy Containers
    Via Scalr                  Via Playbooks          Via Jobs
```

### Naming Convention

- Infrastructure repos: `[Service]-Infra` or `[Service]-infrastructure`
- Configuration repos: `[Service]-orchestration` or `[Service]-config`
- Application repos: `[Service]-app` or just `[Service]`

## Consequences

### Positive

- Clear separation of concerns
- Each repository has a single, well-defined purpose
- Independent versioning and release cycles
- Easier to understand and maintain
- Teams can specialize (infrastructure vs configuration)
- State isolation (each Terraform repo has its own state)

### Negative

- More repositories to manage
- Cross-repository dependencies need documentation
- Deployment requires coordination between repos
- Initial learning curve for team members

### Risks

- Repository sprawl if not managed carefully
- Documentation drift between repositories
- Coordination overhead for major changes

## Alternatives Considered

### Alternative 1: Monolithic Repository

- Pros: Everything in one place, simpler to understand initially
- Rejected: Becomes unmanageable at scale, mixing concerns

### Alternative 2: Tool-Based Separation

- Separate by tool (Terraform repo, Ansible repo, etc.)
- Rejected: Doesn't align with logical service boundaries

### Alternative 3: Environment-Based Separation

- One repo per environment (dev, staging, prod)
- Rejected: Code duplication, difficult to promote changes

## Implementation

### Current State

1. ✅ Hercules-Vault-Infra: Vault infrastructure separated
2. ✅ terraform-homelab: Managing Nomad/Consul cluster
3. ✅ andromeda-orchestration: Consolidated configuration management

### Future Steps

1. ⏳ Create NetBox-Infra for dedicated NetBox VMs
2. ⏳ Create Monitoring-Infra for observability stack
3. ⏳ Consider extracting Nomad jobs to separate orchestration repo

## Success Metrics

- Deployment time reduced by 30%
- Zero cross-repository merge conflicts
- Clear ownership boundaries established
- Documentation stays in sync
- Team can identify correct repository within 5 seconds

## Migration Path

For new infrastructure components:

1. Create dedicated Terraform repository
2. Configure Scalr workspace with VCS integration
3. Document in INFRASTRUCTURE-REPOS.md
4. Add Ansible configuration to andromeda-orchestration
5. Update deployment workflows

## References

- [INFRASTRUCTURE-REPOS.md](../../INFRASTRUCTURE-REPOS.md)
- [Hercules-Vault-Infra](https://github.com/basher83/Hercules-Vault-Infra)
- [terraform-homelab](https://github.com/basher83/terraform-homelab)
- [Scalr Documentation](https://docs.scalr.io)
