# MegaLinter Standards for IaC Repository

This document provides comprehensive linting standards for an Infrastructure as Code (IaC) repository using **MegaLinter** with strong coverage for **Ansible** and **Nomad** workflows.

## Goals and Scope

- Enforce consistent YAML and HCL syntax and formatting
- Surface Ansible best practices and validate Nomad jobs pre-merge
- Integrate automated checks into CI with optional autofix
- Provide granular failure control for gradual adoption in existing codebases

## Coverage and Tools

MegaLinter provides first-class support for ansible-lint and YAML linters (yamllint, Prettier, v8r). This standard augments Nomad with CLI validation and HCL formatting checks.

Recommended coverage includes:

- Repository hygiene and secrets scanning
- EditorConfig compliance
- GitHub Actions workflow linting

### Linter Map

| Area                 | Tool                    | Purpose                                                      | Integration                                     |
| -------------------- | ----------------------- | ------------------------------------------------------------ | ----------------------------------------------- |
| Ansible content      | ansible-lint            | Detects common errors and enforces playbook/role conventions | MegaLinter ANSIBLE descriptor                   |
| YAML files           | yamllint, Prettier, v8r | Style/rule checks, formatting, and schema validation         | MegaLinter YAML descriptor                      |
| HCL (Nomad jobs)     | terragrunt hclfmt       | Canonical HCL formatting with check mode for CI              | CLI step (hclfmt --check)                       |
| Nomad jobs           | nomad job validate      | Syntax/structural validation of job specs in CI              | CLI step pre-merge                              |
| EditorConfig         | editorconfig-checker    | Enforce .editorconfig coding style across files              | MegaLinter integration                          |
| Repo workflows       | actionlint              | Validate GitHub Actions YAML workflows                       | MegaLinter ACTION linters                       |
| Secrets and security | secretlint, trivy       | Detect hard-coded secrets and common vulnerabilities         | MegaLinter supports repo-level security linters |

## Repository Conventions

### Directory Structure

- Place Ansible content under standard `roles/` and `playbooks/` (or `collections/`) directories
- Use YAML files with `.yml` or `.yaml` extensions to align with ansible-lint and yamllint discovery patterns

### Nomad Job Specifications

- Store Nomad job specs as HCL files (`.nomad` or `.hcl` extensions)
- Format with `hclfmt` in check mode for CI validation
- Validate with `nomad job validate` pre-merge

### Configuration Files

- Include a top-level `.editorconfig` file
- Include `.yamllint` configuration to standardize whitespace, line length, and indentation
- Apply standards across YAML and HCL templates

## MegaLinter Configuration

Activate only the linters needed for this repository, enable optional autofix, and scope files using include/exclude filters for speed. Define which linters are blocking versus advisory to stage enforcement in large, pre-existing codebases.

### Example `.mega-linter.yml`

```yaml
# Only enable linters relevant to Ansible + YAML + repo hygiene
ENABLE_LINTERS:
  - ANSIBLE_ANSIBLE_LINT
  - YAML_YAMLLINT
  - YAML_PRETTIER
  - YAML_V8R
  - REPOSITORY_SECRETLINT
  - REPOSITORY_TRIVY
  - ACTION_ACTIONLINT

# Apply autofixes where safe (formatters), others report only
APPLY_FIXES: "MARKDOWN_MARKDOWNLINT,YAML_PRETTIER"
DISABLE_ERRORS_LINTERS:
  - YAML_YAMLLINT

# Speed: only lint tracked sources, ignore generated/vendored paths
FILTER_REGEX_EXCLUDE: "(^|/)(.git/|.tox/|.venv/|dist/|build/|node_modules/|vendor/|megalinter-reports/)"
# Optional: include only IaC-relevant areas
# FILTER_REGEX_INCLUDE: "(^|/)(ansible/|roles/|playbooks/|jobs/|nomad/|environments/|pipelines/)"
```

## GitHub Actions Workflow

Running MegaLinter as a GitHub Action is a single-file addition. By default it fails the build on findings, which can be tuned via environment variables. Configure apply-fix behavior (commit or PR) and failure strategy using documented environment variables.

