# Network Port Architecture

This diagram illustrates the port allocation and traffic flow patterns in the Nomad-based homelab infrastructure.

## Traffic Flow Overview

```mermaid
graph TB
    subgraph "External Access"
        User[User/Browser]
    end
    
    subgraph "Edge Layer"
        LB[Load Balancer<br/>:80/:443<br/>Static Ports]
    end
    
    subgraph "Service Discovery"
        Consul[Consul<br/>:8500/:8600]
    end
    
    subgraph "Nomad Cluster"
        subgraph "Node 1"
            N1_Svc1[Service A<br/>:24563<br/>Dynamic]
            N1_Svc2[PowerDNS<br/>:53/:8081<br/>Static]
        end
        
        subgraph "Node 2"
            N2_Svc1[Service B<br/>:28934<br/>Dynamic]
            N2_Svc2[Service C<br/>:21345<br/>Dynamic]
        end
        
        subgraph "Node 3"
            N3_Svc1[Service D<br/>:30123<br/>Dynamic]
            N3_Svc2[Service E<br/>:25678<br/>Dynamic]
        end
    end
    
    User -->|HTTPS| LB
    LB -->|Service Discovery| Consul
    LB -->|Proxy| N1_Svc1
    LB -->|Proxy| N2_Svc1
    LB -->|Proxy| N2_Svc2
    LB -->|Proxy| N3_Svc1
    LB -->|Proxy| N3_Svc2
    
    N1_Svc1 -.->|Register| Consul
    N2_Svc1 -.->|Register| Consul
    N2_Svc2 -.->|Register| Consul
    N3_Svc1 -.->|Register| Consul
    N3_Svc2 -.->|Register| Consul
    N1_Svc2 -.->|Register| Consul
    
    User -->|DNS Query<br/>:53| N1_Svc2
```

## Port Allocation Strategy

```mermaid
graph LR
    subgraph "Port Ranges"
        subgraph "System Ports 1-1023"
            DNS[53 - DNS]
            HTTP[80 - HTTP]
            HTTPS[443 - HTTPS]
        end
        
        subgraph "Infrastructure 1024-19999"
            Docker[2375-2376<br/>Docker API]
            Nomad[4646-4648<br/>Nomad]
            Consul[8300-8302<br/>8500, 8600<br/>Consul]
            Netdata[19999<br/>Monitoring]
        end
        
        subgraph "Dynamic 20000-32000"
            D1[20000]
            D2[...]
            D3[32000]
        end
        
        subgraph "High Ports 32001-65535"
            Ephemeral[Ephemeral<br/>Connections]
        end
    end
```

## Service Registration Flow

```mermaid
sequenceDiagram
    participant Job as Nomad Job
    participant Nomad
    participant Service
    participant Consul
    participant LB as Load Balancer
    participant User
    
    Job->>Nomad: Submit job with dynamic port
    Nomad->>Nomad: Allocate port (e.g., 24563)
    Nomad->>Service: Start container
    Service->>Consul: Register service with allocated port
    Consul->>LB: Service available at host:24563
    User->>LB: HTTPS request to service.lab.local
    LB->>Consul: Query service location
    Consul->>LB: Return host:24563
    LB->>Service: Proxy request to dynamic port
    Service->>LB: Response
    LB->>User: HTTPS response
```

## Firewall Rules Visualization

```mermaid
graph TD
    subgraph "nftables Rules"
        subgraph "Always Open"
            A1[SSH :22]
            A2[Consul :8300-8302, :8500, :8600]
            A3[Nomad :4646-4648]
            A4[Netdata :19999]
        end
        
        subgraph "Static Service Ports"
            S1[DNS :53 TCP/UDP]
            S2[PowerDNS API :8081]
        end
        
        subgraph "Dynamic Range"
            D[Ports :20000-32000<br/>TCP/UDP]
        end
        
        subgraph "Blocked by Default"
            B1[HTTP :80]
            B2[HTTPS :443]
            B3[All Other Ports]
        end
    end
    
    A1 -->|Allow| Traffic
    A2 -->|Allow| Traffic
    A3 -->|Allow| Traffic
    A4 -->|Allow| Traffic
    S1 -->|Allow| Traffic
    S2 -->|Allow| Traffic
    D -->|Allow| Traffic
    B1 -->|Block| Drop
    B2 -->|Block| Drop
    B3 -->|Block| Drop
    
    Traffic{Incoming<br/>Traffic}
```

