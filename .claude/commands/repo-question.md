---
allowed-tools: Bash(git ls-files:*), Read
description: Answer questions about the project structure and documentation without coding
argument-hint: [Repo question]
---

# Question

Answer the user's question by analyzing the project structure and documentation. This prompt is designed to provide information and answer questions without making any code changes.

## Instructions

- **IMPORTANT: This is a question-answering task only - DO NOT write, edit, or create any files**
- **IMPORTANT: Focus on understanding and explaining existing code and project structure**
- **IMPORTANT: Provide clear, informative answers based on project analysis**
- **IMPORTANT: If the question requires code changes, explain what would need to be done conceptually without implementing**

## Execute

- `git ls-files` to understand the project structure

## Tool Integration Strategy

- **Initial Analysis**: Always start with `git ls-files` and cross-reference against @docs/README.md Directory Structure
- **Targeted Reading**: Use question classification to determine which specific @docs/ directories to read first
- **Verification**: Cross-reference findings against @docs/README.md as source of truth before responding

## Read

- @README.md for project overview
- @docs/README.md as source of truth for documentation structure and navigation
- @docs/standards/ for repository standards and best practices
- @docs/getting-started/ for setup and development guidance

## Analysis Approach

1. **Documentation Mapping**: Cross-reference question against @docs/README.md directory structure as source of truth
2. **Context-Aware Reading**: Selectively read relevant documentation based on question type:
   - Infrastructure deployment → implementation/ directory (PowerDNS, Consul, Nomad, Vault)
   - Architecture decisions → project-management/decisions/ directory (ADR files)
   - Troubleshooting → troubleshooting/ directory
   - Development setup → getting-started/ directory
   - Operational procedures → operations/ directory
   - Standards & best practices → standards/ directory
3. **ADR Integration**: Check project-management/decisions/ for relevant architectural decisions (ADR-\*.md files)
4. **Troubleshooting Priority**: Reference troubleshooting/ for known issues and solutions
5. **Quick Start Guidance**: Use getting-started/ section and @docs/README.md Quick Start Path

## Question Classification & Documentation Routing

**Infrastructure/Deployment Questions:**

- Primary: implementation/ (dns-ipam/, powerdns/, consul/, nomad/, vault/)
- Secondary: project-management/decisions/ for architectural context
- Check: operations/ for deployment procedures and troubleshooting/

**Development/Setup Questions:**

- Primary: getting-started/ (repository-structure.md, mise-setup-guide.md, pre-commit-setup.md)
- Secondary: standards/ for development workflow and linting standards
- Reference: @docs/README.md Quick Start section

**Architecture/Design Questions:**

- Primary: project-management/decisions/ (ADR-\*.md files for architectural decisions)
- Secondary: diagrams/ for visual architecture representations
- Reference: standards/infrastructure-standards.md for design principles

**Operations/Maintenance Questions:**

- Primary: operations/ (netdata-architecture.md, deployment procedures, monitoring)
- Secondary: troubleshooting/ for operational issues
- Check: implementation/ for service-specific operational details

**Troubleshooting/Debugging:**

- Primary: troubleshooting/ (dns-resolution-loops.md, service-identity-issues.md, etc.)
- Secondary: operations/smoke-testing-procedures.md for validation steps
- Check: getting-started/troubleshooting.md for setup-related issues

## Documentation Quality Assurance

- **Verify Completeness**: Cross-check findings against @docs/README.md Directory Structure as source of truth
- **ADR Validation**: Ensure recommendations align with project-management/decisions/ ADR files
- **Process Alignment**: Confirm suggestions match standards/ and getting-started/ documented processes
- **Troubleshooting Coverage**: Reference known issues from troubleshooting/ directory

## When Documentation is Incomplete

- Flag gaps in documentation coverage and suggest updates to relevant @docs/ sections
- Reference most closely related existing documentation from actual directory structure
- Note when architectural decisions may need to be documented in project-management/decisions/
- Suggest following standards/documentation-standards.md for any new documentation

## Response Structure

1. **Direct Answer** (2-3 sentences based on @docs/ analysis)
2. **Supporting Evidence** (cite specific files from actual repository structure)
3. **Documentation References** (with relative paths from @docs/ directory)
4. **Next Steps/Actions** (reference @docs/README.md Quick Start Path if applicable)

## Question

$ARGUMENTS
