# NetBox Automation with Ansible

## Overview

This document provides comprehensive guidance on using Ansible with NetBox, based on analysis of the
`netboxlabs/netbox-learning` repository. NetBox serves as the central source of truth for network automation, providing
dynamic inventory, data queries, and state management capabilities for Ansible-driven network operations.

**Key Integration Patterns:**

- **Dynamic Inventory**: NetBox populates Ansible inventory automatically
- **State Management**: Ansible modules manage NetBox object lifecycle
- **Data Queries**: Runtime queries against NetBox for automation decisions
- **Event-Driven Automation**: NetBox webhooks trigger Ansible workflows

## NetBox Ansible Collection Integration

### Collection Overview

The `netbox.netbox` collection provides comprehensive integration between NetBox and Ansible through three primary components:

| Component             | Purpose                      | Use Cases                                 |
| --------------------- | ---------------------------- | ----------------------------------------- |
| `nb_inventory` plugin | Dynamic inventory generation | Device targeting, group organization      |
| `nb_lookup` plugin    | Runtime data queries         | Configuration generation, decision making |
| NetBox modules        | Object state management      | IPAM, DCIM object lifecycle               |

### Dynamic Inventory Configuration

#### Basic Setup

```yaml
# ansible.cfg
[defaults]
inventory = ./netbox_inv.yml

# netbox_inv.yml
---
plugin: netbox.netbox.nb_inventory
validate_certs: False
group_by:
  - device_roles
  - sites
  - platforms
  - manufacturers
```

#### Environment Variables

```bash
export NETBOX_API="https://netbox.example.com"
export NETBOX_TOKEN="your-api-token-here"
```

#### Generated Inventory Structure

The plugin creates hierarchical inventory groups:

```text
@device_roles_distribution     # Devices with "distribution" role
@device_roles_access          # Devices with "access" role
@sites_cisco_devnet          # Devices at "cisco-devnet" site
@platforms_ios_xe            # Devices running IOS-XE platform
├── sw1 (ansible_host=10.10.20.175)
├── sw2 (ansible_host=10.10.20.176)
└── sw3 (ansible_host=10.10.20.177)
```

#### Device Metadata

Each device includes comprehensive NetBox metadata:

```yaml
hostvars['sw1']:
  ansible_host: "10.10.20.175"
  device_roles: ["distribution"]
  sites: ["cisco-devnet"]
  platforms: ["ios-xe"]
  manufacturers: ["cisco"]
  custom_fields:
    ccc_device_id: "32446e0a-bf3f-465b-ad2e-e5701ff7a46c"
    cisco_catalyst_center: "sandboxdnac.cisco.com"
```

### State Management with NetBox Modules

#### IPAM Management Example

```yaml
---
- name: Create Regional Internet Registry
  netbox.netbox.netbox_rir:
    netbox_url: "{{ lookup('ansible.builtin.env', 'NETBOX_API') }}"
    netbox_token: "{{ lookup('ansible.builtin.env', 'NETBOX_TOKEN') }}"
    data:
      name: "RFC 1918"
      is_private: true
    state: present

- name: Create IP Aggregates
  netbox.netbox.netbox_aggregate:
    netbox_url: "{{ lookup('ansible.builtin.env', 'NETBOX_API') }}"
    netbox_token: "{{ lookup('ansible.builtin.env', 'NETBOX_TOKEN') }}"
    data: "{{ aggregate }}"
    state: present
  loop:
    - prefix: "10.0.0.0/8"
      rir: "RFC 1918"
    - prefix: "172.16.0.0/12"
      rir: "RFC 1918"
    - prefix: "192.168.0.0/16"
      rir: "RFC 1918"
  loop_control:
    loop_var: aggregate
```

#### Device Management Example

```yaml
- name: Create Network Device
  netbox.netbox.netbox_device:
    netbox_url: "{{ netbox_url }}"
    netbox_token: "{{ netbox_token }}"
    data:
      name: "{{ device_name }}"
      device_type: "{{ device_model }}"
      device_role: "{{ device_role }}"
      site: "{{ site_name }}"
      platform: "{{ device_platform }}"
      primary_ip4: "{{ mgmt_ip }}"
      status: "active"
      custom_fields:
        serial_number: "{{ serial }}"
    state: present
```

### Runtime Data Queries

#### Using nb_lookup Plugin

