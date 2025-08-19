#!/bin/bash
# Generate .mcp.json from template using Infisical secrets
# This script securely fetches secrets and generates the MCP configuration
# Usage: ./generate-mcp-config.sh [--force]

set -euo pipefail

# Parse command line arguments
FORCE_OVERWRITE=false
if [ "${1:-}" = "--force" ] || [ "${1:-}" = "-f" ]; then
    FORCE_OVERWRITE=true
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TEMPLATE_FILE="mcp.json.template"
OUTPUT_FILE=".mcp.json"

# Function to print colored messages
print_error() { echo -e "${RED}❌ $1${NC}" >&2; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "ℹ️  $1"; }

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    print_error "Template file '$TEMPLATE_FILE' not found!"
    echo "Please create the template file first with placeholders like \${GITHUB_PERSONAL_ACCESS_TOKEN}"
    exit 1
fi

# Check if output file already exists
if [ -f "$OUTPUT_FILE" ]; then
    if [ "$FORCE_OVERWRITE" = true ]; then
        print_info "Force mode: Backing up existing file to ${OUTPUT_FILE}.backup"
        cp "$OUTPUT_FILE" "${OUTPUT_FILE}.backup"
    else
        print_warning "$OUTPUT_FILE already exists!"
        echo "Do you want to overwrite it? (y/n)"
        read -rp "> " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            print_info "Cancelled. Existing $OUTPUT_FILE was not modified."
            exit 0
        fi
        print_info "Backing up existing file to ${OUTPUT_FILE}.backup"
        cp "$OUTPUT_FILE" "${OUTPUT_FILE}.backup"
    fi
fi

# Check if required tools are installed
if ! command -v infisical &> /dev/null; then
    print_error "Infisical CLI is not installed!"
    echo "Please install it from: https://infisical.com/docs/cli/overview"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_error "jq is not installed!"
    echo "This tool is required and should be installed via mise"
    echo "Run: mise install jq"
    exit 1
fi

# Check if authenticated with Infisical by trying to list secrets
if ! infisical secrets &> /dev/null; then
    print_warning "Not authenticated with Infisical. Please log in..."
    if ! infisical login; then
        print_error "Failed to authenticate with Infisical"
        exit 1
    fi
fi

# Check .infisical.json configuration
if [ ! -f ".infisical.json" ]; then
    print_error ".infisical.json not found! Run 'infisical init' first"
    exit 1
fi

# Get the default environment from .infisical.json if set
INFISICAL_ENV=$(jq -r '.defaultEnvironment // "dev"' .infisical.json 2>/dev/null || echo "dev")
if [ "$INFISICAL_ENV" = "null" ] || [ -z "$INFISICAL_ENV" ]; then
    INFISICAL_ENV="dev"
fi

print_info "Fetching secrets from Infisical (environment: $INFISICAL_ENV)..."

# Export secrets to environment variables
# Using a subshell to avoid polluting the parent environment
(
    # Export API keys from specific path
    print_info "Fetching API keys from /API-keys path..."
    eval "$(infisical export --format=dotenv-export --env="$INFISICAL_ENV" --path="/API-keys" 2>/dev/null)" || {
        print_warning "Failed to fetch secrets from /API-keys path"
        echo "Trying without path restriction..."
        eval "$(infisical export --format=dotenv-export --env="$INFISICAL_ENV" 2>/dev/null)" || {
            print_error "Failed to fetch secrets from Infisical"
            echo "Make sure you have access to the project and environment"
            exit 1
        }
    }

    # Check if required secrets are present
    if [ -z "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]; then
        print_warning "GITHUB_PERSONAL_ACCESS_TOKEN not found in Infisical"
        echo "Make sure it exists in /API-keys path in environment: $INFISICAL_ENV"
        echo "Some MCP servers may not work without required secrets"
    fi

    print_info "Generating $OUTPUT_FILE from template..."

    # Create .mcp.json from template by replacing placeholders
    # Using envsubst if available, otherwise fall back to sed
    if command -v envsubst &> /dev/null; then
        envsubst < "$TEMPLATE_FILE" > "$OUTPUT_FILE"
    else
        # Fallback to sed for basic variable replacement
        cp "$TEMPLATE_FILE" "$OUTPUT_FILE.tmp"

        # Replace common secret placeholders
        for var in GITHUB_PERSONAL_ACCESS_TOKEN ANTHROPIC_API_KEY OPENAI_API_KEY FIRECRAWL_API_KEY; do
            if [ -n "${!var:-}" ]; then
                sed -i "s|\${$var}|${!var}|g" "$OUTPUT_FILE.tmp"
            fi
        done

        mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
    fi
)

# Verify the output file was created
if [ ! -f "$OUTPUT_FILE" ]; then
    print_error "Failed to generate $OUTPUT_FILE"
    exit 1
fi

# Set restrictive permissions on the generated file
chmod 600 "$OUTPUT_FILE"

# Validate JSON syntax with jq
if jq empty "$OUTPUT_FILE" 2>/dev/null; then
    print_success "$OUTPUT_FILE generated successfully with valid JSON!"
else
    print_error "$OUTPUT_FILE contains invalid JSON!"
    echo "Please check the template and try again"
    exit 1
fi

# Final checks and recommendations
echo ""
print_info "Configuration summary:"
echo "  • File: $OUTPUT_FILE"
echo "  • Permissions: 600 (read/write for owner only)"
echo "  • Environment: $INFISICAL_ENV"

if [ -f ".gitignore" ] && grep -q "^\.mcp\.json$" .gitignore; then
    echo "  • Git: ✓ Excluded from version control"
else
    print_warning ".mcp.json should be in .gitignore!"
fi

echo ""
print_info "Next steps:"
echo "  1. Verify the configuration: cat $OUTPUT_FILE | jq"
echo "  2. Test MCP servers: mise mcp list"
echo "  3. Update secrets in Infisical as needed"
