# 1Password Integration Guide

This guide covers the complete setup and usage of 1Password with Ansible for secure credential management.

## Table of Contents

1. [Overview](#overview)
2. [Integration Methods](#integration-methods)
3. [Setup Instructions](#setup-instructions)
4. [Usage Examples](#usage-examples)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

## Overview

This project supports two methods for integrating 1Password with Ansible:

1. **1Password CLI** - Uses the local `op` command-line tool
2. **1Password Connect** - Uses a self-hosted Connect server with API access

Both methods allow you to:

- Store credentials securely in 1Password
- Retrieve credentials dynamically during Ansible execution
- Avoid hardcoding sensitive data in your code
- Maintain audit trails of credential access

## Integration Methods

### 1Password CLI

**Pros:**

- Simple setup for individual users
- No server infrastructure required
- Works with personal 1Password accounts

**Cons:**

- Requires authentication for each session
- May prompt for Master Password/Touch ID
- Less suitable for automation

### 1Password Connect

**Pros:**

- No authentication prompts (uses API tokens)
- Better for CI/CD and automation
- Centralized access control
- Full audit logging

**Cons:**

- Requires running Connect server
- Business/Enterprise accounts only
- More complex initial setup

## Setup Instructions

### Option 1: 1Password Connect (Recommended)

#### 1. Deploy 1Password Connect Server

```bash
# Using Docker
docker run -d \
  --name op-connect \
  -p 8080:8080 \
  -v /path/to/1password-credentials.json:/home/opuser/.op/1password-credentials.json \
  -v op-connect-data:/home/opuser/.op/data \
  1password/connect-api:latest

# Using Docker Compose (see examples/docker-compose.yml)
docker-compose up -d
```

#### 2. Generate Connect Token

1. Sign in to 1Password.com
2. Navigate to Settings > Integrations > 1Password Connect
3. Create a new token with appropriate vault access
4. Save the token securely

#### 3. Configure Environment

Create `scripts/set-1password-env.sh`:

```bash
#!/usr/bin/env bash
export OP_CONNECT_HOST="http://your-connect-server:8080"
export OP_CONNECT_TOKEN="your-connect-token-here"
export OP_VAULT_ID="your-vault-id"  # Optional: default vault
```

#### 4. Install Dependencies

```bash
# Install the onepassword.connect collection (optional)
ansible-galaxy collection install onepassword.connect

# Python dependencies are handled by the wrapper script
```

### Option 2: 1Password CLI

#### 1. Install 1Password CLI

```bash
# macOS
brew install 1password-cli

# Linux
# Download from https://app-updates.agilebits.com/product_history/CLI2

# Verify installation
op --version
```

#### 2. Sign In

```bash
# First time setup
op account add --address my.1password.com --email your@email.com

# Sign in
op signin
```

#### 3. Configure for Ansible

The CLI integration works automatically with the `community.general.onepassword` lookup.

## Usage Examples

### Storing Credentials in 1Password

Use the provided example playbook:

```bash
ansible-playbook playbooks/examples/create-proxmox-secret.yml
```

Or manually via CLI:

```bash
op item create \
  --category="API Credential" \
  --title="Proxmox API - Production" \
  --vault="DevOps" \
  url="https://proxmox.example.com:8006" \
  username="ansible@pve" \
  token_id="ansible" \
  token_secret="your-secret-token"
```

### Using in Inventory Files

```yaml
# inventory/production/proxmox.yml
plugin: community.general.proxmox
url: https://proxmox.example.com:8006
user: ansible@pve
token_id: ansible
# With 1Password CLI
token_secret: "{{ lookup('community.general.onepassword', 'Proxmox API - Production', field='token_secret') }}"
```

### Using in Playbooks

```yaml
- name: Example playbook using 1Password
  hosts: localhost
  vars:
    # Retrieve multiple fields
    proxmox_creds: "{{ lookup('community.general.onepassword', 'Proxmox API - Production') }}"

  tasks:
    - name: Use credentials
      uri:
        url: "{{ proxmox_creds.url }}/api2/json/nodes"
        headers:
          Authorization: >-
            PVEAPIToken={{ proxmox_creds.username }}!{{ proxmox_creds.token_id }}={{ proxmox_creds.token_secret }}
```

### Using the Wrapper Script

The `bin/ansible-connect` wrapper handles all the complexity:

```bash
# Automatically fetches credentials from 1Password Connect
./bin/ansible-connect playbook site.yml

# Works with any ansible command
./bin/ansible-connect inventory -i inventory/production/proxmox.yml --list
./bin/ansible-connect vault view secrets.yml
```

## Best Practices

### 1. Vault Organization

- Create separate vaults for different environments (Dev, Staging, Prod)
- Use consistent naming conventions for items
- Tag items appropriately for easy filtering

### 2. Security

- Never commit credentials to version control
- Use `.gitignore` for environment files
- Rotate tokens regularly
- Limit Connect token permissions to required vaults only

### 3. Item Structure

Recommended fields for API credentials:

- `url` - The API endpoint
- `username` or `user` - The username
- `password` or `token_secret` - The secret
- `token_id` - For token-based auth
- Additional metadata as needed

### 4. Error Handling

Always include error handling in playbooks:

```yaml
- name: Retrieve credentials with error handling
  block:
    - name: Get credentials
      set_fact:
        creds: "{{ lookup('community.general.onepassword', 'Item Name') }}"
  rescue:
    - name: Handle missing credentials
      fail:
        msg: "Failed to retrieve credentials. Check 1Password setup."
```

## Troubleshooting

### Common Issues

#### "No route to host" on macOS

- This is due to macOS Sequoia's Local Network permissions
- See [troubleshooting.md](troubleshooting.md) for the fix

#### Authentication Prompts with CLI

- Use 1Password Connect for automation
- Or set `OP_SESSION` environment variable after signing in

#### "Item not found" Errors

- Verify the item name matches exactly
- Check vault permissions for Connect tokens
- Ensure you're using the correct vault

### Debugging

Enable verbose output:

```bash
# Debug 1Password lookups
ANSIBLE_DEBUG=1 ansible-playbook -vvv playbook.yml

# Test Connect server
curl -H "Authorization: Bearer $OP_CONNECT_TOKEN" \
  $OP_CONNECT_HOST/v1/vaults
```

## Advanced Usage

### Custom Lookup Plugin

This project includes a custom lookup plugin for Connect:

```yaml
# Using the custom plugin
secret: "{{ lookup('onepassword_connect', 'Item Name', field='password') }}"
```

### Multiple Vaults

```yaml
# Specify vault explicitly
dev_secret: "{{ lookup('community.general.onepassword', 'API Key', vault='Development', field='key') }}"
prod_secret: "{{ lookup('community.general.onepassword', 'API Key', vault='Production', field='key') }}"
```

### Dynamic Item Creation

See `playbooks/examples/create-proxmox-secret.yml` for an example of creating items programmatically.

## References

- [1Password CLI Documentation](https://developer.1password.com/docs/cli)
- [1Password Connect Documentation](https://developer.1password.com/docs/connect)
- [Ansible 1Password Lookup Plugin](https://docs.ansible.com/ansible/latest/collections/community/general/onepassword_lookup.html)
