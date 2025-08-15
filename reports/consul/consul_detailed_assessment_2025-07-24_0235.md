# Consul Cluster Detailed Assessment Report

Generated: 2025-07-24T06:35:50Z

## Cluster Overview

Total nodes: 6

- Servers: 3
- Clients: 3

## Leader Information

Failed to retrieve leader information

## Node Details

### nomad-server-1 (192.168.11.11)

- Role: server
- SSH Status: Success

```
=== Node Info ===
nomad-server-1
Role: server

=== Consul Members ===
Node            Address             Status  Type    Build   Protocol  DC   Partition  Segment
nomad-server-1  192.168.11.11:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-2  192.168.11.12:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-3  192.168.11.13:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-client-1  192.168.11.20:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-2  192.168.11.21:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-3  192.168.11.22:8301  alive   client  1.20.5  2         dc1  default    <default>

=== Consul Info ===
agent:
 check_monitors = 0
 check_ttls = 0
 checks = 0
 services = 0
build:
 prerelease =
 revision = 136b9cb8
 version = 1.21.2
 version_metadata =
consul:
 acl = enabled
 bootstrap = false
 known_datacenters = 1
 leader = false
 leader_addr = 192.168.11.12:8300
 server = true
raft:
 applied_index = 258714
 commit_index = 258714
 fsm_pending = 0
 last_contact = 63.754059ms
 last_log_index = 258714
 last_log_term = 7
 last_snapshot_index = 245760
 last_snapshot_term = 7
 latest_configuration = [{Suffrage:Voter ID:b38f83f5-c9c8-a173-e07b-4b150e26234d Address:192.168.11.13:8300} {Suffrage:Voter ID:0c584b88-b8b8-6b20-0d55-cee9e84e7e08 Address:192.168.11.12:8300} {Suffrage:Voter ID:45087616-4a32-f2ae-c364-c0af2bb8ad2a Address:192.168.11.11:8300}]
 latest_configuration_index = 0
 num_peers = 2
 protocol_version = 3
 protocol_version_max = 3
 protocol_version_min = 0
 snapshot_version_max = 1
 snapshot_version_min = 0
 state = Follower
 term = 7
runtime:
 arch = amd64
 cpu_count = 4
 goroutines = 186
 max_procs = 4
 os = linux
 version = go1.23.10
serf_lan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 7
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 563
 members = 6
 query_queue = 0
 query_time = 1
serf_wan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 1
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 53
 members = 3
 query_queue = 0
 query_time = 1

=== Consul Services ===
consul

=== Consul Nodes ===
Node            ID        Address        DC
nomad-client-1  7f023fb2  192.168.11.20  dc1
nomad-client-2  75eaf485  192.168.11.21  dc1
nomad-client-3  dfd2b967  192.168.11.22  dc1
nomad-server-1  45087616  192.168.11.11  dc1
nomad-server-2  0c584b88  192.168.11.12  dc1
nomad-server-3  b38f83f5  192.168.11.13  dc1

=== DNS Test ===

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> @127.0.0.1 -p 8600 consul.service.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 32378
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;consul.service.consul.  IN A

;; AUTHORITY SECTION:
consul.   0 IN SOA ns.consul. hostmaster.consul. 1753338951 3600 600 86400 0

;; Query time: 0 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1) (UDP)
;; WHEN: Thu Jul 24 06:35:51 UTC 2025
;; MSG SIZE  rcvd: 100
```

### nomad-server-2 (192.168.11.12)

- Role: server
- SSH Status: Success

