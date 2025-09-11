# MegaLinter Configuration Files

This directory contains MegaLinter-specific configuration files for the Andromeda IaC repository.

## Files

- **`.yamllint`** - YAML linting rules and style configuration
- **`.ansible-lint`** - Ansible playbook and role linting configuration
- **`.markdownlint.json`** - Markdown style and formatting rules
- **`.actionlint.yml`** - GitHub Actions workflow linting configuration

## Organization

These files are organized here for better:

- **Version control**: Track linter configuration changes
- **Maintainability**: Centralized location for all linter rules
- **Collaboration**: Easier to review and update linting standards

## Integration

These configuration files are referenced by:

- **`.mega-linter.yml`** - Main MegaLinter configuration
- **GitHub Actions workflows** - CI/CD pipeline configuration

## Usage

### Local Development

```bash
# Test specific linter configurations
mise run act-yaml      # Test YAML linters
mise run act-ansible   # Test Ansible linters
mise run act-markdown  # Test Markdown linters
```

### Configuration Updates

1. Edit the configuration files in this directory
2. Test changes locally using the mise tasks
3. Commit and push to trigger CI validation
4. Monitor CI results for any issues

## Maintenance

- Keep configurations in sync with MegaLinter updates
- Review and update rules periodically based on project needs
- Document any custom rules or exceptions

## Related Documentation

- [`../../docs/getting-started/megalinter-implementation.md`](../docs/getting-started/megalinter-implementation.md) - Implementation guide
- [`../../docs/standards/megalinter-standards.md`](../docs/standards/megalinter-standards.md) - Standards and best practices
