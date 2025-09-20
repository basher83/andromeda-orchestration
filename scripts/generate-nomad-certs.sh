#!/usr/bin/env bash
# Generate Nomad TLS certificates from Vault PKI
# Task: PKI-003 - Configure Nomad TLS for Cluster Communication
# Parent Issue: 98 - mTLS for Service Communication

set -euo pipefail

# Configuration
VAULT_ADDR="${VAULT_ADDR:-http://192.168.10.31:8200}"
CERT_DIR="/tmp/nomad-certs"
PKI_PATH="pki_int"
ROLE_NAME="nomad-agent"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if vault is available
if ! command -v vault &> /dev/null; then
    print_error "vault command not found. Please install vault CLI."
    exit 1
fi

# Check if VAULT_TOKEN is set
if [ -z "${VAULT_TOKEN:-}" ]; then
    print_warning "VAULT_TOKEN not set. Attempting to get from Infisical..."
    if command -v infisical &> /dev/null; then
        VAULT_TOKEN=$(infisical secrets get VAULT_PROD_ROOT_TOKEN --path="/apollo-13/vault" --env="prod" --plain)
        export VAULT_TOKEN
        if [ -z "$VAULT_TOKEN" ]; then
            print_error "Failed to retrieve VAULT_TOKEN from Infisical"
            exit 1
        fi
        print_status "Successfully retrieved VAULT_TOKEN from Infisical"
    else
        print_error "VAULT_TOKEN not set and infisical not available"
        exit 1
    fi
fi

# Create certificate directory
print_status "Creating certificate directory: $CERT_DIR"
mkdir -p "$CERT_DIR"

# Export Vault address
export VAULT_ADDR

print_status "Using Vault at: $VAULT_ADDR"

# Generate CA certificate
print_status "Fetching CA certificate from Vault..."
curl -s -H "X-Vault-Token: $VAULT_TOKEN" "$VAULT_ADDR/v1/${PKI_PATH}/ca/pem" -o "$CERT_DIR/ca.crt"
if [ $? -eq 0 ] && [ -s "$CERT_DIR/ca.crt" ]; then
    print_status "CA certificate saved to $CERT_DIR/ca.crt"
else
    print_error "Failed to fetch CA certificate"
    exit 1
fi

# Generate server certificate for Nomad servers
print_status "Generating Nomad server certificate..."
vault write -format=json "${PKI_PATH}/issue/${ROLE_NAME}" \
    common_name="server.global.nomad" \
    alt_names="nomad.service.consul,nomad.spaceships.work" \
    ip_sans="127.0.0.1,192.168.10.11,192.168.10.12,192.168.10.13" \
    ttl="720h" > "$CERT_DIR/server.json"

if [ $? -eq 0 ]; then
    # Extract certificate and key from JSON response
    cat "$CERT_DIR/server.json" | jq -r '.data.certificate' > "$CERT_DIR/server.crt"
    cat "$CERT_DIR/server.json" | jq -r '.data.private_key' > "$CERT_DIR/server.key"
    cat "$CERT_DIR/server.json" | jq -r '.data.ca_chain[]' >> "$CERT_DIR/server.crt"
    print_status "Server certificate saved to $CERT_DIR/server.crt"
    print_status "Server private key saved to $CERT_DIR/server.key"
else
    print_error "Failed to generate server certificate"
    exit 1
fi

# Generate client certificate for Nomad clients
print_status "Generating Nomad client certificate..."
vault write -format=json "${PKI_PATH}/issue/${ROLE_NAME}" \
    common_name="client.global.nomad" \
    ip_sans="127.0.0.1,192.168.10.21,192.168.10.22,192.168.10.23" \
    ttl="720h" > "$CERT_DIR/client.json"

if [ $? -eq 0 ]; then
    # Extract certificate and key from JSON response
    cat "$CERT_DIR/client.json" | jq -r '.data.certificate' > "$CERT_DIR/client.crt"
    cat "$CERT_DIR/client.json" | jq -r '.data.private_key' > "$CERT_DIR/client.key"
    cat "$CERT_DIR/client.json" | jq -r '.data.ca_chain[]' >> "$CERT_DIR/client.crt"
    print_status "Client certificate saved to $CERT_DIR/client.crt"
    print_status "Client private key saved to $CERT_DIR/client.key"
else
    print_error "Failed to generate client certificate"
    exit 1
fi

# Set appropriate permissions
print_status "Setting certificate permissions..."
chmod 644 "$CERT_DIR"/*.crt
chmod 600 "$CERT_DIR"/*.key

# Verify certificates
print_status "Verifying server certificate..."
openssl x509 -in "$CERT_DIR/server.crt" -text -noout | grep -E "(Subject:|DNS:|IP Address:)" || true

print_status "Verifying client certificate..."
openssl x509 -in "$CERT_DIR/client.crt" -text -noout | grep -E "(Subject:|DNS:|IP Address:)" || true

# Summary
echo ""
print_status "=========================================="
print_status "Certificate generation complete!"
print_status "=========================================="
echo ""
echo "Certificates have been generated in: $CERT_DIR"
echo ""
echo "Files created:"
echo "  - $CERT_DIR/ca.crt        (CA Certificate)"
echo "  - $CERT_DIR/server.crt    (Nomad Server Certificate)"
echo "  - $CERT_DIR/server.key    (Nomad Server Private Key)"
echo "  - $CERT_DIR/client.crt    (Nomad Client Certificate)"
echo "  - $CERT_DIR/client.key    (Nomad Client Private Key)"
echo ""
echo "Next steps:"
echo "  1. Deploy certificates to Nomad nodes using Ansible"
echo "  2. Run: uv run ansible-playbook playbooks/infrastructure/vault/deploy-nomad-tls-config.yml"
echo ""
print_status "=========================================="