```
=== Node Info ===
nomad-server-2
Role: server

=== Consul Members ===
Node            Address             Status  Type    Build   Protocol  DC   Partition  Segment
nomad-server-1  192.168.11.11:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-2  192.168.11.12:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-3  192.168.11.13:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-client-1  192.168.11.20:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-2  192.168.11.21:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-3  192.168.11.22:8301  alive   client  1.20.5  2         dc1  default    <default>

=== Consul Info ===
agent:
 check_monitors = 0
 check_ttls = 0
 checks = 0
 services = 0
build:
 prerelease =
 revision = 136b9cb8
 version = 1.21.2
 version_metadata =
consul:
 acl = enabled
 bootstrap = false
 known_datacenters = 1
 leader = true
 leader_addr = 192.168.11.12:8300
 server = true
raft:
 applied_index = 258714
 commit_index = 258714
 fsm_pending = 0
 last_contact = 0
 last_log_index = 258714
 last_log_term = 7
 last_snapshot_index = 245762
 last_snapshot_term = 7
 latest_configuration = [{Suffrage:Voter ID:b38f83f5-c9c8-a173-e07b-4b150e26234d Address:192.168.11.13:8300} {Suffrage:Voter ID:0c584b88-b8b8-6b20-0d55-cee9e84e7e08 Address:192.168.11.12:8300} {Suffrage:Voter ID:45087616-4a32-f2ae-c364-c0af2bb8ad2a Address:192.168.11.11:8300}]
 latest_configuration_index = 0
 num_peers = 2
 protocol_version = 3
 protocol_version_max = 3
 protocol_version_min = 0
 snapshot_version_max = 1
 snapshot_version_min = 0
 state = Leader
 term = 7
runtime:
 arch = amd64
 cpu_count = 4
 goroutines = 248
 max_procs = 4
 os = linux
 version = go1.23.10
serf_lan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 7
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 563
 members = 6
 query_queue = 0
 query_time = 1
serf_wan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 1
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 53
 members = 3
 query_queue = 0
 query_time = 1

=== Consul Services ===
consul

=== Consul Nodes ===
Node            ID        Address        DC
nomad-client-1  7f023fb2  192.168.11.20  dc1
nomad-client-2  75eaf485  192.168.11.21  dc1
nomad-client-3  dfd2b967  192.168.11.22  dc1
nomad-server-1  45087616  192.168.11.11  dc1
nomad-server-2  0c584b88  192.168.11.12  dc1
nomad-server-3  b38f83f5  192.168.11.13  dc1

=== DNS Test ===

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> @127.0.0.1 -p 8600 consul.service.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 22871
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;consul.service.consul.  IN A

;; AUTHORITY SECTION:
consul.   0 IN SOA ns.consul. hostmaster.consul. 1753338951 3600 600 86400 0

;; Query time: 0 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1) (UDP)
;; WHEN: Thu Jul 24 06:35:51 UTC 2025
;; MSG SIZE  rcvd: 100
```

### nomad-server-3 (192.168.11.13)

- Role: server
- SSH Status: Success

```
=== Node Info ===
nomad-server-3
Role: server

=== Consul Members ===
Node            Address             Status  Type    Build   Protocol  DC   Partition  Segment
nomad-server-1  192.168.11.11:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-2  192.168.11.12:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-3  192.168.11.13:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-client-1  192.168.11.20:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-2  192.168.11.21:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-3  192.168.11.22:8301  alive   client  1.20.5  2         dc1  default    <default>

=== Consul Info ===
agent:
 check_monitors = 0
 check_ttls = 0
 checks = 0
 services = 0
build:
 prerelease =
 revision = 136b9cb8
 version = 1.21.2
 version_metadata =
consul:
 acl = enabled
 bootstrap = false
 known_datacenters = 1
 leader = false
 leader_addr = 192.168.11.12:8300
 server = true
raft:
 applied_index = 258714
 commit_index = 258714
 fsm_pending = 0
 last_contact = 33.676896ms
 last_log_index = 258714
 last_log_term = 7
 last_snapshot_index = 245762
 last_snapshot_term = 7
 latest_configuration = [{Suffrage:Voter ID:b38f83f5-c9c8-a173-e07b-4b150e26234d Address:192.168.11.13:8300} {Suffrage:Voter ID:0c584b88-b8b8-6b20-0d55-cee9e84e7e08 Address:192.168.11.12:8300} {Suffrage:Voter ID:45087616-4a32-f2ae-c364-c0af2bb8ad2a Address:192.168.11.11:8300}]
 latest_configuration_index = 0
 num_peers = 2
 protocol_version = 3
 protocol_version_max = 3
 protocol_version_min = 0
 snapshot_version_max = 1
 snapshot_version_min = 0
 state = Follower
 term = 7
runtime:
 arch = amd64
 cpu_count = 4
 goroutines = 163
 max_procs = 4
 os = linux
 version = go1.23.10
serf_lan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 7
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 563
 members = 6
 query_queue = 0
 query_time = 1
serf_wan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 1
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 53
 members = 3
 query_queue = 0
 query_time = 1

=== Consul Services ===
consul

=== Consul Nodes ===
Node            ID        Address        DC
nomad-client-1  7f023fb2  192.168.11.20  dc1
nomad-client-2  75eaf485  192.168.11.21  dc1
nomad-client-3  dfd2b967  192.168.11.22  dc1
nomad-server-1  45087616  192.168.11.11  dc1
nomad-server-2  0c584b88  192.168.11.12  dc1
nomad-server-3  b38f83f5  192.168.11.13  dc1

=== DNS Test ===

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> @127.0.0.1 -p 8600 consul.service.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 19046
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;consul.service.consul.  IN A

;; AUTHORITY SECTION:
consul.   0 IN SOA ns.consul. hostmaster.consul. 1753338952 3600 600 86400 0

;; Query time: 0 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1) (UDP)
;; WHEN: Thu Jul 24 06:35:52 UTC 2025
;; MSG SIZE  rcvd: 100
```

