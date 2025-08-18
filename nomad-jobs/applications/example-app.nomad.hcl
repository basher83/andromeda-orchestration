job "myapp" {
  datacenters = ["dc1"]
  type        = "service"

  group "myapp" {
    count = 1

    network {
      port "http" {
        to = 8080 # Dynamic port, app runs on 8080 internally
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
          "traefik.http.routers.myapp.rule=Host(`myapp.{{ homelab_domain }}`)",
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
