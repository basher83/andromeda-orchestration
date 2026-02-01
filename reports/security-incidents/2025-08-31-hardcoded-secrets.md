# Security Finding Report: Hardcoded Secrets Assessment

**Date:** 2025-08-31  
**Severity:** MEDIUM (Internal Infrastructure)  
**Status:** IDENTIFIED - Action Plan in Progress

## Executive Summary

Security scans (Infisical and KICS) identified hardcoded secrets in the repository. Analysis shows these are primarily bootstrap/temporary passwords used during initial infrastructure setup before Vault was operational. The infrastructure is internal-only (not internet accessible), and secrets have since been rotated.

## Findings Analysis

### Context

- **Infrastructure Type**: Homelab (internal network only, no internet exposure)
- **Access Requirements**: Physical network access or VPN required
- **Secret Status**: Previously rotated, used for bootstrapping before Vault deployment

### Actual vs Perceived Risk

#### 1. Active Code Findings

**PostgreSQL Bootstrap File** (`nomad-jobs/platform-services/postgresql.nomad.hcl`)

- **Purpose**: Database initialization before Vault was operational
- **Current Status**: Needs update to use environment variables or Vault
- **Risk Level**: LOW (internal only, passwords rotated)
- **Action**: Update to use proper secret management

#### 2. Archived Files (.archive/ directories)

- **Purpose**: Historical test configurations
- **Risk Level**: MINIMAL (not in use, test values)
- **Action**: Consider cleanup (low priority)

#### 3. Documentation Examples

- **Finding**: Example curl commands with tokens in READMEs
- **Risk Level**: FALSE POSITIVE (documentation examples)
- **Action**: None required

#### 4. KICS HTTP Findings

- **Finding**: 44 instances of HTTP instead of HTTPS
- **Context**: Internal service communication (localhost:8500, etc.)
- **Risk Level**: LOW (standard for internal services)
- **Action**: Add TLS where feasible (future enhancement)

## Realistic Action Plan

### Priority 1: Update Active Configuration (This Week)

1. **Update PostgreSQL Nomad Job**
   - [ ] Modify `postgresql.nomad.hcl` to use environment variables
   - [ ] Configure Vault/Infisical integration when available
   - [ ] Test deployment with dynamic secrets

### Priority 2: Infrastructure Improvements (Next Sprint)

1. **Secret Management Migration**

   ```hcl
   # WRONG - What we have now
   env {
     POSTGRES_PASSWORD = "temporary-bootstrap-password"
   }
   
   # RIGHT - What we need (using environment variables for now)
   env {
     POSTGRES_PASSWORD = "${POSTGRES_PASSWORD}"
   }
   
   # FUTURE - When Vault is fully operational
   template {
     data = <<EOF
     {{ with secret "database/creds/postgresql" }}
     POSTGRES_PASSWORD="{{ .Data.password }}"
     {{ end }}
     EOF
     destination = "secrets/db.env"
     env = true
   }
   ```

### Priority 3: Long-term Improvements (Backlog)

1. **Archive Cleanup**
   - [ ] Review and remove unnecessary `.archive/` directories
   - [ ] Document any kept archives for historical reference

2. **TLS Implementation**
   - [ ] Add TLS to internal services where appropriate
   - [ ] Document TLS strategy for homelab environment

3. **Git History**
   - [ ] Consider cleanup if deploying to production
   - [ ] Current assessment: Not required for internal homelab

## Security Best Practices Going Forward

### Development Guidelines

- Use environment variables for secrets during development
- Implement proper secret management (Vault/Infisical) as infrastructure matures
- Run `mise run security:secrets` periodically to catch issues
- Document when bootstrap passwords are necessary

### Pre-commit Protection

- Infisical scanning configured in `.infisical-scan.toml`
- Consider adding pre-commit hooks for automated checking
- Regular security audits with both Infisical and KICS

## Risk Assessment

### Affected Systems

- **PostgreSQL**: Bootstrap configuration only
- **Internal Services**: Consul, Nomad, Netdata (localhost communication)
- **Access Required**: Physical network or VPN access

### Actual Impact

- **External Risk**: NONE (infrastructure not internet accessible)
- **Internal Risk**: LOW (secrets rotated, bootstrap values only)
- **Compliance**: N/A (homelab environment)

## Resolution Timeline

- **Week 1**: Update postgresql.nomad.hcl to use environment variables
- **Week 2-3**: Complete Vault integration for dynamic secrets
- **Month 2**: Implement TLS for internal services (enhancement)
- **As Needed**: Archive cleanup and documentation updates

## Key Takeaways

1. **Context Matters**: Homelab bootstrap passwords != production credentials
2. **Risk-Based Approach**: Focus on actual risks, not theoretical vulnerabilities
3. **Continuous Improvement**: Migrate to better patterns as infrastructure matures
4. **Security Tools**: Require human validation to separate real issues from false positives

---

**Status**: This is a tracked improvement opportunity, not a security breach. The findings help us mature our secret management practices as we transition from bootstrap configuration to production-ready infrastructure.
