# MegaLinter Troubleshooting Guide

## Common Issues and Solutions

### 1. SARIF Report Upload Failures

**Error**: `Path does not exist: megalinter-report.sarif`

**Solution**: 
- Ensure SARIF_REPORT_FILE points to `megalinter-reports/megalinter-report.sarif`
- Check that SARIF_REPORTER is set to `true`
- Verify MegaLinter completes successfully before SARIF upload step

**Configuration**:
```yaml
env:
  SARIF_REPORTER: true
  SARIF_REPORT_FILE: megalinter-reports/megalinter-report.sarif
```

### 2. Massive Linting Errors Breaking Builds

**Error**: Hundreds of ansible-lint, mypy, or other linter errors

**Solution**: Use gradual enforcement approach
- Add problematic linters to `DISABLE_ERRORS_LINTERS`
- Let them generate warnings instead of errors
- Gradually fix issues and re-enable strict mode

**Configuration**:
```yaml
env:
  DISABLE_ERRORS_LINTERS: ANSIBLE_ANSIBLE_LINT,PYTHON_MYPY,YAML_YAMLLINT
```

### 3. Performance Issues and Timeouts

**Error**: Workflow times out or runs very slowly

**Solutions**:
- Increase timeout (currently 30 minutes)
- Improve exclude patterns to skip unnecessary files
- Use PARALLEL processing with appropriate process count
- Consider disabling slower linters temporarily

**Configuration**:
```yaml
env:
  PARALLEL: true
  PARALLEL_PROCESS_COUNT: 4
  FILTER_REGEX_EXCLUDE: '(cache|node_modules|\.git|test/output)'
```

### 4. Security Scanner False Positives

**Error**: Gitleaks or Trivy flagging legitimate code

**Solutions**:
- Add specific excludes to security scanner configs
- Review findings to separate real issues from false positives
- Use `.gitleaksignore` or `.trivyignore` files for specific exclusions

### 5. Schema Validation Failures (YAML_V8R)

**Error**: YAML schema validation errors for action files

**Solution**: 
- Temporarily disable YAML_V8R if causing widespread issues
- Fix specific schema problems incrementally
- Use yamllint for basic YAML validation instead

## Quick Fixes

### Test Configuration Locally
```bash
# Quick local test
./scripts/test-megalinter.sh --quick

# Test specific linter
./scripts/test-megalinter.sh --linter=ANSIBLE_ANSIBLE_LINT

# Diagnostic mode
./scripts/diagnose-megalinter.sh
```

### Common Configuration Patterns

**Development Branch (Warnings Only)**:
```yaml
DISABLE_ERRORS_LINTERS: ANSIBLE_ANSIBLE_LINT,PYTHON_MYPY,YAML_YAMLLINT,MARKDOWN_MARKDOWNLINT
```

**Production Branch (Strict)**:
```yaml
FAIL_ON_ERROR: true
DISABLE_ERRORS_LINTERS: ""
```

**Performance Optimized**:
```yaml
PARALLEL: true
PARALLEL_PROCESS_COUNT: 4
FILTER_REGEX_EXCLUDE: '(^|/)(.git/|.cache/|node_modules/|test/)'
```

## Getting Help

1. **Check Workflow Logs**: Look for specific error messages in GitHub Actions
2. **Review MegaLinter Reports**: Download the megalinter-results artifact
3. **Test Locally**: Use the provided scripts to reproduce issues locally
4. **Documentation**: https://megalinter.io/troubleshooting/
5. **Configuration Reference**: https://megalinter.io/configuration/

## Emergency Fixes

If MegaLinter is completely blocking development:

1. **Disable Failing Linters**: Add them to `DISABLE_LINTERS`
2. **Switch to Warning Mode**: Use `DISABLE_ERRORS_LINTERS`
3. **Reduce Scope**: Use `FILTER_REGEX_INCLUDE` to limit file scanning
4. **Temporary Bypass**: Comment out MegaLinter step in workflow (not recommended)

## Version Specific Issues

### MegaLinter v8
- SARIF output path changed to megalinter-reports/ subdirectory
- Some linters have updated rule sets
- Performance improvements but may need timeout adjustments