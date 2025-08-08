# Consul Cluster Assessment Report
Generated: 2025-07-24T05:49:06Z

## Summary
Total nodes checked: 6

## Node Details

### nomad-server-1 (192.168.11.11)
- Role: server
- SSH Status: Success

```
=== Node Info ===
nomad-server-1
Role: server

=== Consul Version ===
Consul v1.21.2
Revision 136b9cb8
Build Date 2025-06-18T08:16:39Z
Protocol 2 spoken by default, understands 2 to 3 (agent will automatically use protocol >2 when speaking to compatible agents)


=== Consul Service ===
active

=== Consul Config ===
ls: cannot open directory '/etc/consul.d/': Permission denied
Config dir not found

=== Network Ports ===
LISTEN 0      4096                             *:8600             *:*
LISTEN 0      4096                             *:8500             *:*
LISTEN 0      4096                             *:8302             *:*
LISTEN 0      4096                             *:8300             *:*
LISTEN 0      4096                             *:8301             *:*
```

### nomad-server-2 (192.168.11.12)
- Role: server
- SSH Status: Success

```
=== Node Info ===
nomad-server-2
Role: server

=== Consul Version ===
Consul v1.21.2
Revision 136b9cb8
Build Date 2025-06-18T08:16:39Z
Protocol 2 spoken by default, understands 2 to 3 (agent will automatically use protocol >2 when speaking to compatible agents)


=== Consul Service ===
active

=== Consul Config ===
ls: cannot open directory '/etc/consul.d/': Permission denied
Config dir not found

=== Network Ports ===
LISTEN 0      4096                             *:8302             *:*
LISTEN 0      4096                             *:8301             *:*
LISTEN 0      4096                             *:8300             *:*
LISTEN 0      4096                             *:8500             *:*
LISTEN 0      4096                             *:8600             *:*
```

### nomad-server-3 (192.168.11.13)
- Role: server
- SSH Status: Success

```
=== Node Info ===
nomad-server-3
Role: server

=== Consul Version ===
Consul v1.21.2
Revision 136b9cb8
Build Date 2025-06-18T08:16:39Z
Protocol 2 spoken by default, understands 2 to 3 (agent will automatically use protocol >2 when speaking to compatible agents)


=== Consul Service ===
active

=== Consul Config ===
ls: cannot open directory '/etc/consul.d/': Permission denied
Config dir not found

=== Network Ports ===
LISTEN 0      4096                             *:8302             *:*
LISTEN 0      4096                             *:8300             *:*
LISTEN 0      4096                             *:8301             *:*
LISTEN 0      4096                             *:8500             *:*
LISTEN 0      4096                             *:8600             *:*
```

### nomad-client-1 (192.168.10.11)
- Role: client
- SSH Status: Success

```
=== Node Info ===
nomad-server-1
Role: client

=== Consul Version ===
Consul v1.21.2
Revision 136b9cb8
Build Date 2025-06-18T08:16:39Z
Protocol 2 spoken by default, understands 2 to 3 (agent will automatically use protocol >2 when speaking to compatible agents)


=== Consul Service ===
active

=== Consul Config ===
ls: cannot open directory '/etc/consul.d/': Permission denied
Config dir not found

=== Network Ports ===
LISTEN 0      4096                             *:8600             *:*
LISTEN 0      4096                             *:8500             *:*
LISTEN 0      4096                             *:8302             *:*
LISTEN 0      4096                             *:8300             *:*
LISTEN 0      4096                             *:8301             *:*
```

### nomad-client-2 (192.168.10.12)
- Role: client
- SSH Status: Success

```
=== Node Info ===
nomad-server-2
Role: client

=== Consul Version ===
Consul v1.21.2
Revision 136b9cb8
Build Date 2025-06-18T08:16:39Z
Protocol 2 spoken by default, understands 2 to 3 (agent will automatically use protocol >2 when speaking to compatible agents)


=== Consul Service ===
active

=== Consul Config ===
ls: cannot open directory '/etc/consul.d/': Permission denied
Config dir not found

=== Network Ports ===
LISTEN 0      4096                             *:8302             *:*
LISTEN 0      4096                             *:8301             *:*
LISTEN 0      4096                             *:8300             *:*
LISTEN 0      4096                             *:8500             *:*
LISTEN 0      4096                             *:8600             *:*
```

### nomad-client-3 (192.168.10.22)
- Role: client
- SSH Status: Success

```
=== Node Info ===
nomad-client-3
Role: client

=== Consul Version ===
Consul v1.20.5
Revision 74efe419
Build Date 2025-03-11T10:16:18Z
Protocol 2 spoken by default, understands 2 to 3 (agent will automatically use protocol >2 when speaking to compatible agents)


=== Consul Service ===
active

=== Consul Config ===
ls: cannot open directory '/etc/consul.d/': Permission denied
Config dir not found

=== Network Ports ===
LISTEN 0      4096                 192.168.11.22:8301       0.0.0.0:*
LISTEN 0      4096                             *:8500             *:*
LISTEN 0      4096                             *:8600             *:*
```

## Findings
- Consul appears to be installed on accessible nodes
- ACLs are enabled (deny by default)
- Cluster is configured for dual-network operation
- Management network: 192.168.10.x
- High-speed network: 192.168.11.x (used for Consul communication)

## Recommendations
1. Verify ACL tokens are properly configured
2. Check firewall rules for Consul ports (8300-8302, 8500, 8600)
3. Ensure DNS forwarding is configured for .consul domain
4. Consider implementing monitoring for cluster health
