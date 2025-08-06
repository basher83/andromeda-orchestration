# HashiCorp Stack Integration

This diagram illustrates how Consul, Vault, and Nomad work together as an integrated platform.

## Complete Stack Integration

```mermaid
graph TB
    subgraph "Service Mesh & Discovery"
        Consul[Consul<br/>Service Registry]
        ConsulDNS[Consul DNS<br/>:8600]
        ConsulConnect[Service Mesh<br/>mTLS]
    end

    subgraph "Secrets & Identity"
        Vault[Vault<br/>Secrets Manager]
        VaultPKI[PKI Engine<br/>Certificates]
        VaultKV[KV Engine<br/>Secrets]
        VaultTransit[Transit Engine<br/>Encryption]
    end

    subgraph "Orchestration"
        Nomad[Nomad<br/>Scheduler]
        NomadJobs[Job Specs]
        NomadAlloc[Allocations]
    end

    subgraph "Workloads"
        App1[Application A<br/>Container]
        App2[Application B<br/>Container]
        DB[Database<br/>StatefulSet]
    end

    %% Service Discovery
    Nomad -->|Register Services| Consul
    ConsulDNS -->|DNS Resolution| App1
    ConsulDNS -->|DNS Resolution| App2

    %% Service Mesh
    ConsulConnect -->|Sidecar Proxy| App1
    ConsulConnect -->|Sidecar Proxy| App2
    App1 <-->|mTLS| App2

    %% Secrets Management
    Nomad -->|Request Token| Vault
    Vault -->|Workload Token| NomadAlloc
    NomadAlloc -->|Inject Token| App1
    NomadAlloc -->|Inject Token| App2

    %% PKI
    VaultPKI -->|Issue Certs| Consul
    VaultPKI -->|Issue Certs| Nomad
    VaultPKI -->|App Certs| App1
    VaultPKI -->|App Certs| App2

    %% Database Credentials
    App1 -->|Dynamic Creds| VaultKV
    App2 -->|Dynamic Creds| VaultKV
    VaultKV -->|Rotate| DB

    %% Encryption
    App1 -->|Encrypt Data| VaultTransit
    App2 -->|Encrypt Data| VaultTransit

    %% Job Deployment
    NomadJobs -->|Deploy| App1
    NomadJobs -->|Deploy| App2
    NomadJobs -->|Deploy| DB

    %% Styling
    classDef consul fill:#e8f5e9,stroke:#1b5e20,stroke-width:3px
    classDef vault fill:#fff3e0,stroke:#e65100,stroke-width:3px
    classDef nomad fill:#e1f5fe,stroke:#01579b,stroke-width:3px
    classDef app fill:#f3e5f5,stroke:#4a148c,stroke-width:2px

    class Consul,ConsulDNS,ConsulConnect consul
    class Vault,VaultPKI,VaultKV,VaultTransit vault
    class Nomad,NomadJobs,NomadAlloc nomad
    class App1,App2,DB app
```

## Authentication & Authorization Flow

```mermaid
graph LR
    subgraph "Identity Sources"
        User[Human User]
        Service[Service Account]
        Workload[Nomad Workload]
    end

    subgraph "Vault Auth Methods"
        UserAuth[LDAP/OIDC<br/>Auth]
        TokenAuth[Token<br/>Auth]
        JWTAuth[JWT/Workload<br/>Identity]
    end

    subgraph "Policy Mapping"
        Admin[admin-policy<br/>Full Access]
        Producer[producer-policy<br/>Write Access]
        Consumer[consumer-policy<br/>Read Only]
    end

    subgraph "Resources"
        Secrets[Secrets<br/>KV Store]
        Certs[Certificates<br/>PKI]
        Transit[Encryption<br/>Transit]
    end

    User -->|Authenticate| UserAuth
    Service -->|Token| TokenAuth
    Workload -->|JWT| JWTAuth

    UserAuth -->|Maps to| Admin
    TokenAuth -->|Maps to| Producer
    JWTAuth -->|Maps to| Consumer

    Admin -->|Full| Secrets
    Admin -->|Full| Certs
    Admin -->|Full| Transit

    Producer -->|Write| Secrets
    Producer -->|Issue| Certs
    Producer -->|Encrypt| Transit

    Consumer -->|Read| Secrets
    Consumer -->|Read| Certs
    Consumer -->|Decrypt| Transit
```