## Port Conflict Resolution

```mermaid
graph TD
    Start[New Service Deployment]
    Start --> Q1{Needs specific port?}
    
    Q1 -->|No| Dynamic[Use Dynamic Port<br/>20000-32000]
    Q1 -->|Yes| Q2{Why?}
    
    Q2 -->|Standard Protocol| Q3{Port Available?}
    Q2 -->|User Access| LB[Use Load Balancer<br/>+ Dynamic Port]
    Q2 -->|Legacy App| Migrate[Plan Migration<br/>to Dynamic]
    
    Q3 -->|Yes| Static[Use Static Port<br/>Document in firewall]
    Q3 -->|No| Conflict[CONFLICT!<br/>Resolve or use different node]
    
    Dynamic --> Register[Register in Consul]
    Static --> Register
    LB --> Register
    
    Register --> Success[Service Available]
```

## Example Service Deployments

### 1. Web Application (Dynamic Port)

```
┌─────────────────┐       ┌──────────────┐       ┌─────────────────┐
│                 │       │              │       │                 │
│  User Browser   │──────▶│ Traefik :443 │──────▶│ Windmill :24563 │
│                 │ HTTPS │              │ HTTP  │                 │
└─────────────────┘       └──────────────┘       └─────────────────┘
                                │                           │
                                ▼                           ▼
                          ┌──────────┐              ┌──────────┐
                          │  Consul  │◀─────────────│ Register │
                          │  Catalog │   Discovery  │ Service  │
                          └──────────┘              └──────────┘
```

### 2. DNS Service (Static Port)

```
┌─────────────────┐       ┌─────────────────┐
│                 │       │                 │
│   DNS Client    │──────▶│  PowerDNS :53   │
│                 │  UDP  │                 │
└─────────────────┘       └─────────────────┘
                                  │
                                  ▼
                          ┌──────────────┐
                          │ PowerDNS API │
                          │    :8081     │
                          └──────────────┘
```

### 3. Multi-Port Microservice

```
┌───────────────┐     ┌─────────────────────────┐     ┌─────────┐
│   Frontend    │────▶│      Microservice       │────▶│ Database│
│               │ :80 │                         │     │         │
└───────────────┘     │  HTTP API :25677       │     └─────────┘
                      │  gRPC     :26788       │
┌───────────────┐     │  Metrics  :27899       │
│  Prometheus   │────▶│  Health   :28900       │
│               │     │                         │
└───────────────┘     └─────────────────────────┘
```

## Network Segments

```mermaid
graph TB
    subgraph "Management Network 192.168.10.0/24"
        Proxmox[Proxmox Hosts]
        Infrastructure[Infrastructure VMs]
    end
    
    subgraph "Service Network 192.168.11.0/24"
        Nomad[Nomad Clients]
        Services[Dynamic Services<br/>Ports 20000-32000]
    end
    
    subgraph "Storage Network 192.168.12.0/24"
        NFS[NFS Servers]
        CSI[CSI Volumes]
    end
    
    subgraph "External Access"
        Internet[Internet]
        VPN[VPN Clients]
    end
    
    Internet -->|:80/:443| Services
    VPN -->|All Ports| Management
    VPN -->|All Ports| Services
    Services <-->|Service Mesh| Services
    Services -->|Storage| Storage
    Infrastructure -->|Management| Services
```

## Key Principles Illustrated

1. **Dynamic by Default**: Most services use ports 20000-32000
2. **Static Exceptions**: Only DNS (53) and current PowerDNS API (8081)
3. **Single Load Balancer**: One service owns 80/443 for all HTTP(S) traffic
4. **Service Discovery**: All services register with Consul
5. **Internal Communication**: Services use `.consul` domains
6. **Firewall Protection**: Only required ports are open

## Related Documentation

- [Firewall and Port Strategy](../operations/firewall-port-strategy.md)
- [Nomad Port Allocation Best Practices](../implementation/nomad-port-allocation.md)
- [Consul Service Discovery](../implementation/consul/)