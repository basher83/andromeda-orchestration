# Linting Integration Guide

## Overview

This guide integrates our linting standards with the specialized Claude agents and GitHub issues to provide a comprehensive approach to code quality management in the netbox-ansible project.

## Current State Analysis

### Tool Availability Status

Based on recent agent testing, we have identified critical gaps in our tooling:

| Tool | Status | Type | Installation Method | GitHub Issue |
|------|--------|------|-------------------|--------------|
| ruff | ✅ Installed | Python | `uv sync` | - |
| ansible-lint | ✅ Installed | Python | `uv sync` | - |
| yamllint | ✅ Installed | Python | `uv sync` | - |
| shellcheck | ✅ Installed | Native | System package | - |
| nomad | ❌ Missing | Native | Manual install | [#62](https://github.com/basher83/netbox-ansible/issues/62) |
| terraform | ❌ Missing | Native | Manual install | [#62](https://github.com/basher83/netbox-ansible/issues/62) |

### Violation Summary

Current ansible-lint violations: **391 issues** across the codebase

- Primary issue: Missing Fully Qualified Collection Names (FQCN)
- Tracked in: [Issue #63](https://github.com/basher83/netbox-ansible/issues/63)

## Agent Architecture

### Master Coordinator

- **Agent**: `lint-master`
- **Role**: Orchestrates specialized linters based on file types
- **Key Feature**: Understands tool invocation patterns (uv run vs direct)

### Specialized Agents

| Agent | File Types | Tools | Invocation Pattern |
|-------|------------|-------|-------------------|
| python-linter | `.py` | ruff, mypy | `uv run <tool>` |
| ansible-linter | `playbooks/*.yml`, `roles/**/*.yml` | ansible-lint | `uv run ansible-lint` |
| yaml-linter | `.yml`, `.yaml` | yamllint | `uv run yamllint` |
| shell-linter | `.sh`, `.bash` | shellcheck | `shellcheck` (direct) |
| hcl-linter | `.hcl`, `.tf`, `.nomad` | nomad fmt, terraform fmt | Direct execution |

## Implementation Roadmap

### Phase 1: Tool Installation (Issue #62)

**Status**: 🔴 Not Started
**Target**: Migrate to Mise for comprehensive tool management

1. **Install Mise**:

   ```bash
   curl https://mise.run | sh
   echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc
   ```

2. **Create .mise.toml**:

   ```toml
   [tools]
   python = "3.12"
   node = "20"
   terraform = "1.7.0"
   nomad = "1.7.3"
   shellcheck = "0.9.0"

   [env]
   VIRTUAL_ENV = ".venv"
   PATH_add = [".venv/bin"]
   ```

3. **Update development setup**:
   - Remove Taskfile.yml
   - Migrate tasks to Mise
   - Update documentation

### Phase 2: FQCN Migration (Issue #63)

**Status**: 🔴 Not Started
**Target**: Fix 391 ansible-lint violations

#### Automated Fix Script

```bash
#!/bin/bash
# fix-fqcn.sh - Automatically fix FQCN violations

echo "=== Starting FQCN Migration ==="

# Step 1: Backup current state
git stash push -m "Pre-FQCN migration backup"

# Step 2: Run ansible-lint with auto-fix
echo "Running ansible-lint auto-fix..."
uv run ansible-lint --write

# Step 3: Check remaining issues
echo "Checking remaining violations..."
uv run ansible-lint --profile=moderate | tee fqcn-report.txt

# Step 4: Summary
echo "=== Migration Summary ==="
echo "Auto-fixed violations: $(grep -c "Fixed" fqcn-report.txt)"
echo "Remaining violations: $(uv run ansible-lint --count)"
```

#### Manual Fix Patterns

Common FQCN replacements:

```yaml
# Before
- name: Install package
  apt:
    name: nginx

# After
- name: Install package
  ansible.builtin.apt:
    name: nginx
```

### Phase 3: Progressive Linting (Issue #64)

**Status**: 🔴 Not Started
**Target**: Implement staged quality improvements

#### Profile Progression Strategy

1. **Week 1-2**: Basic Profile

   ```yaml
   # .ansible-lint
   profile: basic
   ```

   - Fix syntax errors
   - Basic formatting

2. **Week 3-4**: Moderate Profile

   ```yaml
   profile: moderate
   ```

   - FQCN compliance
   - Task naming

3. **Week 5-6**: Safety Profile

   ```yaml
   profile: safety
   ```

   - Security checks
   - Deterministic behavior

4. **Week 7-8**: Production Profile

   ```yaml
   profile: production
   ```

   - Full compliance
   - Platform compatibility

### Phase 4: Pre-commit Enhancement (Issue #65)

**Status**: 🔴 Not Started
**Target**: Comprehensive pre-commit hooks

#### Enhanced Configuration

```yaml
# .pre-commit-config.yaml
repos:
  # Python/Ansible tools (require uv)
  - repo: local
    hooks:
      - id: ansible-lint
        name: Ansible Lint
        entry: uv run ansible-lint
        language: system
        files: \.(yml|yaml)$
        exclude: ^archive/

      - id: yamllint
        name: YAML Lint
        entry: uv run yamllint
        language: system
        files: \.(yml|yaml)$

      - id: ruff
        name: Ruff Check
        entry: uv run ruff check --fix
        language: system
        files: \.py$

  # Native tools (direct execution)
  - repo: local
    hooks:
      - id: shellcheck
        name: Shell Check
        entry: shellcheck
        language: system
        files: \.(sh|bash)$

      - id: nomad-fmt
        name: Nomad Format
        entry: nomad fmt
        language: system
        files: \.nomad\.hcl$

      - id: terraform-fmt
        name: Terraform Format
        entry: terraform fmt
        language: system
        files: \.tf$
```

## Integration Workflows

### Daily Development Workflow

1. **Before starting work**:

   ```bash
   # Ensure tools are available
   mise install

   # Update pre-commit hooks
   pre-commit install
   pre-commit autoupdate
   ```

2. **During development**:

   ```bash
   # Run quick lint check
   uv run ansible-lint playbooks/my-playbook.yml

   # Use lint-master agent for comprehensive check
   # This coordinates all specialized agents
   ```

3. **Before committing**:

   ```bash
   # Pre-commit will run automatically
   git commit -m "feat: add new playbook"

   # If issues found, fix and re-commit
   uv run ansible-lint --write
   git add -u
   git commit -m "feat: add new playbook"
   ```

### CI/CD Pipeline Integration

```yaml
# .github/workflows/lint.yml
name: 🔍 Comprehensive Linting

on:
  pull_request:
  push:
    branches: [main]

jobs:
  lint-python-tools:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v2

      - name: Install dependencies
        run: uv sync

      - name: Run Python-based linters
        run: |
          uv run ansible-lint
          uv run yamllint .
          uv run ruff check .

  lint-native-tools:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - uses: hashicorp/setup-nomad@v1

      - name: Install shellcheck
        run: |
          sudo apt-get update
          sudo apt-get install -y shellcheck

      - name: Run native linters
        run: |
          shellcheck scripts/*.sh
          find nomad-jobs -name "*.hcl" -exec nomad fmt -check {} \;
          terraform fmt -check -recursive terraform/
```

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue: "uv: command not found"

**Solution**: Install uv and ensure Python environment is activated

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.cargo/env
```

#### Issue: "ansible-lint: command not found" (when using uv run)

**Solution**: Sync Python dependencies

```bash
uv sync
uv run ansible-lint --version
```

#### Issue: Missing HashiCorp tools

**Solution**: Use Mise for tool management (see Phase 1)

```bash
mise install
mise doctor
```

#### Issue: Pre-commit hooks failing

**Solution**: Update hooks and fix issues

```bash
pre-commit clean
pre-commit install --install-hooks
pre-commit run --all-files
```

## Metrics and Monitoring

### Key Performance Indicators

| Metric | Current | Target | Timeline |
|--------|---------|--------|----------|
| Ansible-lint violations | 391 | 0 | 4 weeks |
| Linting profile | None | Production | 8 weeks |
| Pre-commit adoption | Partial | 100% | 2 weeks |
| CI/CD lint pass rate | ~60% | 100% | 6 weeks |

### Progress Tracking

Weekly reviews should assess:

1. Reduction in linting violations
2. Profile progression status
3. Tool availability across environments
4. Developer feedback on workflow

## Best Practices

### For Developers

1. **Always use uv run for Python tools**:

   ```bash
   uv run ansible-lint  # ✅ Correct
   ansible-lint         # ❌ May use wrong version
   ```

2. **Run lint-master agent for comprehensive checks**:
   - Before creating PRs
   - After major refactoring
   - When adding new file types

3. **Fix issues incrementally**:
   - Start with errors, then warnings
   - Use auto-fix where available
   - Document legitimate exceptions

### For CI/CD

1. **Fail fast on critical issues**:
   - Syntax errors
   - Security violations
   - Missing FQCN (after migration)

2. **Warn on style issues**:
   - Allow PR merge with warnings
   - Track improvement over time

3. **Cache dependencies**:
   - Python packages
   - Pre-commit environments
   - Tool binaries

## References

- [Linting Standards](./linting-standards.md)
- [GitHub Issue #62](https://github.com/basher83/netbox-ansible/issues/62) - Tool Installation
- [GitHub Issue #63](https://github.com/basher83/netbox-ansible/issues/63) - FQCN Migration
- [GitHub Issue #64](https://github.com/basher83/netbox-ansible/issues/64) - Progressive Linting
- [GitHub Issue #65](https://github.com/basher83/netbox-ansible/issues/65) - Pre-commit Enhancement
- [Mise Documentation](https://mise.jdx.dev/)
- [Ansible-lint Documentation](https://ansible-lint.readthedocs.io/)
