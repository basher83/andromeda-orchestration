# Linting Standards

## Purpose
Define code quality standards enforced through automated linting tools.

## Background
[TODO]: Add background on why consistent code style and quality checks matter

## Standard

### Why Specific Rules Are Enabled/Disabled
[TODO]: Document rationale for each linting configuration:
- YAML linting rules
- Ansible-lint rules
- Python linting (ruff)
- Shell script linting

### How to Handle Linting Errors
[TODO]: Define process for addressing linting issues:
- Fix vs ignore decisions
- Documenting exceptions
- Updating configurations
- Team communication

### When to Use Ignore Comments
[TODO]: Document acceptable uses of ignore directives:
- Legitimate exceptions
- Temporary workarounds
- External code
- Documentation requirements

### Tool-specific Configurations
[TODO]: Explain each tool's configuration:
- `.yamllint` settings
- `.ansible-lint` configuration
- `pyproject.toml` for ruff
- Pre-commit hook configs

### Performance Considerations
[TODO]: Document linting performance optimizations:
- File exclusions
- Parallel execution
- Caching strategies
- CI/CD optimizations

## Rationale
[TODO]: Explain why automated linting improves code quality

## Examples

### Good Example
[TODO]: Show code that passes all linters

### Bad Example
[TODO]: Show common linting violations

## Exceptions
[TODO]: When linting rules can be bypassed

## Migration
[TODO]: How to fix linting issues in existing code

## References
- [Yamllint Documentation](https://yamllint.readthedocs.io/)
- [Ansible-lint Documentation](https://ansible-lint.readthedocs.io/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)