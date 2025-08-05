# Tools and Utilities

CLI tools, scripts, utilities, and applications for infrastructure management and development workflow.

## To Review

### Example Entry

- **URL**: <https://github.com/example/tool>
- **Type**: CLI tool / Script / Application
- **Use Case**: What it does and how it might help
- **Date Added**: YYYY-MM-DD
- **Status**: To Review
- **Notes**: Additional context or thoughts

---

<!-- Add new entries below this line -->

### Consul Template

- **URL**: <https://github.com/hashicorp/consul-template>
- **Type**: Configuration templating daemon
- **Use Case**: Automatically generate configuration files from Consul data and reload services when changes occur - perfect for dynamic service discovery, load balancer configs, or any config that needs to react to infrastructure changes
- **Date Added**: 2025-01-05
- **Status**: To Review
- **Notes**: Could eliminate manual config updates when services scale up/down. Integrates with our existing Consul deployment. Consider for Traefik dynamic routing, app configs, or even generating Ansible inventory from Consul service catalog. **See community.md - Netdata project uses this for their Consul integration!**

### hcdiag (HashiCorp Diagnostics)

- **URL**: <https://github.com/hashicorp/hcdiag>
- **Type**: CLI diagnostic tool
- **Use Case**: Collects and bundles diagnostics from HashiCorp products (Consul, Nomad, Vault, TFE) and platform info - essential for troubleshooting issues across our Consul/Nomad infrastructure
- **Date Added**: 2025-01-05
- **Status**: To Review
- **Notes**: Could streamline debugging when issues span multiple HashiCorp products. Useful for support tickets or complex troubleshooting. Since we run both Consul and Nomad, this could capture the full picture when things go wrong. Consider adding to our troubleshooting runbooks

## Reviewing

<!-- Move entries here when actively evaluating -->

## Implemented

<!-- Move entries here when integrated into the project -->

## Rejected

<!-- Move entries here with reason for rejection -->
