# Reports Directory Security Procedures

## Purpose
This directory contains system-generated reports with sensitive infrastructure data that must be handled according to our security standards.

## Security Classification
**SENSITIVE - DO NOT COMMIT RAW REPORTS TO GIT**

📚 **See [Security Standards](../docs/standards/security-standards.md) for comprehensive security practices.**

## Directory Structure

```
reports/
├── SECURITY.md           # This file - security procedures
├── README.md             # Directory overview
├── .gitignore           # Local gitignore for extra protection
├── assessment/          # Infrastructure assessment reports
├── connectivity/        # Network connectivity tests
├── consul/             # Consul cluster reports
├── dns-ipam/           # DNS and IPAM audit results
├── infrastructure/     # General infrastructure reports
├── netdata/            # Netdata configurations (IGNORED)
└── nomad/              # Nomad cluster reports
```

## Security Procedures

### 1. Pre-Commit Checks
Before ANY commit in this repository:
```bash
# Check for potential secrets
rg -i "(password|token|secret|key|api_key|private|credential)" reports/

# Check what files would be committed
git status reports/

# Verify .gitignore is working
git check-ignore reports/**/*.yml reports/**/*.json reports/**/*.txt
```

### 2. What Should Be Committed

✅ **SAFE to commit:**
- Documentation files (*.md)
- Sanitized summaries that have been reviewed

❌ **NEVER commit:**
- Raw reports (*.yml, *.yaml, *.json, *.txt)
- Any file containing infrastructure details or credentials

### 3. Report Sanitization Process

If you need to share report data:

1. **Create a sanitized copy:**
```bash
# Example: Sanitize a consul report
cp reports/consul/consul_assessment.yml reports/consul/consul_assessment_sanitized.md

# Edit the file and:
# - Remove all tokens/secrets
# - Replace IPs with placeholders (e.g., 192.168.x.x -> REDACTED_IP)
# - Replace hostnames with generic names
# - Convert to Markdown for better readability
```

2. **Review before committing:**
```bash
# Double-check for sensitive data
rg -i "(192\.168|10\.|token|secret)" reports/consul/consul_assessment_sanitized.md
```

3. **Commit only sanitized version:**
```bash
git add reports/consul/consul_assessment_sanitized.md
git commit -m "docs: add sanitized consul assessment summary"
```

### 4. GitIgnore Configuration

Report exclusions are configured in:
- `.gitignore` - Repository-wide patterns
- `reports/.gitignore` - Local protection layer

See [Security Standards](../docs/standards/security-standards.md#gitignore-patterns) for details.

### 5. Emergency Response

If sensitive data is accidentally committed, follow the [Incident Response procedures](../docs/standards/security-standards.md#incident-response).

### 6. Automated Scanning

Security scanning tools are configured to exclude the reports directory:
- **Infisical**: Excludes `reports/**` in `.infisical-scan.toml`
- **KICS**: Excludes `reports/` in `kics.config`

See [Security Scanning](../docs/standards/security-standards.md#security-scanning) for tool details.

### 7. Report Retention Policy

- **Raw reports**: Delete after 30 days
- **Sanitized summaries**: Keep indefinitely in git
- **Configs**: Never commit, regenerate as needed

## Quick Reference

```bash
# Check what would be committed
git status reports/

# Verify gitignore
git check-ignore reports/**/*.yml

# Clean old reports (30+ days)
find reports -name "*.yml" -mtime +30 -delete

# Run security scan
task security:secrets
```

## Remember

⚠️ **When in doubt, don't commit it!**

It's easier to add something to git later than to remove sensitive data from git history.

---

📚 Full security practices: [Security Standards](../docs/standards/security-standards.md)
