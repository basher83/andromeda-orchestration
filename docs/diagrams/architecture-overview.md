# High-Level Architecture Overview

This diagram shows the overall architecture of the andromeda-orchestration automation project and how all components interact.

```mermaid
graph TB
    subgraph "Source of Truth"
        NetBox[NetBox<br/>IPAM & DCIM]
    end

    subgraph "Secrets Management"
        Infisical[Infisical<br/>Secrets Store]
    end

    subgraph "Automation Layer"
        Ansible[Ansible<br/>Automation Engine]
        AnsibleInv[Dynamic Inventory<br/>Plugins]
        AnsiblePlay[Playbooks &<br/>Roles]
    end

    subgraph "og-homelab Cluster"
        OGProxmox[Proxmox VE<br/>Hypervisor]
        OGPihole[Pi-hole<br/>Current DNS]
        OGUnbound[Unbound<br/>DNS Resolver]
    end

    subgraph "doggos-homelab Cluster"
        DogProxmox[Proxmox VE<br/>3 Nodes]
        Consul[Consul<br/>Service Discovery]
        Vault[Vault<br/>Secrets & PKI]
        Nomad[Nomad<br/>Orchestrator]
        PowerDNS[PowerDNS<br/>Future DNS]
    end

    %% Data Flow
    NetBox -->|Device Info| AnsibleInv
    Infisical -->|Credentials| Ansible
    AnsibleInv -->|Inventory| Ansible
    AnsiblePlay -->|Execute| Ansible

    %% Management Connections
    Ansible -->|Manage| OGProxmox
    Ansible -->|Manage| DogProxmox
    Ansible -->|Configure| Consul
    Ansible -->|Configure| Vault
    Ansible -->|Deploy Jobs| Nomad
    Ansible -->|Configure| PowerDNS

    %% Service Connections
    Consul <-->|Service Registry| Nomad
    Vault <-->|Secrets/Tokens| Nomad
    Vault -->|PKI/Certs| Consul
    PowerDNS -->|Query| NetBox
    PowerDNS -->|Service Discovery| Consul

    %% Migration Path
    OGPihole -.->|Migration| PowerDNS
    OGUnbound -.->|Migration| PowerDNS

    %% Styling
    classDef sourceOfTruth fill:#e1f5fe,stroke:#01579b,stroke-width:3px
    classDef secrets fill:#fff3e0,stroke:#e65100,stroke-width:3px
    classDef automation fill:#f3e5f5,stroke:#4a148c,stroke-width:3px
    classDef legacy fill:#ffebee,stroke:#b71c1c,stroke-width:2px
    classDef modern fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px

    class NetBox sourceOfTruth
    class Infisical secrets
    class Ansible,AnsibleInv,AnsiblePlay automation
    class OGPihole,OGUnbound legacy
    class PowerDNS,Consul,Vault,Nomad modern
```

## Key Components

### Source of Truth

- **NetBox**: Central repository for all network device information, IP addressing, and infrastructure documentation

### Secrets Management

- **Infisical**: Secure storage for all credentials, API tokens, and sensitive configuration data

### Automation Layer

- **Ansible**: Core automation engine executing all infrastructure changes
- **Dynamic Inventory**: Pulls real-time data from Proxmox clusters and (future) NetBox
- **Playbooks & Roles**: Organized automation code for different infrastructure tasks

### Infrastructure Clusters

- **og-homelab**: Original cluster currently running DNS services (Pi-hole + Unbound)
- **doggos-homelab**: Modern 3-node cluster running Consul and Nomad, target for new DNS infrastructure

### Migration Path

The dotted lines show the planned migration from Pi-hole/Unbound to PowerDNS integrated with NetBox and Consul.
