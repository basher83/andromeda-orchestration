PowerDNS Secrets Playbook [create-powerdns-secrets.yml](./create-powerdns-secrets.yml):

1. ✅ Removed hard-coded credentials - Now uses ansible_env.VAULT_TOKEN and ansible_env.VAULT_ADDR
2. ✅ Fixed password generation - Uses /dev/null instead of temp files to avoid leaving secrets on disk
3. ✅ Fixed character set - Uses proper hexdigits for API key (no redundancy)
4. ✅ Added environment validation - Fails early with helpful message if direnv isn't loaded
5. ✅ Added connectivity test - Checks Vault health before attempting operations
6. ✅ Better variable organization - Grouped secrets under secrets dictionary
7. ✅ Added cleanup handler - Removes any temp files if they exist
8. ✅ Enhanced feedback - Shows masked token and environment status

Manage Secrets Playbook [manage-secrets.yml](./manage-secrets.yml):

1. ✅ Removed hard-coded credentials - Now consistent with environment variable usage

🚀 Usage

Now your playbook works properly with your existing setup:

```bash
# Ensure direnv is loaded (should be automatic in your directory)
direnv allow

# Run the playbook - it will use your Infisical-sourced credentials
uv run ansible-playbook playbooks/infrastructure/vault/create-powerdns-secrets.yml
```
