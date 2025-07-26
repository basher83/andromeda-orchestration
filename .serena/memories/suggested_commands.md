# Suggested Commands for NetBox Ansible Development

## Environment Setup

```bash
# Source 1Password environment variables (REQUIRED before running any commands)
source ./scripts/set-1password-env.sh

# Activate Python virtual environment
source .venv/bin/activate
```

## Consul Operations

```bash
# Check Consul cluster status
./bin/ansible-connect playbook playbooks/assessment/consul-detailed-check.yml

# Register a service with Consul
./bin/ansible-connect playbook playbooks/consul/service-register-v2.yml \
  -e '{"service": {"name": "web", "port": 8080, "tags": ["primary"]}}'

# Test Consul with 1Password integration
./bin/ansible-connect playbook playbooks/examples/consul-with-1password.yml

# Use Consul CLI with token from 1Password
export CONSUL_HTTP_TOKEN=$(op item get "Consul ACL - doggos-homelab" --vault DevOps --fields label=token --reveal)
export CONSUL_HTTP_ADDR=http://192.168.11.11:8500
consul members
```

## Nomad Operations

```bash
# Check Nomad cluster status
./bin/ansible-connect playbook playbooks/nomad/cluster-status.yml

# Deploy a Nomad job
./bin/ansible-connect playbook playbooks/nomad/job-deploy.yml -e job_path=jobs/powerdns.nomad

# Manage Nomad cluster
./bin/ansible-connect playbook playbooks/nomad/cluster-manage.yml -e nomad_action=status
./bin/ansible-connect playbook playbooks/nomad/cluster-manage.yml -e nomad_action=jobs
./bin/ansible-connect playbook playbooks/nomad/cluster-manage.yml -e nomad_action=resources

# Direct Nomad CLI
export NOMAD_ADDR=http://192.168.11.11:4646
nomad server members
nomad node status
nomad job status
```

## Assessment Playbooks

```bash
# Run comprehensive assessments
ansible-playbook playbooks/assessment/consul-health-check.yml
ansible-playbook playbooks/assessment/nomad-cluster-check.yml
ansible-playbook playbooks/assessment/infrastructure-readiness.yml

# Quick checks using direct IPs (bypass inventory issues)
ansible-playbook playbooks/assessment/consul-quick-check.yml
ansible-playbook playbooks/assessment/infra-quick-check.yml
```

## 1Password Integration

```bash
# List items in DevOps vault
op item list --vault DevOps --format json | jq '.[].title'

# Get Consul token
op item get "Consul ACL - doggos-homelab" --vault DevOps --fields label=token --reveal

# Create new credentials
op item create --category "API Credential" --title "Service Name" --vault "DevOps"
```

## Inventory Management

```bash
# Test inventory with fixed ansible_host
./bin/ansible-connect inventory -i inventory/doggos-homelab/proxmox.yml --list
./bin/ansible-connect inventory -i inventory/og-homelab/proxmox.yml --list

# Direct SSH to nodes
ssh ansible@192.168.11.11  # nomad-server-1
ssh ansible@192.168.11.12  # nomad-server-2
ssh ansible@192.168.11.13  # nomad-server-3
```

## Development & Linting

```bash
# Run production linting
ansible-lint --profile production
yamllint .
ruff check

# Fix common issues
sed -i '' 's/[[:space:]]*$//' <file>  # Remove trailing spaces
echo >> <file>                         # Add missing newline
```

## PowerDNS Deployment (Phase 2)

```bash
# Deploy PowerDNS to Nomad
./bin/ansible-connect playbook playbooks/nomad/job-deploy.yml -e job_path=jobs/powerdns.nomad

# Check deployment status
nomad job status powerdns
nomad alloc status <alloc-id>

# Test PowerDNS API
curl -H "X-API-Key: changeme" http://<node-ip>:8081/api/v1/servers
```

## Report Analysis

```bash
# View latest reports
ls -la reports/consul/
ls -la reports/nomad/
ls -la reports/infrastructure/

# Read assessment summaries
cat reports/consul/consul_detailed_assessment_*.md
cat reports/nomad/nomad_assessment_*.md
```
