# Linting Standards

## Purpose

Define automated code quality checks and formatting standards that ensure consistent, reliable, and secure Infrastructure as Code and documentation across all Ansible projects.

## Background

Linting is our first line of defense against common errors, security vulnerabilities, and inconsistent code patterns. These standards were developed to catch issues early in development, enforce best practices, and maintain code readability across teams. By automating these checks, we reduce cognitive load during code reviews and ensure baseline quality standards are met before human review begins.

## Standard

### Ansible Linting

#### ansible-lint Configuration

All Ansible projects must use ansible-lint with a `.ansible-lint` configuration file at the repository root.

**Profile Selection:**

```yaml
# Use profile based on project maturity
profile: production # For production-ready code
# profile: shared    # For code intended for Galaxy/Automation Hub
# profile: safety    # For security-focused environments
# profile: moderate  # For active development
# profile: basic     # For initial development
# profile: min       # For emergency fixes only
```

**Profile Descriptions:**

- **min**: Prevents Ansible execution errors (syntax, parser errors)
- **basic**: Enforces standard styles and formatting
- **moderate**: Improves readability and maintainability
- **safety**: Avoids non-deterministic outcomes and security issues
- **shared**: Prepares content for public distribution
- **production**: Ensures Ansible Automation Platform compatibility

**Standard Configuration Template:**

```yaml
# .ansible-lint
kinds:
  - yaml: "**/inventory/*.yml"
  - yaml: "**/inventory/*.yaml"
  - playbook: "**/playbooks/*.yml"
  - tasks: "**/tasks/*.yml"
  - vars: "**/vars/*.yml"
  - meta: "**/meta/main.yml"

exclude_paths:
  - .cache/
  - .venv/
  - venv/
  - tests/molecule/
  - archive/
  - .serena/

profile: production

task_name_prefix: "{stem} | "

var_naming_pattern: "^[a-z_][a-z0-9_]*$"

warn_list:
  - experimental
  - fqcn[action-core] # Allow short names for ansible.builtin

enable_list:
  - args
  - empty-string-compare
  - no-log-password
  - no-same-owner
  - name[prefix]
  - yaml[empty-values]

skip_list:
  - galaxy[no-changelog] # Only if not publishing to Galaxy

use_default_rules: true
offline: false
max_block_depth: 20
```

#### Rule Categories and Priority

**Critical Rules (Never Skip):**

- `syntax-check`: YAML syntax validation
- `parser-error`: Ansible parsing errors
- `schema[meta]`, `schema[tasks]`: Schema validation
- `no-log-password`: Security - prevent password logging
- `risky-shell-pipe`: Security - unsafe shell usage

**Recommended Rules (Warn Only During Development):**

- `name[template]`: Task naming consistency
- `name[casing]`: Naming convention enforcement
- `fqcn`: Fully qualified collection names
- `latest`: Package version pinning
- `no-changed-when`: Explicit change conditions

**Project-Specific Rules:**

- `galaxy`: Required for public collections
- `meta-no-tags`: Required for Galaxy publishing
- `sanity[cannot-ignore]`: Platform certification

### YAML Linting

All YAML files must pass yamllint validation using a `.yamllint` configuration.

**Standard Configuration:**

```yaml
# .yamllint
extends: default

rules:
  line-length:
    max: 120
    level: warning
    allow-non-breakable-inline-mappings: true

  indentation:
    spaces: 2
    indent-sequences: true
    check-multi-line-strings: false

  braces:
    min-spaces-inside: 0
    max-spaces-inside: 1

  brackets:
    min-spaces-inside: 0
    max-spaces-inside: 1

  comments:
    require-starting-space: true
    min-spaces-from-content: 1

  empty-lines:
    max: 2
    max-start: 0
    max-end: 1

  truthy:
    allowed-values: ["true", "false", "yes", "no"]

  # Ansible-specific settings
  document-start: disable
  comments-indentation: disable

  octal-values:
    forbid-implicit-octal: true
    forbid-explicit-octal: true

ignore: |
  .venv/
  .cache/
  archive/
```

### Markdown Linting

All markdown documentation must pass markdownlint validation to ensure consistency and readability.

**Markdownlint Configuration (.markdownlint.json):**

```json
{
  "default": true,
  "MD003": { "style": "atx" },
  "MD004": { "style": "dash" },
  "MD007": { "indent": 2 },
  "MD013": false,
  "MD024": { "siblings_only": true },
  "MD025": { "front_matter_title": "" },
  "MD033": false,
  "MD040": true,
  "MD041": false,
  "MD046": { "style": "fenced" },
  "MD048": { "style": "backtick" },
  "MD049": { "style": "underscore" },
  "MD050": { "style": "asterisk" },
  "line-length": false
}
```

**Key Rules Explained:**

