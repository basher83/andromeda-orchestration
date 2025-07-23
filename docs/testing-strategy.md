# Testing Strategy

This document outlines the testing and quality assurance approach for the NetBox Ansible project.

## Overview

We use a comprehensive testing strategy that includes:
- **Linting** - Static code analysis for style and best practices
- **Unit Testing** - Testing individual components (Python plugins)
- **Integration Testing** - Testing playbook functionality
- **Security Scanning** - Detecting vulnerabilities and secrets

## Tools and Configuration

### 1. Ansible Lint

**Tool**: `ansible-lint`  
**Config**: `.ansible-lint`  
**Purpose**: Enforce Ansible best practices and catch common mistakes

```bash
# Run ansible-lint
uv run ansible-lint

# Run on specific file
uv run ansible-lint playbooks/site.yml

# Show all warnings (not just errors)
uv run ansible-lint --profile=shared
```

Key rules enforced:
- Proper task naming conventions
- FQCN (Fully Qualified Collection Names) usage
- Idempotency checks
- Security best practices (no-log for passwords)

### 2. YAML Lint

**Tool**: `yamllint`  
**Config**: `.yamllint`  
**Purpose**: Ensure consistent YAML formatting

```bash
# Run yamllint
uv run yamllint .

# Run on specific directory
uv run yamllint playbooks/

# Auto-fix issues (limited)
uv run yamllint --format parsable . | sed -e 's/^\([^:]*:[^:]*\):/::error file=\1,line=/'
```

### 3. Python Tools (for plugins/scripts)

**Tools**: `ruff`, `mypy`  
**Config**: `pyproject.toml`  
**Purpose**: Python code quality and type checking

```bash
# Install with uv (recommended)
uv pip install -e ".[dev]"

# Run ruff (linting + formatting)
uv run ruff check .
uv run ruff format .

# Run mypy (type checking)
uv run mypy plugins scripts
```

### 4. Pre-commit Hooks

**Tool**: `pre-commit`  
**Config**: `.pre-commit-config.yaml`  
**Purpose**: Automated checks before commits

```bash
# Install pre-commit
uv pip install pre-commit

# Set up hooks
uv run pre-commit install

# Run manually on all files
uv run pre-commit run --all-files

# Update hook versions
uv run pre-commit autoupdate
```

### 5. Molecule (Role Testing)

**Tool**: `molecule`  
**Config**: `molecule/default/molecule.yml`  
**Purpose**: Test Ansible roles in isolation

```bash
# Test a role
cd roles/my-role
uv run molecule test

# Run specific scenario
uv run molecule test -s default

# Just converge (skip teardown)
uv run molecule converge

# Interactive testing
uv run molecule create
uv run molecule converge
uv run molecule login
uv run molecule destroy
```

### 6. Integration Testing

For testing complete playbooks:

```bash
# Syntax check
uv run ansible-playbook playbooks/site.yml --syntax-check

# Dry run
uv run ansible-playbook playbooks/site.yml --check

# List tasks
uv run ansible-playbook playbooks/site.yml --list-tasks

# List affected hosts
uv run ansible-playbook playbooks/site.yml --list-hosts
```

## CI/CD Integration

GitHub Actions workflows (`.github/workflows/`):

1. **ci.yml** - Runs on every push/PR:
   - Linting (ansible-lint, yamllint)
   - Python quality checks
   - Security scanning
   - Molecule tests (if roles exist)

2. **release.yml** - Runs on version tags:
   - Full test suite
   - Build artifacts
   - Create GitHub release

## Local Development Workflow

### Initial Setup

```bash
# Clone repository
git clone <repo>
cd netbox-ansible

# Use task for complete setup
task setup

# Or manually:
uv venv
source .venv/bin/activate  # or .venv/Scripts/activate on Windows
uv pip install -e ".[dev]"
uv run pre-commit install
uv run ansible-galaxy collection install -r requirements.yml
```

### Before Committing

1. **Run linters**:
   ```bash
   uv run yamllint .
   uv run ansible-lint
   uv run ruff check .
   ```

2. **Run tests**:
   ```bash
   # Test playbooks
   uv run ansible-playbook playbooks/test_*.yml --check
   
   # Test Python code
   uv run pytest tests/
   ```

3. **Check secrets**:
   ```bash
   # Detect secrets
   uv run detect-secrets scan --baseline .secrets.baseline
   ```

### Writing Tests

#### For Playbooks

Create test playbooks in `tests/`:

```yaml
---
# tests/test_1password_integration.yml
- name: Test 1Password integration
  hosts: localhost
  gather_facts: false
  tasks:
    - name: Verify 1Password lookup works
      ansible.builtin.debug:
        msg: "{{ lookup('community.general.onepassword', 'Test Item', field='password') }}"
      failed_when: false
      changed_when: false
```

#### For Python Plugins

Create pytest tests in `tests/`:

```python
# tests/test_onepassword_connect.py
import pytest
from plugins.lookup import onepassword_connect

def test_lookup_initialization():
    lookup = onepassword_connect.LookupModule()
    assert lookup is not None

def test_invalid_credentials():
    with pytest.raises(AnsibleError):
        lookup = onepassword_connect.LookupModule()
        lookup.run(["InvalidItem"], variables={})
```

## Best Practices

1. **Always run pre-commit** before pushing:
   ```bash
   uv run pre-commit run --all-files
   ```

2. **Fix linting issues** immediately:
   ```bash
   # Auto-fix Python
   uv run ruff check --fix .
   uv run ruff format .
   
   # Review Ansible issues
   uv run ansible-lint --fix
   ```

3. **Test incrementally**:
   - Test individual tasks/plays during development
   - Use `--check` mode frequently
   - Validate inventory before running playbooks

4. **Document test requirements**:
   - Add comments for complex test scenarios
   - Document any external dependencies
   - Provide example test data

## Troubleshooting Tests

### Common Issues

1. **Ansible-lint failures**:
   - Check `.ansible-lint` for skip rules
   - Use inline comments: `# noqa: rule-name`
   - Consider if the rule is highlighting a real issue

2. **YAML formatting**:
   - Ensure consistent indentation (2 spaces)
   - Check for trailing whitespace
   - Validate special characters in strings

3. **Python type errors**:
   - Add type annotations to functions
   - Use `typing` module for complex types
   - Add `# type: ignore` sparingly with justification

4. **Molecule failures**:
   - Check Docker is running
   - Verify image availability
   - Review `molecule/default/molecule.yml` settings

## Security Testing

1. **Secret Detection**:
   ```bash
   # Initial baseline
   uv run detect-secrets scan > .secrets.baseline
   
   # Audit baseline
   uv run detect-secrets audit .secrets.baseline
   ```

2. **Dependency Scanning**:
   ```bash
   # With pip-audit
   uv run pip-audit
   
   # With safety
   uv run safety check
   ```

## Performance Testing

For large inventories or complex playbooks:

```bash
# Profile task execution
ANSIBLE_CALLBACKS_ENABLED=ansible.posix.profile_tasks \
  uv run ansible-playbook playbooks/site.yml

# Limit concurrent connections
uv run ansible-playbook playbooks/site.yml --forks=10

# Debug slow tasks
ANSIBLE_DEBUG=1 uv run ansible-playbook playbooks/site.yml -vvv
```

## Continuous Improvement

- Review failed CI runs for patterns
- Update tool versions regularly
- Add new test cases for bugs
- Document testing patterns that work well
- Share knowledge with team members