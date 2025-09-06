# Nomad HCL2 Variables Implementation Guide

## Overview

This document explains how to properly pass HCL2 variables to Nomad jobs when deploying through Ansible, addressing a critical limitation of the `community.general.nomad_job` module.

## The Problem

The `community.general.nomad_job` Ansible module **does not support** the standard `NOMAD_VAR_*` environment variables that the Nomad CLI uses. This is because the module communicates directly with the Nomad HTTP API, which doesn't process environment variables.

### What Doesn't Work

```yaml
# THIS DOES NOT WORK with community.general.nomad_job
- name: Deploy job (INCORRECT)
  community.general.nomad_job:
    content: "{{ job_spec.content | b64decode }}"
    content_format: hcl
  environment:
    NOMAD_VAR_homelab_domain: "{{ homelab_domain }}" # IGNORED!
```

## The Solution

Use Nomad's `/v1/jobs/parse` API endpoint to parse the HCL with variables before submitting it to the job endpoint.

### Implementation Pattern

```yaml
# Step 1: Parse HCL with variables
- name: Parse HCL job with variables
  ansible.builtin.uri:
    url: "{{ nomad_api_endpoint }}/v1/jobs/parse?namespace={{ namespace | default('default') }}"
    method: POST
    body_format: json
    body:
      JobHCL: "{{ job_spec.content | b64decode }}"
      Variables:
        homelab_domain: "{{ homelab_domain }}"
        cluster_subdomain: "{{ cluster_subdomain | default('', true) }}"
        fqdn_suffix: "{{ fqdn_suffix | default('', true) }}"
      Canonicalize: true
    headers:
      Content-Type: "application/json"
    status_code: [200, 400, 500]
    validate_certs: "{{ validate_certs | default(true) }}"
  register: parsed_job
  when: job_spec.content | b64decode is search('variable\\s')
  failed_when: false

# Step 2: Deploy the parsed job
- name: Deploy job with parsed content
  community.general.nomad_job:
    host: "{{ nomad_api_endpoint | urlsplit('hostname') }}"
    port: "{{ nomad_api_endpoint | urlsplit('port') | default(4646, true) }}"
    use_ssl: "{{ nomad_api_endpoint.startswith('https') }}"
    namespace: "{{ namespace | default('default') }}"
    content: "{{ parsed_job.json | to_json }}"
    content_format: json # Note: JSON format, not HCL
    state: present
  register: deploy_result
  when: >
    parsed_job is defined and
    parsed_job is not failed and
    parsed_job.status | default(0) == 200 and
    parsed_job.json is defined
```

### Fallback for Non-Variable Jobs

Include a fallback for jobs that don't use variables:

```yaml
- name: Deploy job without variables (fallback)
  community.general.nomad_job:
    host: "{{ nomad_api_endpoint | urlsplit('hostname') }}"
    port: "{{ nomad_api_endpoint | urlsplit('port') | default(4646, true) }}"
    use_ssl: "{{ nomad_api_endpoint.startswith('https') }}"
    namespace: "{{ namespace | default('default') }}"
    content: "{{ job_spec.content | b64decode }}"
    content_format: hcl
    state: present
  register: deploy_result
  when: >
    parsed_job is skipped or
    parsed_job is failed or
    (parsed_job.status | default(500)) != 200 or
    parsed_job.json is not defined
```

## HCL2 Job Requirements

Your Nomad job must declare variables at the top of the file:

```hcl
variable "homelab_domain" {
  type        = string
  default     = "spaceships.work"
  description = "The domain for the homelab environment"
}

variable "cluster_subdomain" {
  type        = string
  default     = ""
  description = "Subdomain prefix for this cluster"
}

job "my-service" {
  # Use variables with ${var.variable_name}
  task "example" {
    config {
      args = [
        "--domain=${var.homelab_domain}",
        "--cluster=${var.cluster_subdomain}"
      ]
    }
  }
}
```

## Testing

### CLI Testing (Works with NOMAD*VAR*\*)

```bash
# The Nomad CLI does support environment variables
NOMAD_VAR_homelab_domain=test.spaceships.work nomad job validate my-job.nomad.hcl
NOMAD_VAR_homelab_domain=test.spaceships.work nomad job plan my-job.nomad.hcl
```

### Ansible Testing

```bash
# Deploy with Ansible (uses API parsing)
uv run ansible-playbook playbooks/infrastructure/nomad/deploy-job.yml \
  -e job=nomad-jobs/my-job.nomad.hcl \
  -e homelab_domain=test.spaceships.work
```

## Common Pitfalls

1. **Don't use Jinja2 in HCL files**: The module loads HCL files raw, not through template processing
2. **Don't rely on NOMAD*VAR* with Ansible**: Only works with CLI, not the module
3. **Always provide defaults**: Include default values in your variable declarations
4. **Check for variable usage**: The playbook checks if variables are used before parsing
5. **Handle parse failures gracefully**: The parse API may fail; always include fallback logic
6. **Include namespace parameter**: Required for multi-namespace Nomad clusters

## API Reference

### /v1/jobs/parse Endpoint

The parse endpoint accepts:

- `JobHCL`: String containing the HCL job specification
- `Variables`: Object with key-value pairs for HCL2 variables
- `Canonicalize`: Boolean to canonicalize the job specification

Returns a JSON job specification that can be submitted directly to the job endpoint.

## Related Documentation

- [Nomad HCL2 Variables Documentation](https://developer.hashicorp.com/nomad/docs/job-specification/hcl2/variables)
- [Nomad HTTP API - Jobs Parse](https://developer.hashicorp.com/nomad/api-docs/jobs#parse-job)
- [Community.General.Nomad_Job Module](https://docs.ansible.com/ansible/latest/collections/community/general/nomad_job_module.html)

## Implementation History

- **2025-01-19**: Discovered limitation during domain migration PR #72
- **Solution Credit**: CodeRabbit AI review identified the issue and suggested the parse API approach
