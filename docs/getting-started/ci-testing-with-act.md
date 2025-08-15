# CI Testing with Act

This guide explains how to test GitHub Actions workflows locally using `act` before pushing changes.

## Overview

[Act](https://github.com/nektos/act) allows you to run GitHub Actions locally, providing fast feedback on workflow changes without requiring git commits or waiting for GitHub's runners.

## Installation

Act should be installed system-wide in `/usr/local/bin/act`.

To install or reinstall:

```bash
# Install act to /usr/local/bin
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Verify installation
act --version
```

## Configuration

Act uses Docker containers to simulate GitHub Actions runners. Configure the default image:

```bash
# Create act configuration (already done in this repo)
echo "-P ubuntu-latest=catthehacker/ubuntu:act-latest" > ~/.actrc
```

## Basic Usage

### List Available Workflows

```bash
# List all workflows and jobs
act -l

# Example output:
# Stage  Job ID          Job name                        Workflow name
# 0      ansible-lint    Ansible Lint & Syntax           CI
# 0      yaml-lint       YAML Lint                       CI
# 0      python-quality  Python Quality                  CI
```

### Test Workflows

```bash
# Dry run (show what would execute)
act push --dryrun

# Run all jobs for push event
act push

# Run specific job
act -j python-quality

# Run workflow for pull request event
act pull_request

# Run with specific workflow file
act --workflows .github/workflows/ci.yml
```

### Common Testing Scenarios

#### Test Before Committing

```bash
# Quick validation of workflow syntax
act push --dryrun

# Run linting jobs locally
act -j ansible-lint
act -j yaml-lint
act -j python-quality
```

#### Test Security Scans

```bash
# Run Infisical secret scanning
act -j secret-scan

# Run KICS infrastructure scanning
act -j kics-scan
```

#### Test Specific Events

```bash
# Test scheduled workflow
act schedule

# Test manual workflow dispatch
act workflow_dispatch
```

## VS Code Integration

If using the GitHub Actions extension for VS Code:

1. Install the extension: "GitHub Actions" by GitHub
2. Open the Actions sidebar
3. Right-click on a workflow and select "Run Locally with Act"

**Note**: Ensure `act` is installed in `/usr/local/bin/act`

## Troubleshooting

### Act Command Not Found

If `act` is not found:

```bash
# Check if act is installed
which act

# If not found, reinstall
curl --proto '=https' --tlsv1.2 -sSf https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

### Docker Issues

```bash
# Ensure Docker is running
docker info

# Clean up old act containers
docker container prune
```

### Resource Limitations

Act can be resource-intensive. For large workflows:

```bash
# Run specific jobs instead of entire workflow
act -j specific-job-name

# Use smaller Docker images for simple tests
act -P ubuntu-latest=node:16-slim
```

## CI Workflow Overview

Our unified CI workflow (`.github/workflows/ci.yml`) includes:

- **ansible-lint**: Ansible playbook linting and syntax checking
- **yaml-lint**: YAML file validation
- **python-quality**: Python code quality (ruff, mypy)
- **markdown-lint**: Documentation formatting
- **secret-scan**: Infisical secret detection
- **kics-scan**: Infrastructure security scanning

## Best Practices

1. **Test locally first**: Run `act push --dryrun` before committing
2. **Fix issues locally**: Use `task fix` to auto-fix linting issues
3. **Test specific jobs**: Don't run all jobs if you only changed Python code
4. **Use caching**: Act caches Docker images after first pull
5. **Clean up**: Remove old containers with `docker container prune`

## Related Documentation

- [Pre-commit Setup](pre-commit-setup.md) - Git hooks for code quality
- [Repository Structure](repository-structure.md) - Project organization
- [Troubleshooting](troubleshooting.md) - Common issues and solutions
