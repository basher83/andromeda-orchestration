# Archive Directory Documentation

This directory contains historical documentation, deprecated guides, and completed project artifacts that are retained for reference purposes.

## Directory Structure

```
archive/
├── README.md                              # This file
├── 1pass.md                              # Deprecated 1Password Connect collection guide
├── 1password-connect-troubleshooting.md  # Legacy 1Password troubleshooting
├── 1password-integration.md              # Deprecated 1Password integration guide
├── assessment-playbook-fixes.md          # Completed assessment playbook fixes (2025-07-28)
├── consul-1password-setup.md             # Deprecated Consul ACL with 1Password
├── documentation-review-findings.md      # Completed documentation review (2025-07-27)
├── bin/                                  # Archived utility scripts
│   └── ansible-connect                   # Legacy 1Password wrapper script
├── doggos-homelab/                       # Archived cluster-specific files
├── og-homelab/                           # Archived cluster-specific files
└── playbooks/                            # Archived playbook versions
```

## Archive Categories

### 1. Deprecated Secrets Management (1Password)

These files document the legacy 1Password Connect integration that has been replaced by Infisical:

- **1pass.md** - Comprehensive 1Password Connect Ansible collection documentation
- **1password-integration.md** - Setup and usage guide for 1Password with Ansible
- **1password-connect-troubleshooting.md** - Troubleshooting specific to 1Password Connect
- **consul-1password-setup.md** - How Consul ACL tokens were managed with 1Password

**Status**: Deprecated as of 2025-07-27  
**Replacement**: See `/docs/implementation/infisical/infisical-setup.md`

### 2. Completed Project Artifacts

- **documentation-review-findings.md** - Results of comprehensive documentation review conducted on 2025-07-27
  - Documents the migration from 1Password to Infisical
  - Lists all inconsistencies found and resolved
  - Serves as a reference for documentation standards

- **assessment-playbook-fixes.md** - Specific fixes for assessment playbooks completed on 2025-07-28
  - Documents Jinja2 filter errors and their solutions
  - Provides defensive coding patterns for robust playbooks
  - All fixes have been implemented and content migrated to troubleshooting.md

### 3. Archived Utility Scripts

- **bin/ansible-connect** - Legacy wrapper script for 1Password Connect integration
  - Used to inject 1Password credentials into Ansible environment
  - Replaced by direct `uv run ansible-*` commands with Infisical

### 4. Cluster-Specific Archives

- **doggos-homelab/** - Contains archived configurations and documentation specific to the doggos-homelab cluster
- **og-homelab/** - Contains archived configurations and documentation specific to the og-homelab cluster

### 5. Archived Playbooks

- **playbooks/** - Previous versions of playbooks that have been significantly refactored or replaced

## Archive Policy

### When to Archive

Documents should be moved to this archive when:
1. They describe deprecated functionality (e.g., 1Password after Infisical migration)
2. They document completed one-time efforts (e.g., migration guides, review findings)
3. They contain outdated patterns that could confuse new developers
4. They represent significant historical milestones in the project

### When NOT to Archive

Do not archive:
1. Documentation that is still partially relevant
2. Files that are frequently referenced for historical context
3. Documentation that just needs updating (update it instead)

### Archive Best Practices

1. **Add Deprecation Notice**: All deprecated docs should have a clear notice at the top pointing to current documentation
2. **Preserve Context**: Keep related files together (e.g., all 1Password docs)
3. **Document Reason**: Update this README when adding new items to explain why they were archived
4. **Consider Deletion**: After 1 year, evaluate if archived content is still needed

## Historical Context

### 1Password → Infisical Migration (2025-07)

The project migrated from 1Password Connect to Infisical for secrets management. This transition included:
- Moving all secrets to Infisical's `/apollo-13/` path structure
- Updating all playbooks and inventory files
- Comprehensive documentation review and cleanup
- Archiving all 1Password-related documentation

This migration improved:
- Cost efficiency (Infisical free tier vs 1Password subscription)
- Infrastructure-as-code capabilities
- CI/CD integration options
- Dynamic secrets support

## Accessing Archived Content

While these documents are deprecated, they may still be useful for:
- Understanding historical design decisions
- Migrating from similar setups
- Troubleshooting legacy systems
- Learning from past implementations

**Note**: Always refer to current documentation in `/docs/` for active development. Archive content should only be used for historical reference.