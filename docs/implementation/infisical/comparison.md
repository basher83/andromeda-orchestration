# Secrets Management Comparison: 1Password Connect vs Infisical

## Executive Summary

This document provides a comprehensive comparison between 1Password Connect (current implementation) and Infisical (proposed alternative) for secrets management in our Ansible automation project. Based on thorough research, Infisical emerges as the recommended solution due to its open-source nature, cost efficiency, and superior infrastructure-as-code integration capabilities.

**Update**: Infisical has recently added game-changing features including:
- **1Password Sync**: Seamless migration with bi-directional synchronization
- **MCP Server**: AI/LLM integration for Claude and other AI assistants
- **ACME/Let's Encrypt**: Automated SSL certificates with DNS-01 validation
- **Dynamic Secrets**: Auto-expiring credentials for databases and cloud providers
- **Packer Integration**: Native support for immutable infrastructure
- **Zabbix Monitoring**: Track secret usage and expiration

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Solution Comparison](#solution-comparison)
3. [Cost Analysis](#cost-analysis)
4. [Technical Evaluation](#technical-evaluation)
5. [Migration Strategy](#migration-strategy)
6. [Risk Assessment](#risk-assessment)
7. [Recommendation](#recommendation)

## Current State Analysis

### 1Password Connect Implementation

Our project currently uses 1Password Connect with the following configuration:

- **Custom Lookup Plugin**: `plugins/lookup/onepassword_connect.py`
- **Authentication**: Environment variables (OP_CONNECT_HOST, OP_CONNECT_TOKEN)
- **Integration Points**:
  - Proxmox dynamic inventory credentials
  - Consul ACL tokens
  - Nomad authentication
  - General secret retrieval in playbooks
- **Documentation**: Comprehensive guide in `docs/1password-integration.md`

### Current Challenges

1. **Cost**: Requires 1Password Teams/Business subscription plus Connect credits
2. **Complexity**: Custom lookup plugin maintenance
3. **Limited Features**: No native secret rotation or PKI management
4. **Authentication**: Token-based only, no OIDC or cloud-native auth

## Solution Comparison

### Feature Comparison Matrix

| Feature | 1Password Connect | Infisical |
|---------|------------------|-----------|
| **Pricing Model** | Subscription + Credits | Open Source (Free tier available) |
| **Self-Hosted** | ✅ Yes | ✅ Yes |
| **Cloud Free Tier** | ❌ No | ✅ Yes (5 users, 3 projects) |
| **Ansible Integration** | community.general + custom | Native collection |
| **Terraform Provider** | ❌ No | ✅ Yes (with ephemeral resources) |
| **Dynamic Secrets** | ❌ No | ✅ Yes (DB, Redis, etc.) |
| **Secret Rotation** | ❌ No | ✅ Automatic rotation |
| **PKI/SSH Management** | ❌ No | ✅ Yes |
| **ACME/Let's Encrypt** | ❌ No | ✅ Built-in integration |
| **Audit Logging** | ✅ Yes | ✅ Yes (90 days in Pro) |
| **OIDC Authentication** | ❌ No | ✅ Yes |
| **Machine Identities** | Limited | ✅ Native support |
| **Secret Scanning** | ❌ No | ✅ Built-in |
| **API Rate Limits** | Unlimited | Configurable |
| **Kubernetes Operator** | ✅ Yes | ✅ Yes |
| **Temporary Access** | ❌ No | ✅ Yes (time-limited) |
| **Access Requests** | ❌ No | ✅ Approval workflows |
| **Secret Referencing** | ❌ No | ✅ Cross-project refs |
| **1Password Sync** | N/A | ✅ Bi-directional sync |
| **MCP Server** | ❌ No | ✅ Yes (AI/LLM integration) |
| **Packer Integration** | ❌ No | ✅ Native support |
| **Zabbix Integration** | ❌ No | ✅ Yes |

### Authentication Methods

#### 1Password Connect
- API Token authentication only
- Environment variables for configuration
- No service account or OIDC support

#### Infisical (Recently Enhanced)
- Universal Auth (Client ID/Secret)
- OIDC (GitHub Actions, GitLab CI)
- Cloud-native (AWS IAM, GCP, Azure) - **NEW**
- Kubernetes native auth - **NEW**
- JWT authentication
- Service tokens (legacy)
- Dynamic identity provisioning

## Cost Analysis

### 1Password Connect

```
Base Requirements:
- 1Password Teams: $8/user/month (minimum 10 users = $80/month)
- OR 1Password Business: $8/user/month
- Connect Server: Self-hosted (infrastructure costs)
- Vault Access Credits: 3 free, then tiered pricing

Annual Minimum Cost: ~$960 + infrastructure
```

### Infisical

```
Self-Hosted Free Tier:
- Up to 5 identities
- Up to 3 projects
- Up to 3 environments
- Up to 10 integrations
- All core features included

Pro Tier (if needed):
- $18/month per identity
- Additional features: Secret rotation, SAML SSO, PKI/SSH

Annual Cost (Free Tier): $0 + infrastructure
Annual Cost (5 Pro identities): $1,080 + infrastructure
```

## Technical Evaluation

### Ansible Integration

#### 1Password Connect
```yaml
# Current implementation
- name: Retrieve secret
  set_fact:
    secret: "{{ lookup('onepassword_connect', 'Item Name', field='password') }}"

# Alternative with community.general
- name: Retrieve with community collection
  set_fact:
    secret: "{{ lookup('community.general.onepassword', 'Item Name', field='password') }}"
```

#### Infisical
```yaml
# Native collection usage
- name: Retrieve secret
  set_fact:
    secret: "{{ lookup('infisical.vault.read_secrets',
                secret_name='API_KEY',
                project_id='{{ project_id }}',
                environment='production',
                path='/backend') }}"

# Retrieve all secrets in path
- name: Get all secrets
  set_fact:
    secrets: "{{ lookup('infisical.vault.read_secrets',
                 project_id='{{ project_id }}',
                 environment='production',
                 path='/backend') }}"
```

### Terraform Integration

#### 1Password Connect
- No native Terraform provider
- Must use external data sources or scripts

#### Infisical
```hcl
# Terraform Provider Configuration
terraform {
  required_providers {
    infisical = {
      source  = "Infisical/infisical"
      version = "~> 0.11"
    }
  }
}

# Ephemeral Resources (Terraform 1.10+)
ephemeral "infisical_secrets" "app_secrets" {
  path         = "/app"
  environment  = "prod"
  project_id   = var.project_id
}

# Traditional Data Source
data "infisical_secret" "api_key" {
  name         = "API_KEY"
  environment  = "prod"
  project_id   = var.project_id
}
```

### Recent Infisical Enhancements (2024)

#### Dynamic Secrets
Infisical now supports dynamic secret generation for:
- **Databases**: PostgreSQL, MySQL, MongoDB, MS SQL, OracleDB
- **Cache Systems**: Redis, Elasticsearch
- **Cloud Providers**: AWS IAM, GCP Service Accounts
- **Use Case**: Temporary, auto-expiring credentials for each job/deployment

```yaml
# Example: Dynamic database credentials in Ansible
- name: Get dynamic PostgreSQL credentials
  set_fact:
    db_creds: "{{ lookup('infisical.vault.read_dynamic_secret',
                   type='postgresql',
                   path='/production/database',
                   ttl='1h') }}"
```

#### Advanced Access Controls
- **Temporary Access Provisioning**: Grant time-limited access to secrets
- **Access Requests**: Approval workflows for sensitive operations
- **Access Tree Visualization**: Visual representation of permissions
- **Grant Privileges**: Granular permission management

```yaml
# Example: Request temporary elevated access
- name: Request production access
  infisical.vault.request_access:
    path: "/production/infrastructure"
    reason: "Emergency patch deployment"
    duration: "30m"
```

#### Secret Rotation
Automatic rotation capabilities for:
- API keys and tokens
- Database passwords
- SSL certificates
- Custom credentials

#### Enhanced Terraform Integration
```hcl
# Project templates for consistent structure
resource "infisical_project" "standard" {
  template = "infrastructure-standard"
  name     = "new-service"
}

# Import existing secrets
resource "infisical_secret" "imported" {
  import_from = "vault://path/to/secret"
}
```

#### Game-Changing New Integrations

##### 1Password Sync
- **Bi-directional synchronization** with 1Password vaults
- **Zero-downtime migration** from 1Password to Infisical
- Keep using 1Password UI while leveraging Infisical's automation features

```yaml
# Example: Sync 1Password vault to Infisical project
- name: Configure 1Password sync
  infisical.sync.onepassword:
    vault_id: "{{ onepassword_vault_id }}"
    project_id: "{{ infisical_project_id }}"
    sync_direction: "bidirectional"
    sync_interval: "5m"
```

##### MCP (Model Context Protocol) Server
- **AI/LLM Integration**: Let AI assistants securely access secrets
- **Claude/ChatGPT Integration**: Safe secret handling in AI workflows
- **Use Case**: Automated infrastructure management with AI assistance

```bash
# Connect Claude to your Infisical secrets
export INFISICAL_MCP_URL="https://app.infisical.com/mcp"
export INFISICAL_MCP_TOKEN="your-machine-identity-token"
```

##### Packer Integration
- **Native Packer plugin** for image building
- Inject secrets during AMI/VM image creation
- Perfect for immutable infrastructure patterns

```hcl
# Packer configuration
source "amazon-ebs" "ubuntu" {
  # Secrets injected from Infisical
  access_key = data.infisical_secret.aws_access_key.value
  secret_key = data.infisical_secret.aws_secret_key.value
}
```

##### Zabbix Integration
- Monitor secret expiration and rotation
- Alert on access anomalies
- Track secret usage patterns

##### ACME Certificate Authority (Let's Encrypt) 🔥
- **Automated SSL/TLS certificates** from Let's Encrypt
- **DNS-01 challenge** support with Route53 integration
- **Automatic renewal** before expiration (90-day certs)
- **Perfect for your homelab services**!

```yaml
# Example: Automated certificates for services
- name: Create subscriber for web service
  infisical.pki.subscriber:
    ca_type: "acme"
    ca_name: "lets-encrypt-production"
    common_name: "{{ service_domain }}"
    alternative_names:
      - "*.{{ service_domain }}"
    auto_renew: true

# Certificate automatically issued and renewed!
```

**Use Cases for Your Infrastructure**:
- PowerDNS admin interface SSL
- Consul UI certificates
- Nomad UI certificates
- Proxmox custom certificates
- Any public-facing service

### Deployment Options

#### 1Password Connect
```yaml
# Docker Compose deployment
version: '3.8'
services:
  op-connect:
    image: 1password/connect-api:latest
    ports:
      - "8080:8080"
    volumes:
      - ./1password-credentials.json:/home/opuser/.op/1password-credentials.json
      - op-data:/home/opuser/.op/data
    environment:
      OP_LOG_LEVEL: info
```

#### Infisical
```yaml
# Docker Compose deployment
version: '3.8'
services:
  infisical:
    image: infisical/infisical:latest
    ports:
      - "8080:80"
    environment:
      ENCRYPTION_KEY: ${ENCRYPTION_KEY}
      AUTH_SECRET: ${AUTH_SECRET}
      DB_CONNECTION_URI: postgresql://user:pass@postgres:5432/infisical
      REDIS_URL: redis://redis:6379
      SITE_URL: http://localhost:8080
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: infisical
      POSTGRES_USER: infisical
      POSTGRES_PASSWORD: infisical
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
```

## Migration Strategy

### Phase 1: Parallel Implementation (Week 1-2)

1. **Configure Infisical Cloud**
   - Sign up for Infisical Cloud free tier
   - Create organization and initial project structure
   - Set up machine identities for Ansible
   - Configure authentication methods

2. **Enable 1Password Sync** ⭐ **NEW - Zero Migration Effort!**
   ```yaml
   # Set up bi-directional sync
   - name: Configure 1Password sync
     tasks:
       - Enable Infisical 1Password integration
       - Map 1Password vaults to Infisical projects
       - Set sync interval (recommended: 5 minutes)
       - Verify sync is working
   ```

3. **Test Dual Access**
   - Access same secrets via 1Password (existing)
   - Access same secrets via Infisical (new)
   - Verify consistency between both systems

### Phase 2: Feature Parity (Week 3-4)

1. **Implement Advanced Features**
   - Set up secret rotation for database passwords
   - Configure audit logging
   - Implement RBAC policies
   - Set up backup procedures

2. **Update Automation Scripts** ✅ **COMPLETED**
   - ~~Replace `bin/ansible-connect` usage with `uv run` commands~~ ✅
   - Updated environment setup for Infisical
   - Migration to Infisical inventory files complete

3. **Documentation Updates**
   - Create Infisical integration guide
   - Update troubleshooting documentation
   - Document new patterns and best practices

### Phase 3: Production Migration (Week 5-6)

1. **Staged Rollout**
   - Migrate by environment (Dev → Staging → Prod)
   - Maintain dual-read capability
   - Monitor access patterns

2. **Cutover Process**
   - Update all playbook references
   - Switch CI/CD pipelines
   - Decommission 1Password Connect

3. **Post-Migration**
   - Archive 1Password documentation
   - Remove custom lookup plugins
   - Optimize Infisical configuration

## Risk Assessment

### Migration Risks

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Service Disruption | High | Low | Parallel run, staged rollout |
| Data Loss | High | Low | Backup exports, version control |
| Authentication Issues | Medium | Medium | Test all auth methods thoroughly |
| Learning Curve | Low | High | Training, documentation, examples |
| Integration Bugs | Medium | Medium | Extensive testing, rollback plan |

### Rollback Strategy

1. **Maintain Dual Configuration**
   - Keep 1Password Connect running
   - Use feature flags for secret source
   - Quick switch capability

2. **Backup Procedures**
   - Export all secrets before migration
   - Version control secret structure
   - Document all configurations

## Recommendation

### Why Choose Infisical

1. **Cost Efficiency**
   - Significant savings ($960+/year → $0/year for current scale)
   - No per-user licensing
   - Generous free tier (cloud or self-hosted)

2. **Technical Superiority**
   - Native Terraform provider with ephemeral resources
   - **NEW**: Dynamic secrets for databases and cloud providers
   - **NEW**: Automatic secret rotation
   - Modern authentication methods (OIDC, cloud-native)
   - Active open-source development (rapid feature additions)

3. **Future-Proofing**
   - Aligns with infrastructure-as-code practices
   - Native Kubernetes integration
   - SSH certificate management for future needs
   - **NEW**: Access request workflows for compliance
   - Extensible architecture

4. **Operational Benefits**
   - Integrated secret scanning (already using Infisical CLI)
   - Single platform for secrets and scanning
   - **NEW**: Temporary access provisioning
   - Better audit and compliance features
   - Community support and transparency

### Cloud vs Self-Hosted Decision

For this project, **Infisical Cloud free tier is recommended** because:

1. **Sufficient Limits**: 5 users and 3 projects covers homelab needs
2. **Zero Maintenance**: No infrastructure to manage
3. **Immediate Access**: All new features available instantly
4. **Same Features**: Cloud free tier includes all core functionality

Consider self-hosting only if you:
- Need more than 3 projects or 5 identities
- Require complete network isolation
- Have strict data residency requirements

### Implementation Timeline

- **Week 1-2**: Environment setup and initial testing
- **Week 3-4**: Feature implementation and documentation
- **Week 5-6**: Production migration
- **Week 7-8**: Optimization and cleanup

### Success Criteria

1. All secrets successfully migrated
2. No service disruptions during migration
3. Improved secret rotation capabilities implemented
4. Team trained on new system
5. Documentation complete and accurate
6. Cost savings realized

## Next Steps

1. **Approval**: Review and approve migration plan
2. **Environment Setup**: Provision Infisical infrastructure
3. **Proof of Concept**: Implement with single playbook
4. **Team Training**: Knowledge transfer sessions
5. **Execute Migration**: Follow phased approach

## Appendix

### Useful Resources

- [Infisical Documentation](https://infisical.com/docs)
- [Infisical Ansible Collection](https://galaxy.ansible.com/ui/repo/published/infisical/vault/)
- [Infisical Terraform Provider](https://registry.terraform.io/providers/Infisical/infisical/latest)
- [Migration Tools Repository](https://github.com/Infisical/infisical-migration)

### Sample Configurations

Available in `examples/infisical/` directory (to be created):
- Docker Compose setup
- Ansible playbook examples
- Terraform configuration
- Migration scripts
