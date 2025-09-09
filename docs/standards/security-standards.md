# Security Standards

## Purpose

Define security practices that protect sensitive infrastructure data, prevent credential exposure, and maintain compliance.

## Background

Infrastructure automation inherently deals with sensitive data: credentials, network topology, service configurations. These standards ensure we protect this data while maintaining operational efficiency.

## Standard

### Data Classification

#### Sensitive Data Types

- **Credentials**: Passwords, tokens, API keys, certificates
- **Infrastructure Details**: IP addresses, hostnames, network topology
- **Configuration**: Service configs, firewall rules, ACLs
- **Reports**: Assessment outputs, scan results, metrics

#### Handling Requirements

```text
PUBLIC:       Can be committed to git
INTERNAL:     Sanitize before committing
SENSITIVE:    Never commit, use secret management
CRITICAL:     Never store, rotate immediately if exposed
```

### Secret Management

#### Infisical Integration

```yaml
# Primary secret store
Environment Variables: INFISICAL_CLIENT_ID
  INFISICAL_CLIENT_SECRET
  INFISICAL_PROJECT_ID

# Usage in playbooks
password: "{{ lookup('env', 'SERVICE_PASSWORD') }}"
```

#### Never Commit

- Hardcoded passwords
- API tokens
- Private keys
- Consul/Nomad tokens
- SSH keys

### Security Scanning

#### Automated Tools

##### Infisical Secret Detection

- **Config**: `.infisical-scan.toml`
- **Git Hook**: Runs automatically on commit
- **Manual**: `mise run security:secrets`
- **Excludes**: Binary files, reports/, build artifacts

##### KICS Infrastructure Security

- **Config**: `kics.config`
- **Manual**: `mise run security:kics`
- **Focus**: Ansible, Docker, Terraform security
- **Fail On**: HIGH, CRITICAL findings

##### Python Security Scanning

- **Bandit** (Static Analysis):
  - **Config**: `.bandit`
  - **Focus**: Security vulnerabilities in Python code
  - **Run**: `bandit -r . -ll` (medium/high severity)
- **Safety** (Dependency Scanning):
  - **Config**: `.safety-policy.json`
  - **Focus**: Known CVEs in dependencies
  - **Run**: `safety check --json`

##### Pre-commit Hooks

- **Config**: `.pre-commit-config.yaml`
- **Features**:
  - `detect-private-key`: Block private keys
  - `check-added-large-files`: Prevent large commits
  - `trailing-whitespace`: Clean code
  - `yamllint`: YAML validation
  - `bandit`: Python security checks
- **Run**: `uv run pre-commit run --all-files`

#### Scanning Commands

```bash
# Run all security scans
mise run security

# Individual scans
mise run security:secrets  # Secret detection
mise run security:kics     # Infrastructure security

# Pre-commit checks
uv run pre-commit run --all-files
```

### GitIgnore Patterns

#### Repository-wide Exclusions

```gitignore
# Secrets - NEVER commit
**/secrets/
**/credentials/
*.pem
*.key
*.crt
*.token

# Reports with sensitive data
reports/**/*.yml
reports/**/*.json
reports/**/*.txt
reports/**/*.log

# Environment files
.env
.mise.local.toml
*-env.sh
```

### Report Security

#### Raw Reports

- **Storage**: Local only, never git
- **Formats**: .yml, .json, .txt, .log
- **Retention**: 30 days maximum
- **Location**: reports/ directory

#### Sanitized Reports

- **Format**: Markdown only
- **Process**: Remove IPs, hostnames, tokens
- **Naming**: _\_sanitized.md or_\_summary.md
- **Storage**: Can be committed to git

### Incident Response

#### If Secrets Are Committed

1. **Immediate Actions**:

```bash
# Remove from history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/secret" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (coordinate with team)
git push --force --all
```

1. **Rotate Credentials**: Change ALL exposed secrets immediately
1. **Document**: Create incident report
1. **Review**: Audit how it happened, improve process

### Network Security

#### Service Identity

```hcl
# Every service gets identity
service {
  identity {
    aud = ["consul.io"]
    ttl = "1h"
  }
}
```

#### Access Control

- Consul ACLs enabled
- Nomad ACLs enabled
- mTLS for service communication (future)
- Zero trust architecture

### Compliance Checklist

Daily:

- [ ] No hardcoded secrets in code
- [ ] Environment variables for credentials
- [ ] Proper .gitignore patterns

Weekly:

- [ ] Run `mise run security`
- [ ] Review uncommitted files
- [ ] Clean old reports: `find reports -mtime +30 -delete`

Monthly:

- [ ] Rotate service tokens
- [ ] Audit git history for secrets
- [ ] Update security tools

## Rationale

### Why Multiple Scanning Layers?

- **Defense in Depth**: Catch secrets at multiple points
- **Different Focus**: Each tool specializes
- **Redundancy**: If one misses, another catches

### Why Strict Report Handling?

- **Data Sensitivity**: Reports contain full infrastructure details
- **Audit Trail**: Git history is permanent
- **Compliance**: Many regulations prohibit credential storage

### Why Automated Scanning?

- **Human Error**: Manual reviews miss things
- **Consistency**: Same checks every time
- **Speed**: Instant feedback on commits

## Examples

### Good: Using Environment Variables

```yaml
- name: Connect to service
  uri:
    url: "{{ service_url }}"
    headers:
      Authorization: "Bearer {{ lookup('env', 'API_TOKEN') }}"
```

### Bad: Hardcoded Credentials

```yaml
# ❌ NEVER DO THIS
- name: Connect to service
  uri:
    url: https://api.example.com
    headers:
      Authorization: "Bearer sk_live_abc123xyz" # ❌
```

### Good: Sanitized Report

```markdown
# Infrastructure Assessment Summary

## Findings

- Cluster has 3 servers in HA configuration
- All health checks passing
- Resource utilization: ~60% CPU, ~40% Memory

## Recommendations

- Consider adding 4th node for capacity
```

### Bad: Raw Report with Details

```yaml
# ❌ Never commit raw reports
nodes:
  - hostname: nomad-server-1.internal
    ip: 192.168.11.20
    consul_token: "abc-123-def-456" # ❌
```

## Exceptions

- **Development**: May use example credentials (clearly marked)
- **Documentation**: Generic examples without real data
- **Public IPs**: May be committed if truly public services

## Migration

### To Secure Practices

1. **Audit existing code**: `mise run security:secrets`
1. **Move secrets to Infisical**: Never store in code
1. **Update .gitignore**: Block sensitive patterns
1. **Enable pre-commit**: `uv run pre-commit install`
1. **Train team**: Share these standards

### Finding Issues

```bash
# Find potential secrets
rg -i "(password|token|secret|key).*=" --type-not md

# Find IPs
rg "(\d{1,3}\.){3}\d{1,3}" --type yaml

# Check git history
git log -p -S "password" --all
```

## Tools

### Find TODOs

```bash
# Find documentation TODOs
./scripts/find-todos.sh

# Manual search
rg "\[TODO\]:" docs/ --type md
```

### Security Scanning

```bash
# Full security check
mise run security

# Quick secret scan
./scripts/scan-secrets.sh quick

# Check before commit
uv run pre-commit run --all-files
```

## References

- [Report Security Procedures](../../reports/SECURITY.md)
- [Infrastructure Standards](./infrastructure-standards.md)
- [Infisical Documentation](https://infisical.com/docs)
- [KICS Documentation](https://docs.kics.io)
