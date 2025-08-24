# Dedicated Vault Infrastructure Requirements

## Overview

This document outlines the system requirements for a dedicated 4-VM Vault infrastructure consisting of:
- 1 Master Vault (auto-unseal provider)
- 3 Production Vault nodes (Raft cluster)

## VM Specifications

### Master Vault (Auto-unseal Provider)

**Role**: Provides Transit secrets engine for auto-unseal services

- **CPU**: 2 vCPUs
- **RAM**: 4 GB
- **Storage**: 40 GB SSD
- **Network**: 1 NIC (1 Gbps sufficient)
- **OS**: Ubuntu 22.04 LTS

**Rationale**: Dev mode Vault with Transit engine has minimal resource requirements. Single NIC adequate as it only serves auto-unseal requests.

### Production Vault Nodes (3x)

**Role**: Raft cluster members handling production secrets management

- **CPU**: 4 vCPUs per node
- **RAM**: 8 GB per node
- **Storage**: 100 GB SSD per node
- **Network**: 1 NIC per node (1 Gbps sufficient)
- **OS**: Ubuntu 22.04 LTS

**Rationale**: Production workloads require more resources for encryption/decryption operations, Raft consensus, and audit logging.

## Network Requirements

### Bandwidth Considerations

**1 Gbps NICs are sufficient** for this environment because:
- Vault API requests are typically small (JSON payloads)
- Raft consensus traffic is minimal
- No high-throughput data streaming
- Homelab/staging environment usage patterns

**10 Gbps NICs would be overkill** unless:
- Handling thousands of concurrent API requests
- Large secret payloads (>1MB consistently)
- High-frequency certificate generation workloads

### Network Topology

**Single NIC per VM** is recommended:
- Simplifies configuration and management
- Reduces potential network failure points
- Adequate bandwidth for Vault operations
- Cost-effective for homelab environments

**Multiple NICs** would only be needed for:
- Network segmentation requirements (management vs. application traffic)
- High-availability network redundancy
- Compliance requirements for traffic separation

## Port Requirements

### Master Vault
- **8200**: Vault API (for auto-unseal requests)
- **22**: SSH management

### Production Vault Cluster
- **8200**: Vault API (client requests)
- **8201**: Raft cluster communication (inter-node)
- **22**: SSH management

## Storage Requirements

### Master Vault
- **40 GB total**:
  - 20 GB OS and applications
  - 10 GB Vault data (Transit keys, minimal storage)
  - 10 GB logs and temporary files

### Production Vault Nodes
- **100 GB total per node**:
  - 20 GB OS and applications
  - 60 GB Vault data (secrets, Raft storage)
  - 20 GB audit logs and temporary files

### Storage Type
- **SSD recommended** for all nodes
- **NVMe preferred** for production nodes if available
- Vault benefits from low-latency storage for encryption operations

## Resource Scaling Guidelines

### CPU Scaling Triggers
- CPU utilization consistently >70%
- API response times >100ms
- High encryption/decryption workloads

### Memory Scaling Triggers
- Memory utilization >80%
- Increased cache requirements
- Large number of concurrent sessions

### Storage Scaling Triggers
- Disk usage >80%
- Rapid audit log growth
- Increased secret volume

## High Availability Considerations

### Minimum Requirements
- **3 production nodes** for Raft quorum
- **1 master node** for auto-unseal (single point acceptable in homelab)

### Enhanced HA (Future)
- **2 master nodes** with load balancer for auto-unseal redundancy
- **5 production nodes** for increased fault tolerance

## Security Hardening

### OS Level
- Minimal OS installation
- Firewall configuration (ufw/iptables)
- Regular security updates
- SSH key-based authentication only

### Network Level
- VLANs for Vault traffic isolation
- Firewall rules limiting port access
- Network segmentation from general workloads

### Vault Level
- TLS encryption for all communications
- Regular key rotation
- Audit logging enabled
- Backup encryption

## Monitoring Requirements

### Resource Monitoring
- CPU, memory, disk utilization
- Network throughput and latency
- Storage IOPS and latency

### Vault-Specific Monitoring
- API response times
- Raft cluster health
- Auto-unseal operation success rates
- Audit log growth rates

## Backup Requirements

### Data to Backup
- Raft snapshots (encrypted)
- Configuration files
- TLS certificates
- Audit logs

### Backup Storage
- **50 GB** minimum for backup retention
- Off-site storage recommended
- Encrypted backup media

## Migration Strategy

### Phase 1: Create New VMs
1. Provision 4 VMs with specifications above
2. Install and configure base OS
3. Install Vault binaries

### Phase 2: Migrate Services
1. Migrate master Vault from lloyd
2. Migrate production Vault from holly/mable
3. Add third production node

### Phase 3: Cleanup
1. Remove Vault from Nomad servers
2. Optimize Nomad server resources
3. Update DNS/load balancer configurations

## Cost Optimization

### Resource Right-sizing
- Start with minimum specifications
- Monitor utilization for 30 days
- Scale up based on actual usage patterns

### Shared Resources
- Use same storage pool for multiple VMs
- Leverage Proxmox resource sharing
- Consider memory ballooning for non-production VMs

## Summary

| Component | CPU | RAM | Storage | Network |
|-----------|-----|-----|---------|---------|
| Master Vault | 2 vCPU | 4 GB | 40 GB SSD | 1x 1Gb NIC |
| Production Vault (3x) | 4 vCPU | 8 GB | 100 GB SSD | 1x 1Gb NIC |
| **Total** | **14 vCPU** | **28 GB** | **340 GB** | **4x 1Gb NICs** |

This configuration provides a robust, scalable foundation for HashiCorp Vault in a homelab/staging environment with room for growth into production workloads.
