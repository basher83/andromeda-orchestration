# ADR-2025-08-20: Decision to Prioritize Infrastructure Configuration Application

![Status](https://img.shields.io/badge/Status-Accepted-green)
![Date](https://img.shields.io/badge/Date-2025--08--20-lightgrey)

## Status

Accepted (Superseded by ADR-2025-08-23)

## Context

During the domain migration sprint (August 20, 2025), we discovered that merged code changes (PRs #71, #72, #76) were not automatically applied to the running infrastructure. This gap between repository state and infrastructure state was blocking all further progress on the domain migration from `.local` to `spaceships.work`.

Additionally, during infrastructure assessment on August 22, we identified that Vault was running in development mode with no persistence, which was preventing production service deployments.

## Decision

We decided to:

1. **Immediately halt** attempts to deploy production services on development-mode infrastructure
2. **Prioritize** deploying Vault in production mode with persistent Raft storage
3. **Establish** a clear deployment pipeline: Code merge → Infrastructure application → Service deployment
4. **Document** explicit deployment procedures to prevent future gaps

## Consequences

### Positive

- Prevented data loss from deploying on non-persistent storage
- Established clear deployment procedures
- Identified critical infrastructure gaps early
- Created foundation for reliable production deployments

### Negative

- Delayed domain migration by 2-3 days
- Required unplanned work to deploy Vault properly
- Increased sprint complexity

### Risks

- Further delays if Vault deployment encounters issues
- Potential for similar gaps in other infrastructure components

## Alternatives Considered

### Alternative 1: Continue with Dev Mode Vault

- **Pros**: Simpler, faster initial deployment
- **Rejected**: No persistence, loses all secrets on restart, blocks production deployments

### Alternative 2: Deploy Services First, Fix Infrastructure Later

- **Pros**: Maintains original sprint timeline
- **Rejected**: Would result in data loss and require re-deployment

### Alternative 3: Use Infisical for All Secrets

- **Pros**: Already configured and working
- **Rejected**: Vault needed for dynamic database credentials and service integration

## Implementation

The decision was implemented through:

1. **ADR-2025-08-23**: Documented Vault production deployment with Raft storage
2. **Vault Deployment**: Successfully deployed 3-node Raft cluster (Phase 2 Complete)
3. **Process Updates**: Added explicit infrastructure application steps to deployment procedures
4. **Documentation**: Created deployment runbooks and verification checklists

## Lessons Learned

1. **Infrastructure State Verification**: Always verify actual infrastructure state before deploying services
2. **Deployment Pipeline**: Code changes require explicit infrastructure application
3. **Development vs Production**: Never deploy production services on development infrastructure
4. **Documentation**: Deployment procedures must be explicitly documented and followed

## References

- [ADR-2025-08-23: Vault Production Deployment](./ADR-2025-08-23-vault-production-deployment.md)
- [Vault Production Deployment Guide](../../implementation/vault/production-deployment.md)
- PR #71, #72, #76 (Domain migration code changes)
