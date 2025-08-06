# Vault Architecture Diagram

This diagram shows the complete HashiCorp Vault deployment architecture including storage, unsealing, and integrations.

## Vault Deployment Architecture

```mermaid
graph TB
    subgraph "Vault Cluster"
        subgraph "Node 1 (Leader)"
            V1[Vault Server<br/>:8200/:8201]
            R1[Raft Storage<br/>/opt/vault/data]
        end

        subgraph "Node 2"
            V2[Vault Server<br/>:8200/:8201]
            R2[Raft Storage<br/>/opt/vault/data]
        end

        subgraph "Node 3"
            V3[Vault Server<br/>:8200/:8201]
            R3[Raft Storage<br/>/opt/vault/data]
        end
    end

    subgraph "Auto-Unseal (Optional)"
        Transit[Master Vault<br/>Transit Engine]
        KMS[Cloud KMS<br/>AWS/Azure/GCP]
    end

    subgraph "PKI Hierarchy"
        RootCA[Root CA<br/>10 year TTL]
        IntCA_C[Consul Int CA<br/>5 year TTL]
        IntCA_N[Nomad Int CA<br/>5 year TTL]
        IntCA_V[Vault Int CA<br/>5 year TTL]
    end

    subgraph "Integrations"
        Nomad[Nomad<br/>JWT Auth]
        Consul[Consul<br/>Service Registry]
        CT[consul-template<br/>Secret Rotation]
    end

    subgraph "Backup"
        Snapshot[Snapshot Storage<br/>/opt/vault-snapshots]
        S3[Remote Backup<br/>S3/NFS]
    end

    %% Raft Consensus
    V1 <-->|Raft Consensus| V2
    V2 <-->|Raft Consensus| V3
    V3 <-->|Raft Consensus| V1

    %% Storage
    V1 --> R1
    V2 --> R2
    V3 --> R3

    %% Auto-unseal
    V1 -.->|Unseal| Transit
    V2 -.->|Unseal| Transit
    V3 -.->|Unseal| Transit
    Transit -.->|Alternative| KMS

    %% PKI
    V1 --> RootCA
    RootCA --> IntCA_C
    RootCA --> IntCA_N
    RootCA --> IntCA_V

    %% Integrations
    Nomad -->|JWT/OIDC| V1
    V1 -->|Register| Consul
    CT -->|Fetch Secrets| V1

    %% Backup
    V1 -->|Daily Snapshot| Snapshot
    Snapshot -->|Sync| S3

    %% Styling
    classDef vault fill:#f9f3e9,stroke:#ff9800,stroke-width:3px
    classDef storage fill:#e8f5e9,stroke:#4caf50,stroke-width:2px
    classDef pki fill:#e1f5fe,stroke:#03a9f4,stroke-width:2px
    classDef integration fill:#f3e5f5,stroke:#9c27b0,stroke-width:2px
    classDef backup fill:#fff3e0,stroke:#ff5722,stroke-width:2px

    class V1,V2,V3 vault
    class R1,R2,R3 storage
    class RootCA,IntCA_C,IntCA_N,IntCA_V pki
    class Nomad,Consul,CT integration
    class Snapshot,S3 backup
```

## Development vs Production Modes

```mermaid
graph LR
    subgraph "Development Mode"
        DevVault[Vault Dev Server<br/>:8200]
        DevMem[In-Memory Storage<br/>Ephemeral]
        DevToken[Root Token<br/>Pre-configured]

        DevVault --> DevMem
        DevVault --> DevToken
    end

    subgraph "Production Mode"
        ProdVault[Vault Cluster<br/>3+ nodes]
        ProdRaft[Raft Storage<br/>Persistent]
        ProdUnseal[Auto-Unseal<br/>Transit/KMS]
        ProdInit[Initialize<br/>5 keys, threshold 3]

        ProdVault --> ProdRaft
        ProdVault --> ProdUnseal
        ProdVault --> ProdInit
    end

    DevVault -.->|Migration Path| ProdVault

    %% Styling
    classDef dev fill:#ffebee,stroke:#f44336,stroke-width:2px
    classDef prod fill:#e8f5e9,stroke:#4caf50,stroke-width:2px

    class DevVault,DevMem,DevToken dev
    class ProdVault,ProdRaft,ProdUnseal,ProdInit prod
```

## Secret Rotation Flow

```mermaid
sequenceDiagram
    participant CT as consul-template
    participant Vault
    participant Consul
    participant Service

    loop Every 1 hour (Gossip Keys)
        CT->>Vault: Request new gossip key
        Vault->>CT: Generate key
        CT->>Consul: Update gossip.key
        CT->>Service: Execute rotation script
        Service->>Service: Reload with new key
    end

    loop Every 24 hours (Certificates)
        CT->>Vault: Check certificate expiry
        alt Certificate expires in < 7 days
            CT->>Vault: Request new certificate
            Vault->>Vault: Sign with Intermediate CA
            Vault->>CT: Return certificate + chain
            CT->>Service: Write new certificate
            Service->>Service: Reload TLS
        else Certificate valid
            CT->>CT: Sleep until next check
        end
    end
```

## Nomad Workload Identity Flow

```mermaid
sequenceDiagram
    participant Job as Nomad Job
    participant Nomad
    participant Vault
    participant App as Application

    Job->>Nomad: Submit with vault stanza
    Nomad->>Nomad: Generate workload JWT
    Nomad->>Vault: Authenticate with JWT
    Vault->>Vault: Validate JWT signature
    Vault->>Vault: Extract claims (job, task, namespace)
    Vault->>Nomad: Return Vault token
    Nomad->>App: Inject VAULT_TOKEN env var
    App->>Vault: Request secrets with token
    Vault->>Vault: Check policy permissions
    Vault->>App: Return secrets
```

## Key Features

### Storage Backend

- **Raft**: Integrated storage, no external dependencies
- **Consensus**: Automatic leader election and failover
- **Persistence**: Data stored in `/opt/vault/data`

### High Availability

- **3-node cluster**: Tolerates 1 node failure
- **Auto-failover**: New leader elected automatically
- **Split-brain prevention**: Raft consensus protocol

### Security Layers

- **Auto-unseal**: No manual intervention required
- **PKI hierarchy**: Three-tier certificate management
- **Audit logging**: All operations logged
- **Policy enforcement**: Fine-grained access control

### Automation

- **consul-template**: Automatic secret rotation
- **Snapshots**: Daily automated backups
- **Certificate renewal**: Before expiry
- **Token management**: Short-lived, auto-renewed
