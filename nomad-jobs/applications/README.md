# Applications

This directory contains Nomad job specifications for user-facing applications.

## Deployment Pattern

All applications should:

1. Use dynamic port allocation
2. Register with Consul for service discovery
3. Include Traefik routing tags
4. Have proper health checks
5. Use persistent volumes for data

## Example Application Structure

[example-app.nomad.hcl](example-app.nomad.hcl)

## Planned Applications

### Windmill

- Workflow automation platform
- Script execution environment
- API integration hub

### Gitea

- Git repository hosting
- CI/CD webhook integration
- Code review workflows

### Wiki.js

- Documentation platform
- Markdown support
- Search capabilities
