#!/bin/bash
# Generate Consul Auto-Encrypt Certificates from Vault PKI

set -euo pipefail

# Set Vault connection details
export VAULT_ADDR="${VAULT_ADDR:-http://192.168.10.31:8200}"

# Get token from Infisical
echo "📦 Retrieving Vault token from Infisical..."
VAULT_TOKEN=$(infisical secrets get VAULT_PROD_ROOT_TOKEN --path="/apollo-13/vault" --env="prod" --plain)
export VAULT_TOKEN

if [ -z "$VAULT_TOKEN" ]; then
    echo "❌ Failed to retrieve Vault token from Infisical"
    exit 1
fi

echo "✅ Vault token retrieved successfully"

# Create certificate directory
CERT_DIR="/tmp/consul-certs"
mkdir -p "$CERT_DIR"

# Get CA certificate
echo "📜 Fetching CA certificate..."
vault read -field=certificate pki_int/cert/ca > "$CERT_DIR/ca.crt"
echo "   - CA certificate saved to $CERT_DIR/ca.crt"

# Generate server certificate for Consul servers
echo "🔐 Generating server certificate..."
vault write -format=json pki_int/issue/consul-agent \
    common_name="server.dc1.consul" \
    alt_names="consul.service.consul,consul.spaceships.work,server.dc1.consul" \
    ip_sans="127.0.0.1,192.168.10.11,192.168.10.12,192.168.10.13" \
    ttl="720h" > "$CERT_DIR/server.json"

# Extract certificate and key
jq -r '.data.certificate' "$CERT_DIR/server.json" > "$CERT_DIR/server.crt"
jq -r '.data.private_key' "$CERT_DIR/server.json" > "$CERT_DIR/server.key"
jq -r '.data.issuing_ca' "$CERT_DIR/server.json" > "$CERT_DIR/issuing_ca.crt"
echo "   - Server certificate saved to $CERT_DIR/server.crt"
echo "   - Server private key saved to $CERT_DIR/server.key"

# Generate client certificate for Consul clients
echo "🔐 Generating client certificate..."
vault write -format=json pki_int/issue/consul-agent \
    common_name="client.dc1.consul" \
    alt_names="consul.service.consul" \
    ip_sans="127.0.0.1" \
    ttl="720h" > "$CERT_DIR/client.json"

# Extract certificate and key
jq -r '.data.certificate' "$CERT_DIR/client.json" > "$CERT_DIR/client.crt"
jq -r '.data.private_key' "$CERT_DIR/client.json" > "$CERT_DIR/client.key"
echo "   - Client certificate saved to $CERT_DIR/client.crt"
echo "   - Client private key saved to $CERT_DIR/client.key"

# Set proper permissions
chmod 644 "$CERT_DIR"/*.crt
chmod 600 "$CERT_DIR"/*.key
chmod 600 "$CERT_DIR"/*.json

echo ""
echo "✅ Consul Auto-Encrypt certificates generated successfully!"
echo ""
echo "📁 Certificates saved in $CERT_DIR:"
echo "   - ca.crt           : CA certificate for all nodes"
echo "   - server.crt       : Server certificate for Consul servers"
echo "   - server.key       : Server private key"
echo "   - client.crt       : Client certificate for Consul clients"
echo "   - client.key       : Client private key"
echo "   - issuing_ca.crt   : Intermediate CA certificate"
echo ""
echo "🚀 Next Steps:"
echo "   1. Deploy these certificates to Consul nodes"
echo "   2. Configure Consul for TLS and auto-encrypt"
echo "   3. Restart Consul services"
echo ""
echo "📋 Certificates valid for:"
echo "   - Server cert: All 3 Consul servers (192.168.10.11-13)"
echo "   - Client cert: All Consul clients and Vault nodes"