- **MD040**: Language specification required for all fenced code blocks
- **MD031/MD032**: Blank lines required around lists and code blocks
- **MD003**: Use ATX-style headers (# Header)
- **MD004**: Use dashes for unordered lists
- **MD007**: 2-space indentation for lists
- **MD046**: Use fenced code blocks (not indented)

**VS Code Integration:**

```json
// .vscode/settings.json
{
  "markdownlint.config": {
    "extends": ".markdownlint.json"
  }
}
```

**Pre-commit Hook Addition:**

```yaml
# Add to .pre-commit-config.yaml
- repo: https://github.com/igorshubovych/markdownlint-cli
  rev: v0.39.0
  hooks:
    - id: markdownlint
      args: [--fix]
```

### Python Linting

For Python scripts, plugins, and modules within Ansible projects.

**Ruff Configuration (pyproject.toml):**

```toml
[tool.ruff]
target-version = "py310"
line-length = 120

[tool.ruff.lint]
select = [
    "E", "W",  # pycodestyle
    "F",       # pyflakes
    "I",       # isort
    "B",       # flake8-bugbear
    "C4",      # flake8-comprehensions
    "UP",      # pyupgrade
    "ARG",     # flake8-unused-arguments
    "PTH",     # flake8-use-pathlib
    "SIM",     # flake8-simplify
]
ignore = [
    "E501",    # line length (handled by formatter)
]

[tool.ruff.lint.per-file-ignores]
"tests/*" = ["ARG"]
"plugins/*" = ["E402", "ARG002"]
```

**MyPy Configuration (pyproject.toml):**

```toml
[tool.mypy]
python_version = "3.10"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
check_untyped_defs = true
no_implicit_optional = true
strict_equality = true

[[tool.mypy.overrides]]
module = ["ansible.*", "pytest_ansible.*"]
ignore_missing_imports = true
```

### Pre-commit Integration

All projects must use pre-commit hooks for automated linting.

**.pre-commit-config.yaml:**

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
        args: [--unsafe]
      - id: check-added-large-files
      - id: check-merge-conflict

  - repo: https://github.com/adrienverge/yamllint
    rev: v1.35.0
    hooks:
      - id: yamllint
        args: [-c=.yamllint]

  - repo: https://github.com/ansible/ansible-lint
    rev: v24.2.0
    hooks:
      - id: ansible-lint
        additional_dependencies:
          - ansible-core>=2.15

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.3.0
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
        args: [--ignore-missing-imports]
```

### CI/CD Integration

**GitHub Actions Workflow:**

```yaml
name: 🔍 Lint

on:
  pull_request:
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install ansible-lint yamllint ruff mypy

      - name: Run yamllint
        run: yamllint .

      - name: Run ansible-lint
        run: ansible-lint

      - name: Run ruff
        run: |
          ruff check .
          ruff format --check .

      - name: Run mypy
        run: mypy plugins scripts
        continue-on-error: true # Warning only initially

      - name: Run markdownlint
        uses: DavidAnson/markdownlint-cli2-action@v15
        with:
          globs: "**/*.md"
```

### Why Specific Rules Are Enabled/Disabled

**Enabled Rules Rationale:**

- `no-log-password`: Prevents accidental credential exposure in logs
- `empty-string-compare`: Catches common logic errors with empty strings
- `args`: Ensures module arguments are properly formatted
- `name[prefix]`: Enforces consistent task naming for better logging
- `yaml[empty-values]`: Prevents ambiguous empty values in YAML

**Disabled/Warning Rules Rationale:**

- `fqcn[action-core]`: Allow short names for built-in modules (e.g., `debug` vs `ansible.builtin.debug`)
- `name[casing]`: Allow flexibility in variable naming for existing codebases
- `galaxy[no-changelog]`: Not needed for internal-only roles
- `experimental`: New rules that may have false positives

**Profile-Based Approach:**

- Start with `basic` for new projects
- Progress to `moderate` → `safety` → `shared` → `production`
- Each level adds more stringent checks without breaking existing code

### How to Handle Linting Errors

1. **Understand the Error:**

   ```bash
   # Get detailed information about a rule
   ansible-lint --help rule-name
   ```

2. **Fix the Issue (Preferred):**

   ```bash
   # Auto-fix where possible
   ansible-lint --write
   ```

3. **Document Legitimate Exceptions:**

   ```yaml
   # Inline for specific instances
   - name: Complex shell operation # noqa: command-instead-of-module
     ansible.builtin.shell: |
       complex_command | with_pipes
   ```

4. **Update Project Configuration:**

   ```yaml
   # In .ansible-lint for project-wide exceptions
   skip_list:
     - rule-id # Document why this is skipped
   ```

### When to Use Ignore Comments

**Acceptable Uses:**

- **External Code**: Third-party roles we don't control
- **Legacy Code**: During gradual migration
- **Complex Shell**: When modules genuinely can't replace shell commands
- **False Positives**: Documented tool limitations

**Unacceptable Uses:**

- Avoiding proper fixes due to time constraints
- Hiding security vulnerabilities
- Bypassing style guidelines without team agreement

**Ignore File Format (.ansible-lint-ignore):**

```text
# Format: path/to/file rule-id
# Legacy playbook - will refactor in PROJ-123
playbooks/legacy-app.yml name[casing]

# External galaxy role
roles/geerlingguy.mysql/* fqcn
```

### Performance Considerations

**File Exclusions:**

```yaml
exclude_paths:
  - .cache/ # Ansible fact cache
  - .venv/ # Python virtual environments
  - archive/ # Old code for reference
  - molecule/ # Test scenarios (lint separately)
```

**Parallel Execution:**

```bash
# Run linters in parallel during CI
yamllint . &
ansible-lint &
ruff check . &
wait
```

**Caching Strategies:**

- Use `actions/cache@v3` for Python dependencies
- Cache pre-commit environments
- Store ansible-lint cache between runs

**CI/CD Optimizations:**

- Run linting only on changed files for PRs
- Use matrix builds for multiple Python versions
- Fail fast on critical errors

## Rationale

Automated linting improves code quality by:

1. **Consistency**: Enforces uniform style across all contributors
2. **Early Detection**: Catches bugs before they reach production
3. **Security**: Identifies potential vulnerabilities automatically
4. **Learning**: Teaches best practices through rule explanations
5. **Efficiency**: Reduces time spent on style discussions in reviews
6. **Documentation**: Self-documenting code through consistent patterns

## Examples

### Good Example - Production-Ready Playbook

```yaml
---
# playbook.yml passing all production profile checks

- name: Configure web servers | Production deployment
  hosts: webservers
  become: true
  gather_facts: true

  vars:
    nginx_version: "1.24.0"
    app_port: 8080
    enable_ssl: true

  tasks:
    - name: Install nginx | Package installation
      ansible.builtin.package:
        name: "nginx={{ nginx_version }}"
        state: present
      notify: restart nginx

    - name: Configure nginx | Template deployment
      ansible.builtin.template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: "0644"
        validate: "nginx -t -c %s"
      changed_when: true
      notify: reload nginx

    - name: Ensure nginx is running | Service management
      ansible.builtin.systemd:
        name: nginx
        state: started
        enabled: true
        daemon_reload: true

  handlers:
    - name: restart nginx
      ansible.builtin.systemd:
        name: nginx
        state: restarted

    - name: reload nginx
      ansible.builtin.systemd:
        name: nginx
        state: reloaded
```

### Bad Example - Common Linting Violations

```yaml
# This playbook has multiple linting issues

- hosts: all # ERROR: missing 'name' for play
  tasks:
    - shell: apt-get update # ERROR: should use package module

    - name: install_nginx # WARNING: name[casing] - should use spaces
      apt: name=nginx state=latest # ERROR: 'latest' is non-deterministic

    - command: systemctl start nginx # ERROR: should use systemd module
      # ERROR: missing 'changed_when' condition

    - name: Set permissions
      file:
        path: /var/www
        mode: 755 # ERROR: should use '0755' (octal notation)
```

## Exceptions

Linting rules may be relaxed for:

1. **Emergency Hotfixes**: Use `profile: min` temporarily
2. **Legacy Code Migration**: Use `.ansible-lint-ignore` for gradual improvement
3. **Third-party Code**: External roles/collections we don't control
4. **Generated Code**: Automatically generated playbooks/tasks

## Migration

### Implementing Linting in Existing Projects

1. **Start with Basic Profile:**

   ```bash
   echo "profile: basic" > .ansible-lint
   ansible-lint --write  # Auto-fix what's possible
   ```

2. **Generate Initial Ignore File:**

   ```bash
   ansible-lint --generate-ignore
   ```

3. **Progressively Increase Strictness:**

   - Fix violations category by category
   - Move from basic → moderate → safety → shared → production
   - Remove entries from `.ansible-lint-ignore` as issues are resolved

4. **Add Pre-commit Hooks:**

   ```bash
   pre-commit install
   pre-commit run --all-files  # Initial run
   ```

5. **Enable CI/CD Checks:**
   - Add GitHub Actions workflow
   - Make linting required for PR merges

### Useful Commands

```bash
# List all available rules
ansible-lint --list-rules

# Show rule details
ansible-lint --help rule-name

# Run specific profile
ansible-lint --profile moderate

# Fix auto-fixable issues
ansible-lint --write

# Validate specific files
ansible-lint playbooks/site.yml

# Check YAML syntax only
yamllint -d .yamllint .

# Format Python code
ruff format .
ruff check --fix .

# Type checking
mypy plugins scripts --show-error-codes

# Markdown linting
markdownlint-cli2 "**/*.md" "#.venv" --fix

# Check specific markdown file
markdownlint-cli2 docs/standards/documentation-standards.md
```

## References

- [Ansible Lint Documentation](https://ansible-lint.readthedocs.io/)
- [YAMLLint Documentation](https://yamllint.readthedocs.io/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [MyPy Documentation](https://mypy.readthedocs.io/)
- [Pre-commit Framework](https://pre-commit.com/)
- [Markdownlint Documentation](https://github.com/DavidAnson/markdownlint)
- [Markdownlint Rules](https://github.com/DavidAnson/markdownlint/blob/main/doc/Rules.md)
- [Mission Control Standards](https://github.com/basher83/docs/tree/main/mission-control)
