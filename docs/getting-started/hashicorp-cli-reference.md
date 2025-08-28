# HashiCorp CLI Quick Reference

Quick status and health check commands for Consul, Nomad, and Vault.

## Pre-requisites

First, authenticate using the commands from `vault-consul-auth.md`.

## Consul Commands

### Health & Status

```bash
# Cluster members and health
consul members
consul members -detailed

# Check leader
consul operator raft list-peers

# Service catalog
consul catalog services
consul catalog nodes

# Check ACL status
consul acl auth-method list
consul acl token read -self

# Cluster info
consul info
consul operator autopilot state

# Check specific service health
consul catalog nodes -service=<service-name>
```

## Nomad Commands

### Health & Status

```bash
# Server members
nomad server members
nomad server members -detailed

# Client nodes status
nomad node status
nomad node status -allocs  # Show allocations

# Job status
nomad job status
nomad status              # All jobs

# Check leader
nomad operator raft list-peers

# Cluster info
nomad operator autopilot get-config

# Resource usage
nomad node status -self -verbose  # If on a node
nomad node pool list
```

## Vault Commands

### Health & Status

```bash
# Seal status
vault status

# Check leader (if using HA)
vault operator raft list-peers

# Auth methods
vault auth list

# Secrets engines
vault secrets list

# Policies
vault policy list

# Token info
vault token lookup  # Current token
vault token lookup -self

# Audit devices
vault audit list

# Health check endpoints (no auth needed)
curl -k https://$VAULT_ADDR/v1/sys/health
```

## Combined Health Checks

### Quick cluster health

```bash
# One-liner health check
echo "=== Consul ===" && consul members | grep -c alive && \
echo "=== Nomad ===" && nomad node status | grep -c ready && \
echo "=== Vault ===" && vault status | grep "Sealed" | awk '{print $2}'
```

### Service discovery check

```bash
# Find services via Consul
consul catalog services

# DNS lookup via Consul
dig @127.0.0.1 -p 8600 <service>.service.consul
```

### Quick troubleshooting

```bash
# Check logs (if you have access to the nodes)
consul monitor -log-level=debug
nomad monitor -log-level=debug

# Version check
consul version
nomad version
vault version

# License status (Enterprise)
consul license get
nomad license get
vault license inspect
```

## Useful Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
# Quick status checks
alias cs='consul members'
alias ns='nomad node status'
alias vs='vault status'

# Leaders
alias cl='consul operator raft list-peers'
alias nl='nomad operator raft list-peers'
alias vl='vault operator raft list-peers'

# Services
alias services='consul catalog services'
alias jobs='nomad job status'
```
