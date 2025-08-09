# PowerDNS Implementation Documentation

This directory contains implementation documentation for PowerDNS deployment and integration within the infrastructure.

## Documents

### [deployment-architecture.md](deployment-architecture.md)

**Deployment Architecture Decision** - Documents the evaluation and selection of PowerDNS deployment patterns (Mode A vs Mode B), implementation guide, and migration strategies.

Key topics:

- Architecture comparison (Simple vs Full Stack)
- Why Mode A was chosen
- Implementation prerequisites and steps
- Configuration details
- Migration path to Mode B

## Quick Start

For deploying PowerDNS in production:

1. Review the [deployment architecture](deployment-architecture.md) to understand the chosen pattern
2. Follow the implementation guide for prerequisites
3. Deploy using the Mode A configuration from `nomad-jobs/platform-services/.testing/mode-a/`

## Related Documentation

- [DNS & IPAM Implementation Plan](../dns-ipam/implementation-plan.md)
- [PowerDNS NetBox Integration](../dns-ipam/powerdns-netbox-integration.md)
- [Nomad Storage Strategy](../nomad/storage-strategy.md)

## Job Files

The actual Nomad job specifications are located at:

- **Mode A (Chosen)**: `nomad-jobs/platform-services/.testing/mode-a/powerdns-testing.nomad.hcl`
- **Mode B (Alternative)**: `nomad-jobs/platform-services/.testing/mode-b/`
- **PostgreSQL Backend**: `nomad-jobs/platform-services/.testing/postgresql/postgresql.nomad.hcl`
