# Testing & Quality Assurance Initiative

**Target Timeline**: August-September 2025
**Status**: Planning
**Prerequisites**: Core infrastructure stable (Phase 2 Complete ✅)

> Navigation: [Current Sprint](../current-sprint.md) | [Task Summary](../task-summary.md) | [Phase 3](./phase-3-netbox.md)

## Initiative Overview

Comprehensive testing improvements to ensure code quality, reliability, and maintainability across all custom modules, roles, and playbooks. This initiative runs parallel to Phase 3 NetBox integration work.

## Priority 1: Python Unit Tests (Critical)

### 29. Add Unit Tests for Custom Modules

**Description**: Create comprehensive unit tests for all 14 custom modules
**Status**: Not Started
**Priority**: P0 (Critical) - No test coverage for custom code
**Blockers**: None
**Related**: modules/*, tests/unit/modules/

Tasks:
- [ ] Create test structure: `mkdir -p tests/unit/modules`
- [ ] Add tests for 8 Consul modules:
  - [ ] consul_acl_token.py
  - [ ] consul_acl_policy.py
  - [ ] consul_kv.py
  - [ ] consul_service.py
  - [ ] consul_check.py
  - [ ] consul_node.py
  - [ ] consul_session.py
  - [ ] consul_snapshot.py
- [ ] Add tests for 5 Nomad modules:
  - [ ] nomad_job.py
  - [ ] nomad_acl_token.py
  - [ ] nomad_acl_policy.py
  - [ ] nomad_namespace.py
  - [ ] nomad_volume.py
- [ ] Add tests for module utility file
- [ ] Achieve 80% code coverage minimum
- [ ] Configure pytest and coverage tools
- [ ] Add test:python task to Taskfile

## Priority 2: Molecule Tests for Critical Roles

### 30. Initialize Molecule Testing for Core Roles

**Description**: Add Molecule tests for 7 roles currently without test coverage
**Status**: Not Started
**Priority**: P1 (High) - Critical roles lack automated testing
**Blockers**: None
**Related**: roles/*/molecule/

Tasks:
- [ ] Initialize Molecule for HashiCorp stack roles (highest priority):
  - [ ] consul role - Service discovery foundation
  - [ ] nomad role - Orchestration platform
  - [ ] vault role - Secrets management
- [ ] Initialize Molecule for DNS infrastructure:
  - [ ] consul_dns role - DNS resolution
- [ ] Initialize Molecule for base infrastructure:
  - [ ] system_base role - Common configuration
  - [ ] nfs role - Storage backend
  - [ ] netdata role - Monitoring
- [ ] Create standard Molecule scenarios (default, ha, upgrade)
- [ ] Configure Docker/Podman drivers
- [ ] Add converge and verify playbooks
- [ ] Document Molecule usage patterns

## Priority 3: Fix Testing Infrastructure Issues

### 31. Resolve Ansible Syntax Check Issues

**Description**: Fix deprecation warnings and YAML parsing issues
**Status**: Not Started
**Priority**: P2 (Medium) - Affects CI/CD reliability
**Blockers**: None
**Related**: ansible.cfg, playbooks/infrastructure/monitoring/

Tasks:
- [ ] Add `deprecation_warnings=False` to ansible.cfg
- [ ] Fix multi-document YAML issue in deploy-netdata-doggos.yml
- [ ] Review and update all playbooks for syntax compliance
- [ ] Configure ansible-lint rules
- [ ] Add pre-commit hooks for syntax validation
- [ ] Update CI pipeline with syntax checks

## Priority 4: Testing Documentation

### 32. Complete Testing Standards Documentation

**Description**: Document comprehensive testing requirements and patterns
**Status**: Not Started
**Priority**: P2 (Medium) - Standards needed for consistency
**Blockers**: None
**Related**: docs/standards/testing-standards.md

Tasks:
- [ ] Define when tests are required:
  - [ ] Mandate tests for all custom modules
  - [ ] Require Molecule for new roles
  - [ ] Integration test requirements
- [ ] Establish coverage requirements:
  - [ ] 80% minimum for Python modules
  - [ ] Critical path coverage for roles
  - [ ] Integration test scenarios
- [ ] Document test naming conventions:
  - [ ] Unit test patterns
  - [ ] Molecule scenario naming
  - [ ] Integration test structure
- [ ] Create pre-deployment testing checklist
- [ ] Define CI/CD integration requirements
- [ ] Add testing workflow examples

## Quick Test Commands

The following commands are now available in Taskfile.yml:

```bash
# Fast smoke test without infrastructure
task test:quick

# Run Python tests (shows modules needing tests)
task test:python

# Run Molecule tests (shows roles needing tests)
task test:roles

# Integration tests (requires infrastructure)
task test:integration:consul
task test:integration:nomad
task test:integration:vault
```

## Success Criteria

- [ ] All custom modules have 80%+ test coverage
- [ ] Critical roles have Molecule test suites
- [ ] Zero syntax errors in all playbooks
- [ ] Testing standards documented and enforced
- [ ] CI/CD pipeline includes all test types
- [ ] Pre-deployment testing checklist in use

## Risk Mitigation

1. **Test Maintenance Burden**
   - Start with critical components only
   - Use test generators where possible
   - Document patterns for consistency

2. **Infrastructure Dependencies**
   - Use mocked responses for unit tests
   - Docker/Podman for Molecule isolation
   - Optional integration tests

3. **Time Investment**
   - Prioritize by risk and usage frequency
   - Incremental implementation
   - Leverage AI assistance for test generation

## Dependencies

- Testing tools already installed via pyproject.toml
- Taskfile.yml configured with test commands
- Docker/Podman for Molecule testing
- CI/CD pipeline for automation (future)

## Timeline Estimate

- **Week 1**: Python unit tests for Consul modules
- **Week 2**: Python unit tests for Nomad modules
- **Week 3**: Molecule setup for HashiCorp roles
- **Week 4**: Documentation and CI/CD integration
