# 🔒 Security Policy

## 🛡️ Mission Security Statement

Security is paramount to the andromeda-orchestration project and its infrastructure. We take the security of this
repository and its users seriously and appreciate your help in keeping our systems safe.

## 🚨 Supported Versions

As a continuously updated documentation repository, we maintain security for:

| Version     | Supported    | Security Updates  |
| ----------- | ------------ | ----------------- |
| main        | ✅ Current   | Full support      |
| PR branches | ⚠️ Limited   | During review     |
| Forks       | ❌ Community | No direct support |

**Recommendation:** Always use the latest main branch for the most secure and up-to-date
documentation.

## 🔍 Reporting Security Vulnerabilities

### 🚨 Critical Security Issues

**DO NOT** report security vulnerabilities through public GitHub issues, discussions, or pull
requests.

Instead, please report security vulnerabilities through one of these secure channels:

#### GitHub Security Advisories (Preferred)

1. Go to the [Security tab](https://github.com/basher83/docs/security/advisories)
2. Click "Report a vulnerability"
3. Fill out the security advisory form
4. Submit your report

#### Direct Contact (fallback only)

- Email: security (at) example.org (used only if you cannot access GitHub Security Advisories)
- Expected first response: within 48 hours (business days)

### 📋 What to Include in Your Report

Please provide as much information as possible:

**🎯 Vulnerability Details:**

- Type of vulnerability (e.g., exposed secrets, malicious scripts, XSS in markdown)
- Affected files, configurations, or workflows
- Attack vector and prerequisites
- Potential impact on users or systems

**🔍 Reproduction Steps:**

1. Detailed step-by-step reproduction
2. Proof of concept if applicable
3. Screenshots if helpful
4. Any special setup required

**💥 Impact Assessment:**

- What sensitive information could be exposed?
- What systems could be compromised?
- Could this affect users who clone/fork the repository?

### 🚀 Our Response Process

**Within 48 hours:**

- Acknowledge receipt of your report
- Begin initial assessment
- Assign a tracking ID for communication

**Within 1 week:**

- Complete vulnerability verification
- Assess severity and impact
- Develop remediation timeline

**Resolution:**

- Develop and test security fix
- Prepare security advisory if needed
- Release fix and notify affected users

**Target remediation timelines (by severity):**

- Critical: fix or effective mitigation within 7–14 days
- High: within 30 days
- Medium: within 60 days
- Low/Informational: best effort, scheduled as capacity allows

**Coordinated disclosure:**

- We prefer coordinated disclosure. Unless we agree otherwise in writing, we aim to publish an advisory once a fix or reasonable mitigation is available, or 90 days after acknowledgment—whichever comes first.

## 🛡️ Security Measures

### 🔐 Repository Security

- **Branch Protection:** Main branch requires reviews and status checks
- **Actions Security:** All GitHub Actions are pinned to specific SHAs
- **Secret Management:** Using Infisical for secure secret storage
- **Code Review:** All changes require review before merging

### 🔒 Secrets & Credentials

- **No Direct Secrets:** Never commit secrets directly to the repository
- **Template Files:** Use `.template` files for configuration examples
- **Gitignore:** Properly configured to exclude sensitive files
- **Secret Scanning:** Automated scanning with gitleaks and detect-secrets

### 🏗️ CI/CD Security

- **Pinned Actions:** All GitHub Actions use SHA pinning
- **Minimal Permissions:** Workflows use least-privilege permissions
- **Dependency Updates:** Automated updates via Renovate
- **Security Checks:** Pre-commit hooks for secret detection

### 👥 Development Security

- **Pre-commit Hooks:** Automated security checks before commits
- **Linting:** Shell scripts checked with shellcheck
- **Documentation:** Security best practices documented
- **MCP Configuration:** Secure handling of API keys

## 🔍 Security Auditing

### Automated Security Checks

- **Every Commit:** Pre-commit hooks scan for secrets
- **Every PR:** GitHub Actions verify security policies
- **Continuous:** Dependabot and Renovate monitor dependencies

### Security Tools in Use

- **gitleaks:** Scans for exposed secrets
- **detect-secrets:** Additional secret detection
- **shellcheck:** Shell script vulnerability scanning
- **GitHub Security:** Native security features enabled

## 📊 Security Configuration Files

### Key Security Files

- `.gitignore` - Excludes sensitive files
- `.gitleaks.toml` - Gitleaks configuration
- `.secrets.baseline` - Detect-secrets baseline
- `mcp.json.template` - Template for secure configuration
- `.github/workflows/*` - Secured CI/CD pipelines

## 🎯 Responsible Disclosure

### Our Commitment

- We will acknowledge your report within 48 hours
- We will provide regular updates on our progress
- We will credit you in our security advisory (unless you prefer anonymity)
- We will not pursue legal action against researchers who follow responsible disclosure

### Your Responsibilities

When researching vulnerabilities, please:

- **Respect privacy** - Don't access private repositories or user data
- **Minimize impact** - Don't perform destructive actions
- **Report promptly** - Submit findings as soon as possible
- **Keep confidential** - Don't disclose until we've addressed the issue

### Out of Scope

The following are generally out of scope:

- Issues in third-party services (GitHub, Infisical, etc.)
- Social engineering attacks
- Denial of service attacks
- Issues already reported or known

## 🔧 Security Best Practices for Contributors

### Before Contributing

- Never commit real API keys or tokens
- Use template files for configuration examples
- Run pre-commit hooks before pushing
- Review your changes for sensitive data

### Working with Secrets

- Use Infisical for secret management
- Generate `.mcp.json` from template using the provided script
- Keep `.env` and similar files in `.gitignore`
- Use environment variables for sensitive values

### GitHub Actions

- Always pin Actions to specific SHAs
- Use minimal required permissions
- Don't echo secrets in logs
- Use GitHub Secrets for sensitive values

## 📚 Security Resources

### Documentation

- [Mise Setup Guide](./docs/getting-started/mise-setup-guide.md)
- [Repository Setup Guide](./docs/getting-started/README.md)

### Scripts

- `scripts/generate-mcp-config.sh` - Secure config generation
- `scripts/setup.sh` - Secure environment setup

### Configuration

- `.mise.toml` - Security tasks and linting
- `.pre-commit-config.yaml` - Automated security checks

## 🏆 Security Contributors

We recognize security researchers who have helped improve our security:

_Be the first to help us improve our security!_

## 📞 Contact Information

### Security Team

- **GitHub Security Advisories:**
  [Report a vulnerability](https://github.com/basher83/docs/security/advisories/new)
- **Response Time:** 48 hours maximum

## 📄 Legal

### Safe Harbor

We support responsible security research and will not pursue legal action against researchers who:

- Make a good faith effort to comply with this policy
- Report vulnerabilities promptly and responsibly
- Avoid privacy violations, data destruction, or service disruption
- Give us reasonable time to address issues before disclosure

We consider activities conducted consistent with this policy to constitute “good-faith” research.
We will not initiate or support legal action under anti-hacking or anti-circumvention laws (including
computer misuse or DMCA §1201) against parties who comply with this policy and report vulnerabilities responsibly.

### Privacy

Security reports may contain sensitive information. We commit to:

- Handling all reports confidentially
- Only sharing information on a need-to-know basis
- Obtaining permission before sharing your contact information

---

**Thank you for helping keep our documentation secure!** 🚀🔒

_This security policy is effective as of August 2025._
