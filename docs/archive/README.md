# Archive Directory

This directory contains archived documentation and files that are no longer actively used but may be useful for historical reference.

## Current Archive Contents

### `/infisical/`

- Consolidated Infisical documentation files from August 26, 2025
- `infisical-setup.md` - General setup guide (consolidated into infisical-complete-guide.md)
- `andromeda-infisical-config.md` - Project-specific config (consolidated into infisical-complete-guide.md)

### Standalone Files

- `assessment-playbook-fixes.md` - Historical assessment playbook fixes from July 2025
- `documentation-review-findings.md` - Documentation review findings from July 2025

## Purged Content (August 26, 2025)

### Complete 1Password Purge

All 1Password-related content has been **permanently removed** from the repository as it has been fully deprecated and replaced by Infisical. This includes:

**Removed Files:**

- `1pass.md` - 1Password Connect collection documentation
- `1password-integration.md` - 1Password setup guide
- `1password-connect-troubleshooting.md` - 1Password troubleshooting
- `1PASSWORD_ARCHIVE_SUMMARY.md` - Archive summary
- `consul-1password-setup.md` - Consul ACL with 1Password
- `ansible-connect` - Legacy wrapper script for 1Password
- All 1Password-specific playbooks and examples
- All 1Password environment setup scripts
- All 1Password lookup plugins
- All 1Password inventory files

**Removed Directories:**

- `/bin/` - Contained ansible-connect wrapper
- `/doggos-homelab/` - Contained 1Password inventory files
- `/og-homelab/` - Contained 1Password inventory files
- `/playbooks/` - Contained 1Password example playbooks
- `/plugins/` - Contained 1Password lookup plugin
- `/scripts/` - Contained 1Password setup scripts

## Migration Status

✅ **Complete**: The project has fully migrated to:

- **Infisical** for repository/automation secrets
- **HashiCorp Vault** for application/service secrets

No 1Password dependencies or references remain in the codebase.

## Archive Policy

### When to Archive

Documents should be moved here when:

1. They describe deprecated functionality
2. They document completed one-time efforts
3. They contain outdated patterns that could confuse developers
4. They represent historical milestones

### When NOT to Archive

Do not archive:

1. Documentation that is still partially relevant
2. Files frequently referenced for context
3. Documentation that just needs updating

### Consider Deletion

After archiving, evaluate if content should be permanently removed to reduce repository size and confusion.

## Note

Files in this archive are preserved for historical reference only and should **not** be used in current implementations. Always refer to current documentation in `/docs/` for active development.
