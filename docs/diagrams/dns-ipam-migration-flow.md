# DNS & IPAM Migration Flow

This diagram illustrates the phased migration approach from the current DNS infrastructure to the target NetBox-integrated solution.

```mermaid
flowchart TD
    Start([Current State:<br/>Pi-hole + Unbound]) --> Phase0{Phase 0:<br/>Assessment}
    
    Phase0 -->|Complete| Phase1[Phase 1:<br/>Consul Foundation]
    Phase0 -->|Issues Found| Fix0[Fix Infrastructure<br/>Issues]
    Fix0 --> Phase0
    
    Phase1 --> Phase1Tasks{Tasks}
    Phase1Tasks --> T1A[Deploy Consul DNS]
    Phase1Tasks --> T1B[Configure ACLs]
    Phase1Tasks --> T1C[Setup Service Registry]
    
    T1A & T1B & T1C --> Phase1Check{Health Check}
    Phase1Check -->|Pass| Phase2[Phase 2:<br/>PowerDNS Deployment]
    Phase1Check -->|Fail| Rollback1[Rollback Consul<br/>Changes]
    Rollback1 --> Phase1
    
    Phase2 --> Phase2Tasks{Tasks}
    Phase2Tasks --> T2A[Deploy PowerDNS<br/>in Nomad]
    Phase2Tasks --> T2B[Configure Zones]
    Phase2Tasks --> T2C[Test Resolution]
    
    T2A & T2B & T2C --> Phase2Check{Validation}
    Phase2Check -->|Pass| Phase3[Phase 3:<br/>NetBox Integration]
    Phase2Check -->|Fail| Rollback2[Rollback PowerDNS]
    Rollback2 --> Phase2
    
    Phase3 --> Phase3Tasks{Tasks}
    Phase3Tasks --> T3A[Import Existing<br/>DNS Records]
    Phase3Tasks --> T3B[Configure<br/>Dynamic Updates]
    Phase3Tasks --> T3C[Setup API<br/>Integration]
    
    T3A & T3B & T3C --> Phase3Check{Integration Test}
    Phase3Check -->|Pass| Phase4[Phase 4:<br/>DNS Cutover]
    Phase3Check -->|Fail| Rollback3[Fix Integration]
    Rollback3 --> Phase3
    
    Phase4 --> Phase4Tasks{Cutover Steps}
    Phase4Tasks --> T4A[Update DHCP<br/>DNS Servers]
    Phase4Tasks --> T4B[Monitor Traffic]
    Phase4Tasks --> T4C[Decommission<br/>Pi-hole]
    
    T4A & T4B --> CutoverCheck{Traffic OK?}
    CutoverCheck -->|Yes| T4C
    CutoverCheck -->|No| EmergencyRB[Emergency<br/>Rollback]
    EmergencyRB --> Start
    
    T4C --> Phase5[Phase 5:<br/>Production Hardening]
    
    Phase5 --> Phase5Tasks{Tasks}
    Phase5Tasks --> T5A[Enable Monitoring]
    Phase5Tasks --> T5B[Configure Backups]
    Phase5Tasks --> T5C[Document Runbooks]
    
    T5A & T5B & T5C --> Complete([Migration Complete:<br/>PowerDNS + NetBox])
    
    %% Styling
    classDef phase fill:#e3f2fd,stroke:#1976d2,stroke-width:3px
    classDef task fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    classDef check fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    classDef rollback fill:#ffebee,stroke:#d32f2f,stroke-width:3px
    classDef success fill:#e8f5e9,stroke:#388e3c,stroke-width:3px
    
    class Phase0,Phase1,Phase2,Phase3,Phase4,Phase5 phase
    class T1A,T1B,T1C,T2A,T2B,T2C,T3A,T3B,T3C,T4A,T4B,T4C,T5A,T5B,T5C task
    class Phase1Check,Phase2Check,Phase3Check,CutoverCheck check
    class Rollback1,Rollback2,Rollback3,EmergencyRB,Fix0 rollback
    class Start,Complete success
```

## Migration Phases

### Phase 0: Infrastructure Assessment
- Validate current infrastructure health
- Document existing DNS configuration
- Identify and fix any blocking issues

### Phase 1: Consul Foundation
- Deploy Consul DNS on port 8600
- Configure ACLs and encryption
- Establish service discovery baseline

### Phase 2: PowerDNS Deployment
- Deploy PowerDNS via Nomad jobs
- Configure initial zones and forwarders
- Validate DNS resolution functionality

### Phase 3: NetBox Integration
- Import existing DNS records to NetBox
- Configure PowerDNS to use NetBox as backend
- Setup dynamic record management

### Phase 4: DNS Cutover
- Update DHCP to point to new DNS servers
- Monitor traffic and validate resolution
- Decommission legacy Pi-hole infrastructure

### Phase 5: Production Hardening
- Enable comprehensive monitoring
- Configure automated backups
- Create operational runbooks

## Rollback Strategy

Each phase includes specific rollback procedures:
- **Phase 1**: Revert Consul configuration
- **Phase 2**: Remove PowerDNS deployment
- **Phase 3**: Disconnect NetBox integration
- **Phase 4**: Emergency rollback to Pi-hole
- **Phase 5**: No rollback needed (hardening only)

## Decision Points

Critical go/no-go decisions occur at:
1. End of Phase 0 assessment
2. Consul health check (Phase 1)
3. PowerDNS validation (Phase 2)
4. NetBox integration test (Phase 3)
5. Traffic validation during cutover (Phase 4)