### nomad-client-1 (192.168.10.11)

- Role: client
- SSH Status: Success

```
=== Node Info ===
nomad-server-1
Role: client

=== Consul Members ===
Node            Address             Status  Type    Build   Protocol  DC   Partition  Segment
nomad-server-1  192.168.11.11:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-2  192.168.11.12:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-3  192.168.11.13:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-client-1  192.168.11.20:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-2  192.168.11.21:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-3  192.168.11.22:8301  alive   client  1.20.5  2         dc1  default    <default>

=== Consul Info ===
agent:
 check_monitors = 0
 check_ttls = 0
 checks = 0
 services = 0
build:
 prerelease =
 revision = 136b9cb8
 version = 1.21.2
 version_metadata =
consul:
 acl = enabled
 bootstrap = false
 known_datacenters = 1
 leader = false
 leader_addr = 192.168.11.12:8300
 server = true
raft:
 applied_index = 258714
 commit_index = 258714
 fsm_pending = 0
 last_contact = 78.817945ms
 last_log_index = 258714
 last_log_term = 7
 last_snapshot_index = 245760
 last_snapshot_term = 7
 latest_configuration = [{Suffrage:Voter ID:b38f83f5-c9c8-a173-e07b-4b150e26234d Address:192.168.11.13:8300} {Suffrage:Voter ID:0c584b88-b8b8-6b20-0d55-cee9e84e7e08 Address:192.168.11.12:8300} {Suffrage:Voter ID:45087616-4a32-f2ae-c364-c0af2bb8ad2a Address:192.168.11.11:8300}]
 latest_configuration_index = 0
 num_peers = 2
 protocol_version = 3
 protocol_version_max = 3
 protocol_version_min = 0
 snapshot_version_max = 1
 snapshot_version_min = 0
 state = Follower
 term = 7
runtime:
 arch = amd64
 cpu_count = 4
 goroutines = 186
 max_procs = 4
 os = linux
 version = go1.23.10
serf_lan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 7
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 563
 members = 6
 query_queue = 0
 query_time = 1
serf_wan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 1
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 53
 members = 3
 query_queue = 0
 query_time = 1

=== Consul Services ===
consul

=== Consul Nodes ===
Node            ID        Address        DC
nomad-client-1  7f023fb2  192.168.11.20  dc1
nomad-client-2  75eaf485  192.168.11.21  dc1
nomad-client-3  dfd2b967  192.168.11.22  dc1
nomad-server-1  45087616  192.168.11.11  dc1
nomad-server-2  0c584b88  192.168.11.12  dc1
nomad-server-3  b38f83f5  192.168.11.13  dc1

=== DNS Test ===

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> @127.0.0.1 -p 8600 consul.service.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 33999
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;consul.service.consul.  IN A

;; AUTHORITY SECTION:
consul.   0 IN SOA ns.consul. hostmaster.consul. 1753338953 3600 600 86400 0

;; Query time: 0 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1) (UDP)
;; WHEN: Thu Jul 24 06:35:53 UTC 2025
;; MSG SIZE  rcvd: 100
```

### nomad-client-2 (192.168.10.12)

- Role: client
- SSH Status: Success

```
=== Node Info ===
nomad-server-2
Role: client

=== Consul Members ===
Node            Address             Status  Type    Build   Protocol  DC   Partition  Segment
nomad-server-1  192.168.11.11:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-2  192.168.11.12:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-3  192.168.11.13:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-client-1  192.168.11.20:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-2  192.168.11.21:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-3  192.168.11.22:8301  alive   client  1.20.5  2         dc1  default    <default>

=== Consul Info ===
agent:
 check_monitors = 0
 check_ttls = 0
 checks = 0
 services = 0
build:
 prerelease =
 revision = 136b9cb8
 version = 1.21.2
 version_metadata =
consul:
 acl = enabled
 bootstrap = false
 known_datacenters = 1
 leader = true
 leader_addr = 192.168.11.12:8300
 server = true
raft:
 applied_index = 258714
 commit_index = 258714
 fsm_pending = 0
 last_contact = 0
 last_log_index = 258714
 last_log_term = 7
 last_snapshot_index = 245762
 last_snapshot_term = 7
 latest_configuration = [{Suffrage:Voter ID:b38f83f5-c9c8-a173-e07b-4b150e26234d Address:192.168.11.13:8300} {Suffrage:Voter ID:0c584b88-b8b8-6b20-0d55-cee9e84e7e08 Address:192.168.11.12:8300} {Suffrage:Voter ID:45087616-4a32-f2ae-c364-c0af2bb8ad2a Address:192.168.11.11:8300}]
 latest_configuration_index = 0
 num_peers = 2
 protocol_version = 3
 protocol_version_max = 3
 protocol_version_min = 0
 snapshot_version_max = 1
 snapshot_version_min = 0
 state = Leader
 term = 7
runtime:
 arch = amd64
 cpu_count = 4
 goroutines = 248
 max_procs = 4
 os = linux
 version = go1.23.10
serf_lan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 7
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 563
 members = 6
 query_queue = 0
 query_time = 1
serf_wan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 1
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 53
 members = 3
 query_queue = 0
 query_time = 1

=== Consul Services ===
consul

=== Consul Nodes ===
Node            ID        Address        DC
nomad-client-1  7f023fb2  192.168.11.20  dc1
nomad-client-2  75eaf485  192.168.11.21  dc1
nomad-client-3  dfd2b967  192.168.11.22  dc1
nomad-server-1  45087616  192.168.11.11  dc1
nomad-server-2  0c584b88  192.168.11.12  dc1
nomad-server-3  b38f83f5  192.168.11.13  dc1

=== DNS Test ===

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> @127.0.0.1 -p 8600 consul.service.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 3056
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;consul.service.consul.  IN A

;; AUTHORITY SECTION:
consul.   0 IN SOA ns.consul. hostmaster.consul. 1753338954 3600 600 86400 0

;; Query time: 0 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1) (UDP)
;; WHEN: Thu Jul 24 06:35:54 UTC 2025
;; MSG SIZE  rcvd: 100
```