```yaml
- name: Query NetBox for Site Information
  set_fact:
    sites: "{{ query('netbox.netbox.nb_lookup', 'sites',
      api_endpoint=netbox_url, token=netbox_token) }}"

- name: Get Devices for Specific Site
  set_fact:
    site_devices: "{{ query('netbox.netbox.nb_lookup', 'devices',
      api_filter='site=cisco-devnet',
      api_endpoint=netbox_url, token=netbox_token) }}"

- name: Extract Device Names
  set_fact:
    device_names: "{{ site_devices | json_query('[*].value.name') }}"
```

#### Dynamic Configuration Generation

```yaml
- name: Generate VLAN Configuration from NetBox
  set_fact:
    vlans: "{{ query('netbox.netbox.nb_lookup', 'vlans',
      api_filter='site=' + inventory_hostname,
      api_endpoint=netbox_url, token=netbox_token) }}"

- name: Apply VLAN Configuration
  cisco.ios.ios_vlans:
    config: "{{ vlans | json_query('[*].{vlan_id: value.vid, name: value.name}') }}"
    state: overridden
```

## Role-Based Organization

### Directory Structure

```text
roles/
├── netbox_ipam/
│   ├── tasks/main.yml
│   ├── vars/main.yml
│   └── defaults/main.yml
├── netbox_devices/
│   ├── tasks/main.yml
│   ├── vars/main.yml
│   └── defaults/main.yml
└── network_config/
    ├── tasks/main.yml
    ├── templates/
    └── vars/main.yml
```

### Example Role Implementation

```yaml
# roles/netbox_ipam/tasks/main.yml
---
- name: Create IPAM Roles
  netbox.netbox.netbox_ipam_role:
    netbox_url: "{{ netbox_url }}"
    netbox_token: "{{ netbox_token }}"
    data:
      name: "{{ item.name }}"
      slug: "{{ item.slug }}"
    state: present
  loop: "{{ ipam_roles }}"

# roles/netbox_ipam/vars/main.yml
---
ipam_roles:
  - name: "Loopback"
    slug: "loopback"
  - name: "Management"
    slug: "management"
  - name: "Point-to-Point"
    slug: "p2p"
```

### Playbook Integration

```yaml
---
- name: Populate NetBox IPAM
  hosts: localhost
  gather_facts: false
  roles:
    - netbox_rirs
    - netbox_aggregates
    - netbox_ipam_roles
    - netbox_prefixes
```

## Advanced Integration Patterns

### Cisco Systems Integration

#### Custom Fields for Controller Mapping

```yaml
- name: Create Cisco-Specific Custom Fields
  netbox.netbox.netbox_custom_field:
    netbox_url: "{{ netbox_url }}"
    netbox_token: "{{ netbox_token }}"
    data:
      name: "cisco_catalyst_center"
      content_types: ["dcim.device"]
      type: "selection"
      choices:
        - "sandboxdnac.cisco.com"
        - "production-cc.example.com"
    state: present

- name: Query Cisco Catalyst Center Device
  uri:
    url: >-
      https://{{ hostvars[inventory_hostname].custom_fields['cisco_catalyst_center'] }}/dna/intent/api/v1/network-device/{{ hostvars[inventory_hostname].custom_fields['ccc_device_id'] }}
    headers:
      Authorization: "Bearer {{ ccc_auth_token }}"
    method: GET
  delegate_to: localhost
  register: device_details
```

#### Meraki Integration

```yaml
- name: Configure Meraki Device Management IP
  cisco.meraki.devices_management_interface:
    state: present
    serial: "{{ hostvars[inventory_hostname].serial }}"
    wan1:
      staticGatewayIp: "192.168.20.1"
      staticIp: "{{ hostvars[inventory_hostname].primary_ip4 | ipaddr('address') }}"
      staticSubnetMask: "255.255.255.0"
      staticDns:
        - "8.8.8.8"
      usingStaticIp: true
```

### Event-Driven Automation

#### NetBox Webhook Integration

```yaml
# rulebooks/netbox-webhook.yml
---
- name: NetBox Event-Driven Automation
  hosts: all
  sources:
    - ansible.eda.webhook:
        host: 0.0.0.0
        port: 5001
  rules:
    - name: NTP Server Configuration Update
      condition: >
        event.payload.event == "job_ended" and
        event.payload.model == "branch" and
        event.payload.data.log is search("config context ntp_servers", ignorecase=true)
      action:
        run_job_template:
          name: "Configure NTP Servers"
          organization: "Default"

    - name: VLAN Configuration Changes
      condition: >
        event.payload.event == "job_ended" and
        event.payload.model == "branch" and
        (event.payload.data.log is search("Creating VLAN", ignorecase=true) or
         event.payload.data.log is search("Deleting VLAN", ignorecase=true))
      action:
        run_job_template:
          name: "Configure VLANs"
          organization: "Default"
```

