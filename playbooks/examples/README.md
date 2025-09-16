# Ansible Playbook Examples

This directory contains example playbooks demonstrating various Ansible automation patterns and troubleshooting techniques used in the Andromeda orchestration project.

## Available Examples

### 🔧 Troubleshooting & Diagnostics

- **`simple-connectivity-test.yml`** - Basic connectivity testing between hosts
- **`robust-connectivity-test.yml`** - Comprehensive connectivity and service health checks
- **`quick-status.yml`** - Fast status overview of infrastructure components

### 🔐 Security & Secrets Management

- **`infisical-demo.yml`** - Demonstrates Infisical integration for secrets management
- **`infisical-test.yml`** - Testing patterns for Infisical lookup plugins

### 🔗 Service Integration

- **`netdata-consul-template.yml`** - Netdata monitoring with Consul template integration
- **`test-nomad-consul-acl-integration.yml`** - ACL integration testing between Nomad and Consul

## Usage

These playbooks serve as:

- **Reference implementations** for common automation patterns
- **Troubleshooting examples** for infrastructure issues
- **Learning resources** for Ansible best practices
- **Starting points** for custom automation development

Most examples include comprehensive documentation and can be run with:

```bash
uv run ansible-playbook playbooks/examples/<playbook-name>.yml
```

## Service Endpoints

Service endpoints are centrally defined in `inventory/environments/all/service-endpoints.yml` to avoid hardcoded IPs throughout the codebase. Examples use these centralized definitions:

- **Consul**: `{{ service_endpoints.consul.addr }}`
- **Nomad**: `{{ service_endpoints.nomad.addr }}`
- **Vault**: `{{ service_endpoints.vault.addr }}`

These can be overridden via environment variables:

- `CONSUL_HTTP_ADDR`
- `NOMAD_ADDR`
- `VAULT_ADDR`

## Contributing

When adding new examples:

- Include clear documentation in playbook comments
- Add appropriate tags for selective execution
- Follow the project's Ansible coding standards
- Update this README with a brief description
