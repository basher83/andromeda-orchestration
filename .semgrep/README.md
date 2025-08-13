# Semgrep Configuration for Infrastructure Automation

This directory contains curated Semgrep rules specifically designed for infrastructure automation projects using Ansible, Terraform, Nomad, and related tools.

## Files

- `infrastructure-rules.yml` - Curated ruleset focused on infrastructure security and best practices

## Rules Overview

### Ansible Security

- **ansible-no-log-sensitive-tasks** - Ensures sensitive tasks use `no_log: true`
- **yaml-avoid-latest-tag** - Warns against using `:latest` tags in production

### Secret Management

- **hardcoded-secrets** - Detects hardcoded passwords, API keys, and tokens
- **python-unsafe-yaml-load** - Prevents unsafe YAML loading vulnerabilities

### Infrastructure Configuration

- **terraform-hardcoded-ips** - Warns against overly permissive CIDR blocks (0.0.0.0/0)
- **nomad-missing-health-check** - Ensures Nomad services include health checks
- **avoid-debug-true** - Prevents debug mode in production configurations

### Security Vulnerabilities

- **shell-command-injection** - Detects potential command injection in Python scripts
- **dockerfile-root-user** - Warns against running containers as root

## Configuration

The ruleset is configured in `.coderabbit.yaml` to:

- Only scan for ERROR and WARNING severity issues
- Exclude irrelevant directories (docs/archive, logs, temp files, virtual environments)
- Focus on infrastructure-relevant file types

## Severity Levels

- **ERROR**: Critical security issues that should be fixed immediately
- **WARNING**: Best practice violations that should be addressed
- **INFO**: Suggestions for improvement (optional fixes)

## Path Targeting

Rules are configured to run only on relevant paths:

- Ansible: `playbooks/**/*.yml`, `roles/**/*.yml`
- Terraform: `**/*.tf`, `**/*.hcl`
- Nomad: `nomad-jobs/**/*.hcl`, `nomad-jobs/**/*.nomad`
- Docker: `**/Dockerfile*`
- Python: `**/*.py`

## Customization

To modify the rules:

1. Edit `infrastructure-rules.yml` to add/remove/modify rules
2. Test changes locally with: `semgrep --config=.semgrep/infrastructure-rules.yml .`
3. Update `.coderabbit.yaml` if needed to adjust severity thresholds or exclusions

## Integration

This configuration integrates with:

- CodeRabbit for automated PR reviews
- CI/CD pipelines (can be run with `semgrep --config=.semgrep/infrastructure-rules.yml`)
- Local development (IDE plugins, pre-commit hooks)
