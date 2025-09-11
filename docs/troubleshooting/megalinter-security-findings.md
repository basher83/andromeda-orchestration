# MegaLinter Security Scan Findings

## Current Status

The MegaLinter workflow includes security scanning via gitleaks and trivy. Recent runs have detected some potential issues that need investigation:

### GitLeaks Findings

- **Status**: 1 error, 68 warnings
- **Description**: Scans for secrets in git history and current files
- **Action Required**: Review findings to determine if actual secrets or false positives

### Trivy Findings

- **Status**: 2 errors, 3 warnings
  > Source: See GitHub Actions → MegaLinter job → Artifact “megalinter-reports/megalinter-report.sarif”.
- **Description**: Scans for known vulnerabilities in dependencies
- **Action Required**: Review dependency versions and update if necessary

## Investigation Notes

### Potential Sources

1. **Example passwords in comments** - PostgreSQL job file contains `changeme` examples in comments
1. **False Positive Tuning**: Add excludes for legitimate examples and templates
1. **Dependency Updates**: Update vulnerable packages to latest secure versions
1. **Secret Scanning Config**: Tune `.gitleaks.toml` to ignore specific patterns in comments/docs

## References

- GitLeaks: <https://github.com/gitleaks/gitleaks>
- Trivy: <https://github.com/aquasecurity/trivy>
- MegaLinter Security: <https://megalinter.io/latest/descriptors/repository/>