#### Triggered Playbook Example

```yaml
---
- name: Configure NTP from NetBox
  hosts: sites_melbourne
  gather_facts: false
  vars:
    ntp_servers: "{{ hostvars[inventory_hostname].config_context[0].ntp_servers }}"

  tasks:
    - name: Generate NTP Configuration
      template:
        src: ntp_config.j2
        dest: "/tmp/ntp_config_{{ inventory_hostname }}.yml"
      delegate_to: localhost

    - name: Apply NTP Configuration
      arista.eos.eos_ntp_global:
        config: "{{ lookup('file', '/tmp/ntp_config_' + inventory_hostname + '.yml') | from_yaml }}"
        state: merged

    - name: Verify NTP Configuration
      arista.eos.eos_command:
        commands:
          - "show running-config section ntp"
      register: ntp_verification
```

## Data Discovery and Ingestion

### Network Discovery with orb-agent

#### Agent Configuration

```yaml
# agent.yaml
orb:
  config_manager:
    active: git
    sources:
      git:
        url: "https://github.com/netboxlabs/netbox-learning"
        schedule: "* * * * *"
        branch: main
  backends:
    network_discovery:
    device_discovery:
    common:
      diode:
        target: "grpc://diode.example.com:8080/diode"
        api_key: "${DIODE_API_KEY}"
        agent_name: "netbox-discovery"
  policies:
    network_discovery:
      policy_1:
        scope:
          targets:
            - "172.24.0.0/24"
    device_discovery:
      discovery_1:
        config:
          schedule: "* * * * *"
          defaults:
            site: "Main Office"
        scope:
          - driver: "srl"
            hostname: "172.24.0.100"
            username: "${DEVICE_USERNAME}"
            password: "${DEVICE_PASSWORD}"
```

#### Diode Integration for Data Import

```python
# Example: CSV data import to NetBox via Diode
from diode.client import DiodeClient
from diode.entity import Device, DeviceType, Site, Manufacturer
import csv

def import_devices_from_csv(csv_file):
    client = DiodeClient(
        target="grpc://diode.example.com:8080/diode",
        app_name="ansible-inventory-import",
        app_version="1.0"
    )

    entities = []

    with open(csv_file, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            device = Device(
                name=row['Device_Name'],
                device_type=DeviceType(
                    manufacturer=row['Vendor'],
                    model=row['Device_Model']
                ),
                role=row['Device_Type'],
                site=Site(name=row['Site_Name']),
                serial=row['Serial_Number']
            )
            entities.append(device)

    response = client.ingest(entities)
    return response
```

## Monitoring and Configuration Assurance

### Intent-Based Monitoring with Icinga

#### NetBox-Driven Monitoring Configuration

```yaml
- name: Configure Device for Monitoring
  netbox.netbox.netbox_device:
    netbox_url: "{{ netbox_url }}"
    netbox_token: "{{ netbox_token }}"
    data:
      name: "{{ inventory_hostname }}"
      status: "active" # Triggers Icinga import
      custom_fields:
        icinga_import_source: "Default"
    state: present
# Icinga automatically creates:
# - Host object with management IP
# - Ping service checks
# - SNMP monitoring (if configured)
# - SSH connectivity checks
```

### Configuration Assurance Integration

```yaml
- name: Validate NTP Configuration Post-Deployment
  block:
    - name: Deploy NTP Configuration
      arista.eos.eos_ntp_global:
        config: "{{ ntp_config }}"
        state: merged

    - name: Trigger Netpicker Policy Check
      uri:
        url: "http://netpicker.example.com/api/policies/ntp/validate"
        method: POST
        body_format: json
        body:
          device: "{{ inventory_hostname }}"
          policy: "corporate_ntp_policy"
      delegate_to: localhost
      register: policy_result

    - name: Verify Policy Compliance
      assert:
        that:
          - policy_result.json.compliant == true
        fail_msg: "Device {{ inventory_hostname }} failed NTP policy compliance"
```

## Best Practices

### Security and Authentication

```yaml
# Use Ansible Vault for sensitive data
vault_netbox_token: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  66633...encrypted...token

# Environment variable approach
netbox_token: "{{ lookup('env', 'NETBOX_TOKEN') }}"

# Always use no_log for sensitive operations
- name: Create secret in NetBox
  netbox.netbox.netbox_secret:
    netbox_url: "{{ netbox_url }}"
    netbox_token: "{{ netbox_token }}"
    data: "{{ secret_data }}"
  no_log: true
```

### Error Handling

