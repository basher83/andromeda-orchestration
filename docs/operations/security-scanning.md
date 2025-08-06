# Security Scanning Operations

This document covers the security scanning tools and procedures used in the andromeda-orchestration project.

## Overview

The project uses multiple security scanning tools to detect and prevent security issues:

1. **Infisical CLI** - Secret detection in code and commits
2. **KICS** - Infrastructure as Code security scanning
3. **Pre-commit hooks** - Automated checks before commits

## Infisical Secret Scanning

### Configuration

Infisical CLI secret scanning is configured to detect exposed secrets in the codebase.

**Installation**:
```bash
# Install via Homebrew (macOS/Linux)
brew install infisical/get-cli/infisical

# Or download from releases
# https://github.com/Infisical/infisical/releases
```

**Configuration File**: `.infisical-scan.toml`

### Usage

```bash
# Run secret scan
task security:secrets

# Manual scan
infisical scan

# Deep scan (more thorough)
infisical scan --deep

# Scan with custom config
infisical scan --config .infisical-scan.yml
```

### Pre-commit Integration

The Infisical scanner can be integrated with pre-commit hooks:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: infisical-scan
        name: Infisical Secret Scan
        entry: infisical scan
        language: system
        pass_filenames: false
        always_run: true
```

**Note**: Currently run via `task security:secrets` due to integration complexity.

## KICS Infrastructure Security

KICS (Keeping Infrastructure as Code Secure) scans for security issues in infrastructure code.

### Configuration

**Configuration File**: `kics.config` (YAML format)

Key settings:
- Exclusions for test containers and documentation
- Output formats: JSON and SARIF
- Results directory: `kics-results/`

### Usage

```bash
# Run KICS scan
task security:kics

# Manual Docker command
docker run -t -v "$(pwd)":/path checkmarx/kics scan \
  -p /path \
  --output-path /path/kics-results \
  --output-name results \
  --report-formats json,sarif
```

### Results

Scan results are saved to:
- `kics-results/results.json` - JSON format for analysis
- `kics-results/results.sarif` - SARIF format for IDE integration

## Combined Security Scanning

Run all security scans with a single command:

```bash
# Run all security scans
task security
```

This executes:
1. Infisical secret detection
2. KICS infrastructure scanning

## False Positive Management

### Infisical Scan Ignore

Create `.infisical-scan-ignore` file:

```yaml
# Ignore specific files
docs/examples/sample-config.yml

# Ignore specific patterns
pattern:EXAMPLE_.*_TOKEN

# Ignore specific findings by ID
finding:abc123def456
```

### KICS Exclusions

Configure in `kics.config`:

```yaml
exclude-paths:
  - test/
  - docs/examples/
  - "*.test.yml"
```

## Best Practices

1. **Regular Scanning**
   - Run `task security` before commits
   - Include in CI/CD pipeline
   - Schedule weekly deep scans

2. **Handle Findings Promptly**
   - Rotate any exposed secrets immediately
   - Fix high/critical infrastructure issues
   - Document false positives

3. **Maintain Exclusions**
   - Keep ignore lists minimal
   - Document why items are excluded
   - Review exclusions quarterly

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Security Scanning
on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Infisical Scan
        uses: Infisical/infisical-scan-action@v1
        with:
          fail-on-finding: true
      
      - name: Run KICS Scan
        uses: checkmarx/kics-github-action@v1
        with:
          path: .
          fail_on: high,critical
```

## Troubleshooting

### Common Issues

1. **Docker not available for KICS**
   - Ensure Docker is running
   - Check Docker permissions

2. **Infisical CLI not found**
   - Install via package manager
   - Add to PATH

3. **Too many false positives**
   - Review and update ignore patterns
   - Consider adjusting sensitivity

### Getting Help

- Infisical Docs: https://infisical.com/docs
- KICS Docs: https://docs.kics.io
- Project Issues: Report in repository

## Related Documentation

- [Security Standards](../standards/security-standards.md)
- [Pre-commit Setup](../getting-started/pre-commit-setup.md)
- [Development Workflow](../standards/development-workflow.md)