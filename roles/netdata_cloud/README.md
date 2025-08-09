# Netdata Cloud Role

This role handles claiming Netdata agents to Netdata Cloud for centralized monitoring and management.

## Features

- Claim nodes to Netdata Cloud
- Support for proxy configurations
- Force reclaim functionality
- Node labeling for cloud organization
- Infisical integration for secure token storage
- Connection status verification

## Requirements

- Netdata installed and running
- Valid Netdata Cloud account
- Claim token and room ID from Netdata Cloud
- Ansible 2.9+

## Role Variables

### Basic Configuration

```yaml
# Enable cloud claiming
netdata_cloud_enabled: false

# Claiming credentials (get from Netdata Cloud)
netdata_claim_token: ""
netdata_claim_rooms: ""
netdata_claim_url: "https://app.netdata.cloud"
```

### Advanced Settings

```yaml
# Proxy configuration (if behind proxy)
netdata_claim_proxy: "http://proxy.example.com:8080"

# Force reclaim even if already claimed
netdata_claim_force: false

# Skip SSL verification (not recommended for production)
netdata_claim_insecure: false
```

### Node Metadata

```yaml
# Labels for organizing nodes in Netdata Cloud
netdata_cloud_node_labels:
  environment: "production"
  datacenter: "us-east-1"
  role: "web-server"
  team: "platform"
```

### Infisical Integration

```yaml
# Use Infisical for secure token storage
netdata_use_infisical: false
netdata_infisical_path: "/apollo-13/services/netdata"
```

## Dependencies

- `netdata_install` role must be run first
- `netdata_configure` role should be run before claiming

## Example Playbooks

### Basic Cloud Claiming

```yaml
- hosts: all
  roles:
    - role: netdata_cloud
      vars:
        netdata_cloud_enabled: true
        netdata_claim_token: "your-claim-token-here"
        netdata_claim_rooms: "your-room-id-here"
```

### Claiming with Node Labels

```yaml
- hosts: production
  roles:
    - role: netdata_cloud
      vars:
        netdata_cloud_enabled: true
        netdata_claim_token: "{{ vault_netdata_claim_token }}"
        netdata_claim_rooms: "{{ vault_netdata_claim_rooms }}"
        netdata_cloud_node_labels:
          environment: "{{ env_name }}"
          datacenter: "{{ ansible_hostname | regex_search('^[a-z]+') }}"
          role: "{{ server_role }}"
          team: "infrastructure"
```

### Using Infisical for Tokens

```yaml
- hosts: all
  roles:
    - role: netdata_cloud
      vars:
        netdata_cloud_enabled: true
        netdata_use_infisical: true
        netdata_infisical_path: "/apollo-13/services/netdata"
        # Tokens will be retrieved from Infisical automatically
```

### Claiming Behind Proxy

```yaml
- hosts: corporate_network
  roles:
    - role: netdata_cloud
      vars:
        netdata_cloud_enabled: true
        netdata_claim_token: "{{ claim_token }}"
        netdata_claim_rooms: "{{ claim_rooms }}"
        netdata_claim_proxy: "http://corporate-proxy:3128"
```

### Force Reclaim Nodes

```yaml
- hosts: reclaim_nodes
  roles:
    - role: netdata_cloud
      vars:
        netdata_cloud_enabled: true
        netdata_claim_token: "new-token"
        netdata_claim_rooms: "new-room-id"
        netdata_claim_force: true
```

## Getting Claim Credentials

1. Log in to [Netdata Cloud](https://app.netdata.cloud)
2. Navigate to your Space
3. Click "Add Nodes" or "Connect Nodes"
4. Copy the claim token and room ID from the provided command
5. Use these values in your playbook

## Files and Directories

- `/var/lib/netdata/cloud.d/claimed_id` - Claim ID file (created after claiming)
- `/var/lib/netdata/cloud.d/labels.conf` - Node labels configuration

## Handlers

- `restart netdata` - Restarts Netdata service

## Tags

- `netdata` - All Netdata tasks
- `netdata-cloud` - Cloud claiming tasks
- `netdata-claim` - Claim execution
- `netdata-cloud-config` - Cloud configuration
- `netdata-secrets` - Secret retrieval

## Verification

After claiming, verify the connection:

```bash
# Check claim status
ls -la /var/lib/netdata/cloud.d/claimed_id

# Check cloud connection
netdatacli aclk-state

# View in Netdata Cloud
# Visit https://app.netdata.cloud and check your Space
```

## Troubleshooting

### Claiming Fails

1. **Invalid Token/Room**
   - Verify credentials from Netdata Cloud
   - Ensure token hasn't expired

2. **Network Issues**
   ```bash
   # Test connectivity
   curl -I https://app.netdata.cloud
   ```

3. **Proxy Issues**
   - Verify proxy settings
   - Check proxy allows HTTPS traffic

4. **Already Claimed**
   - Use `netdata_claim_force: true` to reclaim
   - Or manually remove `/var/lib/netdata/cloud.d/claimed_id`

### Node Not Appearing in Cloud

1. Check ACLK (Agent Cloud Link) status:
   ```bash
   netdatacli aclk-state
   ```

2. Review Netdata logs:
   ```bash
   journalctl -u netdata | grep -i cloud
   ```

3. Ensure firewall allows outbound HTTPS (port 443)

### Labels Not Updating

Labels are applied at claim time. To update:
1. Modify `netdata_cloud_node_labels`
2. Run playbook with `netdata_claim_force: true`

## Security Considerations

- Never commit claim tokens to version control
- Use Ansible Vault or Infisical for token storage
- Rotate tokens periodically
- Use node labels to organize access control in Netdata Cloud

## Netdata Cloud Features

Once claimed, you can:
- View all metrics in a unified dashboard
- Set up alerts and notifications
- Create custom dashboards
- Share dashboards with team members
- Access nodes remotely through the cloud
- Perform cross-node queries

## License

MIT

## Author Information

Andromeda Orchestration Infrastructure Team