### Example `.github/workflows/mega-linter.yml`

```yaml
name: MegaLinter
on:
  pull_request:
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: MegaLinter
        uses: oxsecurity/megalinter@v8
        env:
          ENABLE_LINTERS: ANSIBLE_ANSIBLE_LINT,YAML_YAMLLINT,YAML_PRETTIER,YAML_V8R,REPOSITORY_SECRETLINT,REPOSITORY_TRIVY,ACTION_ACTIONLINT
          APPLY_FIXES: MARKDOWN_MARKDOWNLINT,YAML_PRETTIER
          DISABLE_ERRORS_LINTERS: YAML_YAMLLINT
          FILTER_REGEX_EXCLUDE: "(^|/)(.git/|.tox/|.venv/|dist/|build/|node_modules/|vendor/|megalinter-reports/)"
```

## Nomad and HCL Standards

### HCL Formatting

- Require `hclfmt` in check mode in CI to enforce canonical formatting across all HCL
- Fail the job if files need reformatting

### Nomad Job Validation

- Require `nomad job validate` as a separate CI step
- Catch parser and structure errors early in the pipeline

### Example CI Steps

```yaml
- name: HCL format check
  run: terragrunt hclfmt --check

- name: Validate Nomad jobs
  run: |
    find . -name "*.nomad" -o -name "*.hcl" | xargs -n1 -I{} nomad job validate {}
```

## Ansible Lint Standards

### Configuration

- Enforce ansible-lint on all `.yml`/`.yaml` files under `playbooks/`, `roles/`, and `collections/`
- Use a project-level `.ansible-lint` file for `skip_list`, `warn_list`, and `exclude_paths`

### Rule Management

- Use `warn_list` for rules to monitor without blocking
- Use `skip_list` or `exclude_paths` sparingly for legacy code
- Enable incremental cleanup of technical debt

### Example `.ansible-lint`

```yaml
skip_list:
  - name[missing]
  - yaml[truthy]

warn_list:
  - fqcn[action-core]

exclude_paths:
  - legacy_playbooks/
  - roles/experimental/
```

## YAML Style and Validation

### Configuration Approach

- Base rules on yamllint defaults and relax selectively (e.g., adjust line-length and truthy)
- Minimize noise while keeping quality signals
- Keep Prettier enabled for YAML auto-formatting
- Use v8r when schema-based validation is required

### Example `.yamllint`

```yaml
extends: default

rules:
  line-length:
    max: 120
    level: warning

  truthy: disable

  comments:
    level: warning
```

## Local Development Workflow

### Local Testing

- Provide a fast local path via `mega-linter-runner` to replicate CI checks
- Apply safe fixes before opening a PR

### Project Integration

- Add a project badge to the README to surface lint status
- Encourage consistent adherence across the team

## Performance and Tuning

### Optimization Strategies

- Prefer `list_of_files` or `project` lint modes where supported
- Scope with `FILTER_REGEX_INCLUDE`/`EXCLUDE` to reduce run times
- Use `APPLY_FIXES` only for deterministic formatters
- Gate security linters as blocking to protect critical quality

## Maintenance and Currency

### Version Management

- MegaLinter ships frequent updates and linter integrations
- Pin versions as needed and review changelogs during upgrades

### Project Health

- The project is actively maintained with ongoing issues and enhancements
- Supports long-term viability for CI linting in IaC environments

## Adoption Plan

### Phase 1: Basic Setup

- Enable YAML formatting (Prettier)
- Enable non-blocking yamllint
- Enable blocking ansible-lint and actionlint

### Phase 2: Advanced Validation

- Add HCL format checks as blocking gates
- Add `nomad job validate` as blocking gates
- Enable secrets scanning

## Appendix: Badges and Autofix

### Status Badges

To display lint status, use the documented badge pattern that references the MegaLinter workflow name and branch.

### Autofix Configuration

For autofix commits or PRs, set `APPLY_FIXES_EVENT` and `APPLY_FIXES_MODE` in workflow environment. Consider PAT-based approaches when permission errors arise.

---

_Last Updated: 2025-01-09_
