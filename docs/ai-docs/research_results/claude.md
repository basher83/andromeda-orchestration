# Synthesized Recommendations: Deploying HashiCorp Vault via Ansible to Nomad

## Best Example Repository

**Winner: Deltamir/ansible-hashistack**

### Justification

- Most comprehensive and production-ready implementation found
- Automated configuration of interoperability between Consul, Vault, and Nomad
- Production features include:
  - Automatic PKI management with full mTLS
  - Auto-unseal capabilities using Transit Secret Engine
  - Automatic certificate rotation
  - Cross-ACL management (Vault manages Consul and Nomad ACLs)
- Only requires 6 mandatory variables for basic deployment
- Actively maintained with clear documentation

## Deployment Strategy

### Step-by-Step Approach Based on Research

1. **Infrastructure Preparation**

   - Set up minimum 3 nodes for HA (can be VMs or physical servers)
   - Ensure network connectivity between all nodes
   - Configure DNS or use Consul for service discovery

2. **Deploy Consul First** (Foundation Layer)

   ```yaml
   - Install Consul using ansible-consul role
   - Configure as HA cluster with encryption
   - Enable ACLs and generate bootstrap token
   - Verify cluster health before proceeding
   ```

3. **Deploy Vault Using Consul Backend**

   ```yaml
   - Install Vault using ansible-vault role
   - Configure Consul as storage backend
   - Initialize Vault and save unseal keys securely
   - Configure auto-unseal (highly recommended for production)
   - Set up PKI for certificate management
   ```

4. **Deploy Nomad with Vault Integration**

   ```yaml
   - Install Nomad using ansible-nomad role
   - Configure vault block in Nomad configuration
   - Set up JWT authentication backend in Vault
   - Create appropriate Vault policies for Nomad
   - Test workload identity integration
   ```

5. **Post-Deployment Configuration**
   - Run `nomad setup vault` to automate Vault configuration
   - Configure monitoring and alerting
   - Set up backup procedures
   - Document operational procedures

## Tool Combination Insights

### Most Effective Tool Combinations

1. **DeepWiki + GitHub/Grep**

   - DeepWiki provided architectural understanding from official docs
   - GitHub/Grep found real-world implementations
   - Together they bridged theory and practice

2. **Docker-MCP (Perplexity) + All Others**

   - Perplexity research synthesized findings from all sources
   - Provided comprehensive analysis with citations
   - Filled gaps and provided production insights

3. **Sequential Discovery Pattern**
   - Official docs (DeepWiki) → Real examples (GitHub) → Synthesis (Perplexity)
   - Each tool built upon previous findings
   - Created complete understanding from multiple perspectives

## Platform-Specific Observations

### Claude Code Platform Strengths

1. **Multi-Tool Orchestration**

   - Seamless switching between different MCP servers
   - Maintained context across all tool usage
   - Effective synthesis of diverse information sources

2. **Research Methodology**

   - Systematic approach with todo list tracking
   - Clear progression through research phases
   - Comprehensive documentation of findings

3. **Synthesis Capabilities**
   - Excellent at combining technical details from multiple sources
   - Created actionable recommendations from research
   - Provided both high-level strategy and specific implementation details

### Challenges Encountered

1. **Tool Learning Curve**

   - GitHub/Grep required understanding of literal pattern matching
   - Some repositories weren't indexed in DeepWiki
   - Docker Hub documentation wasn't directly accessible

2. **Information Gaps**
   - Limited examples of Vault running AS a Nomad job (not recommended)
   - Few examples of complete end-to-end Ansible automation
   - Security considerations sometimes glossed over in examples

## Final Recommendations

### For Production Deployment

1. **Use Deltamir/ansible-hashistack** as your starting point
2. **Implement auto-unseal** - manual unsealing doesn't scale
3. **Plan your PKI strategy** - certificate management is critical
4. **Test disaster recovery** - practice cluster rebuilding
5. **Monitor everything** - especially unsealing status and certificate expiry

### For Development/Learning

1. Start with **brightzheng100/hashistack-by-ansible-footloose**
2. Use **livioribeiro/nomad-lxd-ansible** for isolated testing
3. Study the official HashiCorp examples in **nomad-guides**
4. Experiment with different unsealing methods
5. Practice the complete deployment sequence multiple times

### Key Insight

While it's technically possible to run Vault as a Nomad job, the research clearly shows this is not the recommended approach. Vault should be deployed as a separate service that Nomad workloads can integrate with for secrets management. The complexity of Vault's unsealing requirements and stateful nature make it better suited as a foundational service rather than a scheduled workload.
