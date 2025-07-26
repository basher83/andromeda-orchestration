# Claude Agents Directory

This directory contains specialized agent configurations for the NetBox-Ansible project. Each agent is designed to handle specific aspects of the infrastructure automation and documentation workflow.

## Available Agents

### Infrastructure Agents

1. **ansible-playbook-developer**
   - Ansible playbook development specialist
   - Creates, tests, and refines playbooks
   - Focus on NetBox integration, DNS/IPAM configuration, and infrastructure provisioning

2. **netbox-integration-engineer**
   - NetBox integration specialist
   - Implements dynamic inventory, state management, and bi-directional synchronization
   - Expert in NetBox modules and source-of-truth patterns

3. **consul-service-mesh-engineer**
   - Consul service mesh and DNS configuration specialist
   - Phase 1 Consul foundation work including DNS setup, service registration, health checks
   - ACLs, encryption, and Consul-Nomad integration

4. **powerdns-deployment-specialist**
   - PowerDNS deployment and configuration expert
   - Phase 2 of DNS/IPAM migration
   - Handles PowerDNS deployment into Nomad, MariaDB backends, API access

5. **nomad-job-developer**
   - Nomad job specification developer
   - Specializes in containerized service deployments and job lifecycle management
   - Infrastructure orchestration for PowerDNS, monitoring services

### Security & Secrets Management

6. **infisical-secrets-architect**
   - Infisical secrets management architect
   - Advanced features including dynamic secrets, secret rotation, ACME certificates
   - Infrastructure-as-code patterns for secrets management

### Analysis & Assessment

7. **codebase-context-analyzer**
   - Quick codebase structure and pattern analysis
   - Identifies project architecture, dependencies, and coding conventions
   - Provides actionable insights for navigation and contribution

8. **infrastructure-assessment-analyst**
   - Infrastructure assessment and audit specialist
   - Pre-implementation state gathering and risk identification
   - Essential for DNS/IPAM migration phases

9. **iac-platform-architect**
   - Infrastructure as Code review specialist
   - Expert review of Ansible, Terraform, Consul, or Nomad code
   - Identifies anti-patterns, security vulnerabilities, and suggests improvements

### Project Coordination

10. **dns-migration-coordinator**
    - DNS migration coordination specialist
    - Manages transition from Pi-hole to PowerDNS
    - Plans migration sequences, rollback procedures, and zero-downtime transitions

### Development Support

11. **git-commit-organizer**
    - Organizes and commits code changes to git
    - Creates clean, logical commits from workspace changes
    - Analyzes uncommitted changes and groups them appropriately

12. **docs-agent**
    - Documentation specialist for technical documentation
    - Ensures markdown linting compliance and best practices
    - Creates, updates, and maintains all project documentation

## Usage

To use a specific agent, invoke it with the Task tool:

```yaml
Task(
  description="Short task description",
  prompt="Detailed instructions for the agent",
  subagent_type="agent-name"
)
```

## Agent Selection Guidelines

- **Starting a new playbook**: Use `ansible-playbook-developer`
- **Implementing NetBox integration**: Use `netbox-integration-engineer`
- **DNS/IPAM migration tasks**: Use `dns-migration-coordinator` for planning, specific specialists for implementation
- **Code review**: Use `iac-platform-architect` after implementing infrastructure code
- **Documentation**: Always use `docs-agent` for any documentation tasks
- **Understanding existing code**: Use `codebase-context-analyzer`
- **Pre-implementation assessment**: Use `infrastructure-assessment-analyst`

## Best Practices

1. Use agents proactively when their description matches your task
2. Combine multiple agents for complex workflows
3. Always use the docs-agent for documentation to ensure consistency
4. Run assessments before implementations
5. Use the git-commit-organizer after completing coding tasks

## Adding New Agents

When creating new agents:
1. Follow the existing template structure
2. Clearly define the agent's specific expertise
3. List required tools
4. Provide usage examples
5. Update this README with the new agent