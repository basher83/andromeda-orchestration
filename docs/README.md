# NetBox-Ansible Documentation Index

This directory contains comprehensive documentation for the NetBox-focused Ansible automation project. Documentation is organized by category to help you quickly find the information you need.

## Architecture Diagrams

Visual representations of project architecture and workflows:

- [**High-Level Architecture Overview**](diagrams/architecture-overview.md) - System components and relationships
- [**DNS/IPAM Migration Flow**](diagrams/dns-ipam-migration-flow.md) - Phased migration approach with rollback procedures
- [**Secrets Management Flow**](diagrams/secrets-management-flow.md) - Infisical authentication and secret retrieval patterns

## Getting Started

### Core Documentation

- [**Project Task List**](project-task-list.md) - Complete task tracking and project management for all DNS/IPAM implementation phases
- [**Repository Structure**](repository-structure.md) - Overview of project organization and directory layout
- [**UV Ansible Notes**](uv-ansible-notes.md) - Guide for using UV package manager with Ansible

### Secret Management

- [**Infisical Setup and Migration**](infisical-setup-and-migration.md) - Complete guide for using Infisical secrets management, including migration from 1Password
- [**Secrets Management Comparison**](secrets-management-comparison.md) - Detailed comparison of 1Password vs Infisical for this project

## Implementation Guides

### DNS & IPAM Infrastructure

- [**DNS & IPAM Implementation Plan**](dns-ipam-implementation-plan.md) - Master roadmap for transitioning from ad-hoc DNS to service-aware infrastructure using Consul, PowerDNS, and NetBox
- [**NetBox Integration Patterns**](netbox.md) - Comprehensive guide for NetBox automation with Ansible, including dynamic inventory, state management, and API integration

### Development Setup

- [**Pre-commit Setup**](pre-commit-setup.md) - Configuration guide for pre-commit hooks and code quality tools
- [**Testing Strategy**](testing-strategy.md) - Framework for testing Ansible playbooks and infrastructure changes

### Infrastructure Configuration

- [**Consul Telemetry Setup**](consul-telemetry-setup.md) - Guide for enabling Consul metrics collection with Netdata
- [**Imported Infrastructure**](imported-infrastructure.md) - Documentation of Ansible roles and modules imported from terraform-homelab
- [**Phase 1 Implementation Guide**](phase1-implementation-guide.md) - Step-by-step guide for DNS infrastructure Phase 1

## Operations

### Troubleshooting

- [**Troubleshooting Guide**](troubleshooting.md) - Common issues and solutions, including macOS Sequoia permissions, network connectivity, and Python environment
- [**Assessment Playbook Fixes**](assessment-playbook-fixes.md) - Solutions for issues with infrastructure assessment playbooks

## AI Documentation

The `ai-docs/` subdirectory contains documentation specific to AI agent integration:

- [**Sub-agents**](ai-docs/sub-agents.md) - Specialized Claude AI agent configurations

## Archived Documentation

The `archive/` subdirectory contains deprecated documentation preserved for reference:

- Historical 1Password integration guides
- Legacy setup procedures
- Previous documentation reviews

See [archive/README.md](archive/README.md) for the complete archive index.

## Documentation Standards

All documentation in this project follows these standards:

- CommonMark specification compliance
- Consistent heading hierarchy (single H1 per document)
- Fenced code blocks with language specifications
- Descriptive link text (no bare URLs)
- Active voice and present tense
- Practical examples and use cases

## Quick Links

### Current Project Focus

- [DNS & IPAM Implementation Plan](dns-ipam-implementation-plan.md#current-state) - Current infrastructure state
- [Project Task List](project-task-list.md#high-priority---immediate-action-required) - Immediate action items
- [Infisical Migration](infisical-setup-and-migration.md#current-state) - Secret management transition status

### Essential References

- [NetBox Dynamic Inventory](netbox.md#dynamic-inventory-configuration) - NetBox inventory setup
- [Troubleshooting Network Issues](troubleshooting.md#network-connectivity) - Common connectivity problems
- [Testing Playbooks](testing-strategy.md) - How to test changes safely

## Contributing to Documentation

When updating documentation:

1. Follow the markdown standards listed above
2. Run linting: `uv run markdownlint docs/**/*.md`
3. Update this index if adding new documents
4. Add "Related Documentation" sections for cross-references
5. Keep examples practical and tested

## Documentation Maintenance

- **Review Schedule**: Weekly during active implementation
- **Update Triggers**: After task completion, new findings, or process changes
- **Quality Checks**: Markdown linting, link validation, example testing