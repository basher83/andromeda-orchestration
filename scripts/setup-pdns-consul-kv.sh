#!/bin/bash
set -euo pipefail

# Setup PowerDNS Consul KV configuration
# This script configures the database connection parameters for PowerDNS

echo "🔧 Setting up PowerDNS Consul KV configuration..."

# Database connection parameters
CONSUL_KV_PREFIX="pdns"

# Set database connection parameters
echo "📝 Setting database connection parameters..."
consul kv put "${CONSUL_KV_PREFIX}/db/host" "postgres.service.consul"
consul kv put "${CONSUL_KV_PREFIX}/db/port" "5432"
consul kv put "${CONSUL_KV_PREFIX}/db/name" "powerdns"
consul kv put "${CONSUL_KV_PREFIX}/db/user" "pdns"

echo "✅ Consul KV configuration complete!"

# Verify the configuration
echo "🔍 Verifying configuration..."
echo "Database host: $(consul kv get ${CONSUL_KV_PREFIX}/db/host)"
echo "Database port: $(consul kv get ${CONSUL_KV_PREFIX}/db/port)"
echo "Database name: $(consul kv get ${CONSUL_KV_PREFIX}/db/name)"
echo "Database user: $(consul kv get ${CONSUL_KV_PREFIX}/db/user)"

echo "✨ PowerDNS Consul KV setup complete!"
