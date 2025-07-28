# 1Password Connection Issues

## Problem: "Server hostname or auth token not defined"

### Check environment variables

```bash
echo $OP_CONNECT_HOST
echo $OP_CONNECT_TOKEN
```

### 1Password Solution

```bash
source scripts/set-1password-env.sh
```

## Problem: "No route to host" when connecting to Connect server

### Test connectivity

```bash
curl -I $OP_CONNECT_HOST/health
```

### Connect Common causes

- Firewall blocking the connection
- Docker container not running
- Incorrect hostname/port

## Problem: CLI authentication prompts

### For automation, use Connect instead of CLI

### Or export session token

```bash
export OP_SESSION=$(op signin --raw)
```

## Ansible Inventory Errors

### Problem: "Failed to parse inventory with auto plugin"

#### Inventory Common causes

1. **Missing Python dependencies:**

   ```bash
   uv pip install proxmoxer requests
   ```

2. **Invalid YAML syntax:**

   ```bash
   yamllint inventory/og-homelab/proxmox.yml
   ```

3. **Credential issues:**
   - Verify token is being retrieved correctly
   - Test with hardcoded token temporarily

### Problem: "vault is required with 1Password Connect"

This error occurs when using the wrong lookup plugin.

- Use `community.general.onepassword` for CLI
- Use `onepassword_connect` (custom) for Connect
