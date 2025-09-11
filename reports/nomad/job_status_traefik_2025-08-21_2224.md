# Nomad Job Status Report

Generated: 2025-08-22T02:24:58Z
Nomad Endpoint: <http://192.168.11.11:4646>
Namespace: default

## Job: traefik

- **Status**: running
- **Type**: service
- **Priority**: 50
- **Datacenters**: dc1
- **Running Allocations**: 1
- **Last Modified**: Unknown

### Full Job Details

```yaml
Affinities: null
AllAtOnce: false
Constraints: null
ConsulNamespace: ''
CreateIndex: 151481
Datacenters:
- dc1
DispatchIdempotencyToken: ''
Dispatched: false
ID: traefik
JobModifyIndex: 200745
Meta: null
ModifyIndex: 200750
Multiregion: null
Name: traefik
Namespace: default
NodePool: default
NomadTokenID: ''
ParameterizedJob: null
ParentID: ''
Payload: null
Periodic: null
Priority: 50
Region: global
Spreads: null
Stable: true
Status: running
StatusDescription: ''
Stop: false
SubmitTime: 1755838693718330625
TaskGroups:
-   Affinities: null
    Constraints:
    -   LTarget: ${attr.nomad.version}
        Operand: semver
        RTarget: '>= 1.7.0-a'
    Consul: null
    Count: 1
    Disconnect: null
    EphemeralDisk:
        Migrate: false
        SizeMB: 300
        Sticky: false
    MaxClientDisconnect: null
    Meta: null
    Migrate:
        HealthCheck: checks
        HealthyDeadline: 300000000000
        MaxParallel: 1
        MinHealthyTime: 10000000000
    Name: traefik
    Networks:
    -   Mode: host
        ReservedPorts:
        -   HostNetwork: default
            Label: http
            Value: 80
        -   HostNetwork: default
            Label: https
            Value: 443
        -   HostNetwork: default
            Label: admin
            Value: 8080
    PreventRescheduleOnLost: false
    ReschedulePolicy:
        Attempts: 0
        Delay: 30000000000
        DelayFunction: exponential
        Interval: 0
        MaxDelay: 3600000000000
        Unlimited: true
    RestartPolicy:
        Attempts: 2
        Delay: 15000000000
        Interval: 1800000000000
        Mode: fail
        RenderTemplates: false
    Scaling: null
    Services: null
    ShutdownDelay: null
    Spreads: null
    StopAfterClientDisconnect: null
    Tasks:
    -   Actions: null
        Affinities: null
        Artifacts: null
        CSIPluginConfig: null
        Config:
            image: traefik:v3.0
            ports:
            - http
            - https
            - admin
            volumes:
            - local/traefik.yml:/etc/traefik/traefik.yml
            - local/dynamic:/etc/traefik/dynamic
            - traefik-certs:/certs
        Constraints:
        -   LTarget: ${attr.consul.version}
            Operand: semver
            RTarget: '>= 1.8.0'
        Consul: null
        DispatchPayload: null
        Driver: docker
        Env:
            CONSUL_HTTP_ADDR: ${attr.unique.network.ip-address}:8500
        Identities: null
        Identity:
            Audience:
            - nomadproject.io
            ChangeMode: ''
            ChangeSignal: ''
            Env: false
            File: false
            Filepath: ''
            Name: default
            ServiceName: ''
            TTL: 0
        KillSignal: ''
        KillTimeout: 5000000000
        Kind: ''
        Leader: false
        Lifecycle: null
        LogConfig:
            Disabled: false
            MaxFileSizeMB: 10
            MaxFiles: 10
        Meta: null
        Name: traefik
        Resources:
            CPU: 200
            Cores: 0
            Devices: null
            DiskMB: 0
            IOPS: 0
            MemoryMB: 256
            MemoryMaxMB: 0
            NUMA: null
            Networks: null
            SecretsMB: 0
        RestartPolicy:
            Attempts: 2
            Delay: 15000000000
            Interval: 1800000000000
            Mode: fail
            RenderTemplates: false
        ScalingPolicies: null
        Schedule: null
        Services:
        -   Address: ''
            AddressMode: auto
            CanaryMeta: null
            CanaryTags: null
            Checks: null
            Cluster: default
            Connect: null
            EnableTagOverride: false
            Identity:
                Audience:
                - consul.io
                ChangeMode: ''
                ChangeSignal: ''
                Env: false
                File: false
                Filepath: ''
                Name: consul-service_traefik-traefik-admin
                ServiceName: traefik
                TTL: 3600000000000
            Kind: ''
            Meta: null
            Name: traefik
            Namespace: default
            OnUpdate: require_healthy
            PortLabel: admin
            Provider: consul
            TaggedAddresses: null
            Tags:
            - traefik.enable=true
            - traefik.http.routers.api.rule=Host(`traefik.spaceships.work`)
            - traefik.http.routers.api.service=api@internal
            - traefik.http.routers.api.entrypoints=websecure
            - traefik.http.routers.api.tls=true
            - prometheus
            - metrics
            TaskName: traefik
            Weights: null
        -   Address: ''
            AddressMode: auto
            CanaryMeta: null
            CanaryTags: null
            Checks:
            -   AddressMode: ''
                Args: null
                Body: ''
                CheckRestart: null
                Command: ''
                Expose: false
                FailuresBeforeCritical: 0
                FailuresBeforeWarning: 0
                GRPCService: ''
                GRPCUseTLS: false
                Header: null
                InitialStatus: ''
                Interval: 10000000000
                Method: ''
                Name: http-entrypoint
                Notes: ''
                OnUpdate: require_healthy
                Path: ''
                PortLabel: http
                Protocol: ''
                SuccessBeforePassing: 0
                TLSServerName: ''
                TLSSkipVerify: false
                TaskName: traefik
                Timeout: 2000000000
                Type: tcp
            Cluster: default
            Connect: null
            EnableTagOverride: false
            Identity:
                Audience:
                - consul.io
                ChangeMode: ''
                ChangeSignal: ''
                Env: false
                File: false
                Filepath: ''
                Name: consul-service_traefik-traefik-http-http
                ServiceName: traefik-http
                TTL: 3600000000000
            Kind: ''
            Meta: null
            Name: traefik-http
            Namespace: default
            OnUpdate: require_healthy
            PortLabel: http
            Provider: consul
            TaggedAddresses: null
            Tags:
            - traefik.enable=true
            - entrypoint
            - http
            TaskName: traefik
            Weights: null
        -   Address: ''
            AddressMode: auto
            CanaryMeta: null
            CanaryTags: null
            Checks:
            -   AddressMode: ''
                Args: null
                Body: ''
                CheckRestart: null
                Command: ''
                Expose: false
                FailuresBeforeCritical: 0
                FailuresBeforeWarning: 0
                GRPCService: ''
                GRPCUseTLS: false
                Header: null
                InitialStatus: ''
                Interval: 10000000000
                Method: ''
                Name: https-entrypoint
                Notes: ''
                OnUpdate: require_healthy
                Path: ''
                PortLabel: https
                Protocol: ''
                SuccessBeforePassing: 0
                TLSServerName: ''
                TLSSkipVerify: false
                TaskName: traefik
                Timeout: 2000000000
                Type: tcp
            Cluster: default
            Connect: null
            EnableTagOverride: false
            Identity:
                Audience:
                - consul.io
                ChangeMode: ''
                ChangeSignal: ''
                Env: false
                File: false
                Filepath: ''
                Name: consul-service_traefik-traefik-https-https
                ServiceName: traefik-https
                TTL: 3600000000000
            Kind: ''
            Meta: null
            Name: traefik-https
            Namespace: default
            OnUpdate: require_healthy
            PortLabel: https
            Provider: consul
            TaggedAddresses: null
            Tags:
            - traefik.enable=true
            - entrypoint
            - https
            - tls
            TaskName: traefik
            Weights: null
        -   Address: ''
            AddressMode: auto
            CanaryMeta: null
            CanaryTags: null
            Checks: null
            Cluster: default
            Connect: null
            EnableTagOverride: false
            Identity:
                Audience:
                - consul.io
                ChangeMode: ''
                ChangeSignal: ''
                Env: false
                File: false
                Filepath: ''
                Name: consul-service_traefik-traefik-metrics-admin
                ServiceName: traefik-metrics
                TTL: 3600000000000
            Kind: ''
            Meta: null
            Name: traefik-metrics
            Namespace: default
            OnUpdate: require_healthy
            PortLabel: admin
            Provider: consul
            TaggedAddresses: null
            Tags:
            - traefik.enable=true
            - prometheus
            - metrics
            - path:/metrics
            TaskName: traefik
            Weights: null
        ShutdownDelay: 0
        Templates:
        -   ChangeMode: restart
            ChangeScript: null
            ChangeSignal: ''
            DestPath: local/traefik.yml
            EmbeddedTmpl: "# Static configuration\napi:\n  dashboard: true\n  debug:
                false\n\nentryPoints:\n  web:\n    address: \":80\"\n    http:\n      redirections:\n
                \       entryPoint:\n          to: websecure\n          scheme: https\n
                \         permanent: true\n\n  websecure:\n    address: \":443\"\n\n
                \ admin:\n    address: \":8080\"\n\nproviders:\n  # File provider
                for static configs\n  file:\n    directory: /etc/traefik/dynamic\n
                \   watch: true\n\n  # Consul Catalog for service discovery\n  consulCatalog:\n
                \   endpoint:\n      address: {{ if env \"CONSUL_HTTP_ADDR\" }}{{
                env \"CONSUL_HTTP_ADDR\" }}{{ else }}consul.service.consul:8500{{
                end }}\n      scheme: http\n    exposedByDefault: false\n    prefix:
                traefik\n    watch: true\n\n# Enable Consul KV for dynamic config
                (optional)\n# providers:\n#   consul:\n#     endpoints:\n#       -
                \"consul.service.consul:8500\"\n#     prefix: traefik\n\nping:\n  entryPoint:
                admin\n\nlog:\n  level: INFO\n\naccessLog: {}\n\nmetrics:\n  prometheus:\n
                \   entryPoint: admin\n    addEntryPointsLabels: true\n    addServicesLabels:
                true\n"
            Envvars: false
            ErrMissingKey: false
            Gid: null
            LeftDelim: '{{'
            Once: false
            Perms: '0644'
            RightDelim: '}}'
            SourcePath: ''
            Splay: 5000000000
            Uid: null
            VaultGrace: 0
            Wait: null
        -   ChangeMode: restart
            ChangeScript: null
            ChangeSignal: ''
            DestPath: local/dynamic/certs.yml
            EmbeddedTmpl: "tls:\n  stores:\n    default:\n      defaultGeneratedCert:\n
                \       resolver: default\n        domain:\n          main: \"spaceships.work\"\n
                \         sans:\n            - \"*.spaceships.work\"\n            -
                \"*.doggos.spaceships.work\"\n            - \"*.service.consul\"\n"
            Envvars: false
            ErrMissingKey: false
            Gid: null
            LeftDelim: '{{'
            Once: false
            Perms: '0644'
            RightDelim: '}}'
            SourcePath: ''
            Splay: 5000000000
            Uid: null
            VaultGrace: 0
            Wait: null
        User: ''
        Vault: null
        VolumeMounts: null
    Update:
        AutoPromote: false
        AutoRevert: false
        Canary: 0
        HealthCheck: checks
        HealthyDeadline: 300000000000
        MaxParallel: 1
        MinHealthyTime: 10000000000
        ProgressDeadline: 600000000000
        Stagger: 30000000000
    Volumes:
        traefik-certs:
            AccessMode: ''
            AttachmentMode: ''
            MountOptions: null
            Name: traefik-certs
            PerAlloc: false
            ReadOnly: false
            Source: traefik-certs
            Sticky: false
            Type: host
Type: service
UI: null
Update:
    AutoPromote: false
    AutoRevert: false
    Canary: 0
    HealthCheck: ''
    HealthyDeadline: 0
    MaxParallel: 1
    MinHealthyTime: 0
    ProgressDeadline: 0
    Stagger: 30000000000
VaultNamespace: ''
Version: 15
VersionTag: null

```
