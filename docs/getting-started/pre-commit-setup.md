# Pre-commit Hook Configuration

This document explains the pre-commit setup for this project and which tools are integrated.

## Active Pre-commit Hooks

The following hooks run automatically on `git commit` or via `uv run pre-commit run --all-files`:

### 1. General File Checks (pre-commit-hooks)

- **trailing-whitespace** - Removes trailing whitespace
- **end-of-file-fixer** - Ensures files end with a newline
- **check-yaml** - Validates YAML syntax
- **check-added-large-files** - Prevents large files (>1MB)
- **check-case-conflict** - Checks for filename case conflicts
- **check-merge-conflict** - Checks for merge conflict markers
- **detect-private-key** - Detects private keys
- **mixed-line-ending** - Fixes mixed line endings (LF)
- **pretty-format-json** - Formats JSON files

### 2. YAML Linting (yamllint)

- Checks YAML formatting according to `.yamllint` config
- Ensures consistent indentation, line length, etc.

### 3. Python Code Quality (ruff)

- **ruff** - Python linting
- **ruff-format** - Python formatting

### 4. Python Type Checking (mypy)

- Type checks Python code in `plugins/` and `scripts/`

### 5. Shell Script Linting (shellcheck)

- Validates shell scripts for common issues

### 6. Markdown Linting (markdownlint)

- Ensures consistent markdown formatting

## Tools Run Separately

Due to compatibility issues, these tools are run via task commands instead of pre-commit:

### 1. Ansible Lint

**Issue**: Module import errors in pre-commit environment
**Run via**: `mise run lint:ansible` or `uv run ansible-lint`

### 2. Security Scanning

**Issue**: Integration complexity with Infisical CLI and KICS Docker containers
**Run via**: `mise run security` (runs both Infisical secrets scan and KICS infrastructure scan)

- **Infisical secrets detection**: `mise run security:secrets`
- **KICS infrastructure scan**: `mise run security:kics`

## Recommended Workflow

1. **During development**: Run individual linters as needed

   ```bash
   mise run lint:yaml     # Check YAML files
   mise run lint:python   # Check Python code
   mise run lint:ansible  # Check Ansible playbooks
   ```

2. **Before committing**: Run all pre-commit hooks

   ```bash
   uv run pre-commit run --all-files  # Run all pre-commit hooks
   ```

3. **For comprehensive check**: Run all linters

   ```bash
   mise run lint  # Runs all linters including ansible-lint
   ```

## Automatic Fixes

Some issues can be automatically fixed:

```bash
mise run fix  # This would auto-fix Python and some Ansible issues (if task existed)
```

## Installation

Pre-commit hooks are installed automatically by `mise run setup`. To install manually:

```bash
uv run pre-commit install
```

## Updating Hook Versions

To update all pre-commit hooks to their latest versions:

```bash
uv run pre-commit autoupdate
```

## Skipping Hooks

If you need to skip hooks temporarily (not recommended):

```bash
git commit --no-verify
```

## Troubleshooting

### Hook Installation Issues

If hooks aren't running on commit:

```bash
uv run pre-commit install --force
```

### Cache Issues

Clear pre-commit cache:

```bash
uv run pre-commit clean
```

### Version Conflicts

If you see version conflicts, try:

1. Update the hooks: `uv run pre-commit autoupdate`
2. Clear cache: `uv run pre-commit clean`
3. Reinstall: `uv run pre-commit install --force`
