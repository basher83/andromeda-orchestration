# Consul and Nomad Integration

## Consul Cluster
- **Version**: v1.21.2 (except nomad-client-3 on v1.20.5)
- **Nodes**: 6 total (3 servers, 3 clients)
- **Leader**: nomad-server-2 (192.168.11.12:8300)
- **ACLs**: Enabled with master token in 1Password
- **Encryption**: Gossip encryption enabled
- **Network**: Using high-speed network (192.168.11.x) for internal communication

## Consul Access
- **Token**: Stored in 1Password as "Consul ACL - doggos-homelab"
- **API**: http://192.168.11.11:8500
- **DNS**: Port 8600 on all nodes
- **Usage in Ansible**:
  ```yaml
  consul_token: "{{ lookup('community.general.onepassword', 'Consul ACL - doggos-homelab', field='token', vault='DevOps') }}"
  ```

## Nomad Cluster
- **Version**: v1.10.2 on all nodes
- **Servers**: 3 (nomad-server-1/2/3)
- **Clients**: 3 (nomad-client-1/2/3)
- **Leader**: nomad-server-2 (192.168.11.12:4647)
- **ACLs**: DISABLED (no authentication needed)
- **Docker**: Available on all client nodes

## Nomad Configuration
- **Consul Integration**: Enabled with service_identity and task_identity
- **API**: http://192.168.11.11:4646
- **UI**: Enabled on all servers
- **Plugins**: Docker and LXC enabled with privileged support

## Management Playbooks

### Consul Operations
- `playbooks/assessment/consul-health-check-v2.yml` - Health check with 1Password
- `playbooks/consul/service-register-v2.yml` - Register services using hashicorp-tools
- `playbooks/examples/consul-with-1password.yml` - Example operations

### Nomad Operations
- `playbooks/nomad/job-deploy.yml` - Deploy jobs using CLI
- `playbooks/nomad/job-deploy-v2.yml` - Deploy using hashicorp-tools collection
- `playbooks/nomad/cluster-status.yml` - Check cluster status
- `playbooks/nomad/cluster-manage.yml` - Comprehensive management (drain, GC, etc.)

## Service Registration Pattern
Jobs deployed to Nomad automatically register with Consul through the service stanza:
```hcl
service {
  name = "service-name"
  port = "port-label"
  tags = ["tag1", "tag2"]
  
  check {
    type     = "http"
    path     = "/health"
    interval = "30s"
  }
}
```

## Key Integration Points
1. Nomad automatically registers services with Consul
2. No Nomad ACL token needed (disabled)
3. Consul ACL token required for direct Consul operations
4. Both clusters use dual-network architecture
5. ansible-community.hashicorp-tools collection available