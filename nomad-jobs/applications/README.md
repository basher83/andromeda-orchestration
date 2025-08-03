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

```hcl
job "myapp" {
  datacenters = ["dc1"]
  type = "service"

  group "myapp" {
    count = 1

    network {
      port "http" {
        to = 8080  # Dynamic port, app runs on 8080 internally
      }
    }

    task "myapp" {
      driver = "docker"

      config {
        image = "myapp:latest"
        ports = ["http"]
      }

      service {
        name = "myapp"
        port = "http"
        
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.myapp.rule=Host(`myapp.lab.local`)",
          "traefik.http.routers.myapp.entrypoints=websecure",
          "traefik.http.routers.myapp.tls=true",
        ]
        
        check {
          type     = "http"
          path     = "/health"
          interval = "30s"
          timeout  = "5s"
        }
      }
    }
  }
}
```

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