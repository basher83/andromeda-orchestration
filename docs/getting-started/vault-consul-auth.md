# Vault & Consul Auth Setup

Quick reference for using Vault and Consul with Infisical in Codespaces.

## Token Helper Setup

1. **Make executable:**

   ```bash
   chmod +x scripts/vault/token-helper.sh
   ```

2. **Configure Vault to use it:**

   ```bash
   echo "token_helper = \"${PWD}/scripts/vault/token-helper.sh\"" >> ~/.vault
   ```

## Authentication Methods

### Method 1: Direct Export (No caching)

```bash
export VAULT_TOKEN=$(infisical secrets get VAULT_PROD_ROOT_TOKEN --env=prod --path="/apollo-13/vault/" --plain)
vault status
```

### Method 2: Login with Helper (Cached)

```bash
infisical secrets get VAULT_PROD_ROOT_TOKEN --env=prod --path="/apollo-13/vault/" --plain | vault login -
```

## Codespaces + Tailscale Setup

### Already configured in `.mise.toml`

```toml
VAULT_ADDR = "https://vault-prod-1-holly.tailfb3ea.ts.net:8200"
```

### Quick auth

```bash
export VAULT_TOKEN=$(infisical secrets get VAULT_PROD_ROOT_TOKEN --env=prod --path="/apollo-13/vault/" --plain)
vault status  # Should work!
```

## Consul Setup (No Helper Needed!)

### Quick auth

```bash
# Address already in .mise.toml: CONSUL_HTTP_ADDR = "http://192.168.11.11:8500"
export CONSUL_HTTP_TOKEN=$(infisical secrets get CONSUL_MASTER_TOKEN --env=prod --path="/apollo-13/consul/" --plain)
consul members  # Should work!
```

### Or via .envrc

```bash
echo 'export CONSUL_HTTP_TOKEN=$(infisical secrets get CONSUL_MASTER_TOKEN --env=prod --path="/apollo-13/consul/" --plain)' >> .envrc
direnv allow
```

## Troubleshooting

**TLS cert errors with IP?**

```bash
export VAULT_SKIP_VERIFY=true  # Dev only
```

**Token Helper Benefits:**

- Stores tokens per `VAULT_ADDR`
- Survives terminal restarts
- No token in shell history