```yaml
- name: NetBox Operations with Error Handling
  block:
    - name: Create Device
      netbox.netbox.netbox_device:
        netbox_url: "{{ netbox_url }}"
        netbox_token: "{{ netbox_token }}"
        data: "{{ device_data }}"
        state: present
      register: device_result

  rescue:
    - name: Handle API Errors
      debug:
        msg: "Failed to create device: {{ ansible_failed_result.msg }}"
      when: "'API Error' in ansible_failed_result.msg"

    - name: Handle Authentication Errors
      fail:
        msg: "NetBox authentication failed - check token"
      when: "'401' in ansible_failed_result.msg"

  always:
    - name: Log Operation
      debug:
        msg: "Device operation completed for {{ device_data.name }}"
```

### Performance Optimization

```yaml
# Use delegation to reduce API calls
- name: Batch NetBox Operations
  netbox.netbox.netbox_device:
    netbox_url: "{{ netbox_url }}"
    netbox_token: "{{ netbox_token }}"
    data: "{{ item }}"
    state: present
  loop: "{{ device_list }}"
  delegate_to: localhost
  run_once: true

# Cache NetBox queries
- name: Cache Site Data
  set_fact:
    all_sites: "{{ query('netbox.netbox.nb_lookup', 'sites',
      api_endpoint=netbox_url, token=netbox_token) }}"
  run_once: true
  delegate_to: localhost
  delegate_facts: true
```

### Variable Organization

```yaml
# group_vars/all.yml
netbox_url: "{{ lookup('env', 'NETBOX_API') }}"
netbox_token: "{{ lookup('env', 'NETBOX_TOKEN') }}"

# group_vars/cisco_devices.yml
device_defaults:
  manufacturer: "Cisco"
  platform: "ios"

# host_vars/switch01.yml
device_specific:
  device_type: "Catalyst 9300"
  mgmt_ip: "192.168.1.10"
  site: "Branch Office 1"
```

## Testing and Validation

### Check Mode and Dry Runs

```yaml
- name: Test NetBox Changes (Dry Run)
  netbox.netbox.netbox_device:
    netbox_url: "{{ netbox_url }}"
    netbox_token: "{{ netbox_token }}"
    data: "{{ test_device }}"
    state: present
  check_mode: true
  register: check_result

- name: Display Proposed Changes
  debug:
    msg: "Would create device: {{ test_device.name }}"
  when: check_result.changed
```

### Integration Testing

```yaml
- name: Validate NetBox Connectivity
  uri:
    url: "{{ netbox_url }}/api/status/"
    headers:
      Authorization: "Token {{ netbox_token }}"
    method: GET
  register: netbox_status
  failed_when: netbox_status.status != 200

- name: Test Inventory Plugin
  assert:
    that:
      - groups['device_roles_access'] is defined
      - hostvars[inventory_hostname].ansible_host is defined
    fail_msg: "NetBox inventory plugin not working correctly"
```

## Troubleshooting

### Common Issues and Solutions

| Issue                   | Cause                      | Solution                                            |
| ----------------------- | -------------------------- | --------------------------------------------------- |
| Empty inventory         | Wrong API URL/token        | Verify `NETBOX_API` and `NETBOX_TOKEN`              |
| Module not found        | Collection not installed   | `ansible-galaxy collection install netbox.netbox`   |
| API errors              | Insufficient permissions   | Check NetBox user permissions                       |
| SSL certificate errors  | Self-signed certificates   | Set `validate_certs: False`                         |
| Device not in inventory | Wrong status or missing IP | Verify device status is "Active" and has primary IP |

### Debug Commands

```bash
# Test inventory plugin
ansible-inventory -i netbox_inv.yml --list

# Verify collection installation
ansible-galaxy collection list | grep netbox

# Test NetBox connectivity
curl -H "Authorization: Token ${NETBOX_TOKEN}" "${NETBOX_API}/api/status/"

# Debug playbook execution
ansible-playbook -i netbox_inv.yml playbook.yml -vvv
```

This comprehensive guide covers the essential patterns for integrating Ansible with NetBox, from basic dynamic inventory
to advanced automation workflows. The examples are based on real implementations from the NetBox learning repository and
demonstrate production-ready patterns for network automation.

## Related Documentation

- [DNS & IPAM Implementation Plan](dns-ipam-implementation-plan.md) - Master plan using NetBox as source of truth
- [Project Task List](project-task-list.md) - NetBox integration tasks and progress
- [Infisical Setup and Migration](infisical-setup-and-migration.md) - Secret management for NetBox API tokens
- [Troubleshooting Guide](troubleshooting.md) - General troubleshooting including API connectivity
- [Testing Strategy](testing-strategy.md) - Testing approaches for NetBox automation