## Service Lifecycle

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Nomad
    participant Consul
    participant Vault
    participant App as Application

    Dev->>Nomad: Submit job spec

    Nomad->>Nomad: Schedule allocation
    Nomad->>Vault: Request workload token
    Vault->>Nomad: Issue scoped token

    Nomad->>App: Start container with token

    App->>Vault: Request certificates
    Vault->>App: Issue TLS certificates

    App->>Vault: Request secrets
    Vault->>App: Return secrets

    App->>Consul: Register service
    Consul->>Consul: Health check

    Consul->>App: Configure sidecar proxy
    App->>App: Ready to serve

    loop Health Monitoring
        Consul->>App: Health check
        App->>Consul: Status OK
    end

    loop Secret Rotation
        App->>Vault: Renew token
        Vault->>App: Extended token
        App->>Vault: Refresh secrets
        Vault->>App: Updated secrets
    end
```

## Data Flow Patterns

```mermaid
graph TB
    subgraph "Ingress"
        LB[Load Balancer<br/>Traefik]
    end

    subgraph "Service Layer"
        API[API Service]
        Worker[Worker Service]
    end

    subgraph "Data Layer"
        Cache[Redis Cache]
        Queue[RabbitMQ]
        DB[(PostgreSQL)]
    end

    subgraph "Infrastructure Services"
        Consul[Consul]
        Vault[Vault]
        Nomad[Nomad]
    end

    %% Request Flow
    LB -->|Route via Consul| API
    API -->|Async Job| Queue
    Queue -->|Process| Worker
    API -->|Cache| Cache
    Worker -->|Store| DB

    %% Service Discovery
    LB -.->|Discover| Consul
    API -.->|Register| Consul
    Worker -.->|Register| Consul

    %% Secrets
    API -.->|DB Creds| Vault
    Worker -.->|DB Creds| Vault
    Cache -.->|Password| Vault
    Queue -.->|Creds| Vault

    %% Orchestration
    Nomad -.->|Deploy| API
    Nomad -.->|Deploy| Worker
    Nomad -.->|Deploy| Cache
    Nomad -.->|Deploy| Queue

    %% Styling
    classDef ingress fill:#ffecb3,stroke:#f57c00,stroke-width:3px
    classDef service fill:#e1f5fe,stroke:#0277bd,stroke-width:2px
    classDef data fill:#f3e5f5,stroke:#6a1b9a,stroke-width:2px
    classDef infra fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px

    class LB ingress
    class API,Worker service
    class Cache,Queue,DB data
    class Consul,Vault,Nomad infra
```

## Integration Benefits

### Service Discovery (Consul)

- **Automatic registration**: Services register on startup
- **Health checking**: Continuous monitoring
- **DNS interface**: Simple service resolution
- **Load balancing**: Client-side and proxy-based

### Secrets Management (Vault)

- **Dynamic credentials**: Short-lived, auto-rotated
- **PKI as a Service**: Automated certificate management
- **Encryption as a Service**: Application-level encryption
- **Audit trail**: Complete secret access logging

### Orchestration (Nomad)

- **Workload identity**: Automatic Vault integration
- **Service registration**: Automatic Consul integration
- **Resource management**: CPU, memory, network isolation
- **Rolling updates**: Zero-downtime deployments

### Combined Power

- **Zero-trust networking**: mTLS everywhere via Consul Connect
- **Automated PKI**: Vault issues certs, Consul distributes
- **Dynamic configuration**: Consul KV + Vault secrets
- **Unified workflows**: Single job spec for complete deployment