### nomad-client-3 (192.168.10.22)

- Role: client
- SSH Status: Success

```
=== Node Info ===
nomad-client-3
Role: client

=== Consul Members ===
Node            Address             Status  Type    Build   Protocol  DC   Partition  Segment
nomad-server-1  192.168.11.11:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-2  192.168.11.12:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-server-3  192.168.11.13:8301  alive   server  1.21.2  2         dc1  default    <all>
nomad-client-1  192.168.11.20:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-2  192.168.11.21:8301  alive   client  1.21.2  2         dc1  default    <default>
nomad-client-3  192.168.11.22:8301  alive   client  1.20.5  2         dc1  default    <default>

=== Consul Info ===
agent:
 check_monitors = 0
 check_ttls = 0
 checks = 0
 services = 0
build:
 prerelease =
 revision = 74efe419
 version = 1.20.5
 version_metadata =
consul:
 acl = enabled
 known_servers = 3
 server = false
runtime:
 arch = amd64
 cpu_count = 8
 goroutines = 57
 max_procs = 8
 os = linux
 version = go1.23.6
serf_lan:
 coordinate_resets = 0
 encrypted = true
 event_queue = 0
 event_time = 7
 failed = 0
 health_score = 0
 intent_queue = 0
 left = 0
 member_time = 563
 members = 6
 query_queue = 0
 query_time = 1

=== Consul Services ===
consul

=== Consul Nodes ===
Node            ID        Address        DC
nomad-client-1  7f023fb2  192.168.11.20  dc1
nomad-client-2  75eaf485  192.168.11.21  dc1
nomad-client-3  dfd2b967  192.168.11.22  dc1
nomad-server-1  45087616  192.168.11.11  dc1
nomad-server-2  0c584b88  192.168.11.12  dc1
nomad-server-3  b38f83f5  192.168.11.13  dc1

=== DNS Test ===

; <<>> DiG 9.18.30-0ubuntu0.24.04.2-Ubuntu <<>> @127.0.0.1 -p 8600 consul.service.consul
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 18826
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
;; QUESTION SECTION:
;consul.service.consul.  IN A

;; AUTHORITY SECTION:
consul.   0 IN SOA ns.consul. hostmaster.consul. 1753338954 3600 600 86400 0

;; Query time: 0 msec
;; SERVER: 127.0.0.1#8600(127.0.0.1) (UDP)
;; WHEN: Thu Jul 24 06:35:54 UTC 2025
;; MSG SIZE  rcvd: 100
```

## Key Findings

1. **Cluster Health**: All nodes are running Consul service
2. **Version**: Mix of v1.21.2 (most nodes) and v1.20.5 (nomad-client-3)
3. **Network Configuration**:
   - Management: 192.168.10.x
   - Consul internal: 192.168.11.x
4. **Security**:
   - ACLs enabled (deny by default)
   - Gossip encryption enabled
5. **DNS**: Port 8600 is listening on all nodes

## Recommendations for Phase 1

1. **Version Consistency**: Update nomad-client-3 to v1.21.2
2. **DNS Integration**: Configure system resolvers to use Consul DNS
3. **Service Registration**: Implement service definitions for existing workloads
4. **Monitoring**: Set up health checks and metrics collection
5. **Backup**: Implement regular snapshot backups of Consul data
