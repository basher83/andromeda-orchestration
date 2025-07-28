# Architecture Diagrams

This directory contains Mermaid-based architecture and flow diagrams for the NetBox-Ansible project.

## Available Diagrams

1. **[Architecture Overview](architecture-overview.md)**
   - High-level view of all system components
   - Shows relationships between NetBox, Ansible, Infisical, and infrastructure
   - Illustrates both current and target states

2. **[DNS/IPAM Migration Flow](dns-ipam-migration-flow.md)**
   - Detailed flowchart of the 5-phase migration plan
   - Includes decision points and rollback procedures
   - Maps directly to the implementation plan phases

3. **[Secrets Management Flow](secrets-management-flow.md)**
   - Sequence diagram showing authentication flow
   - Details how secrets move from Infisical to target infrastructure
   - Includes error handling scenarios

## Viewing Diagrams

These diagrams use Mermaid syntax and can be viewed in:
- GitHub (renders automatically in markdown files)
- VS Code with Mermaid preview extensions
- Any Mermaid-compatible markdown viewer
- Online at [mermaid.live](https://mermaid.live) for editing

## Updating Diagrams

When updating diagrams:
1. Keep diagrams focused on high-level concepts
2. Use consistent styling (see color schemes in existing diagrams)
3. Update related documentation if architecture changes
4. Test rendering in GitHub before committing

## Diagram Standards

- Use clear, descriptive labels
- Include legends for complex diagrams
- Keep text concise but meaningful
- Use consistent node shapes for similar components
- Apply color coding to distinguish component types