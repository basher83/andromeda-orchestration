job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      mode = "host"
      
      port "http" {
        static = 80
      }
      
      port "https" {
        static = 443
      }
      
      port "admin" {
        to = 8080
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v3.0"
        ports = ["http", "https", "admin"]
        args = [
          "--api.dashboard=true",
          "--api.debug=false",
          "--entrypoints.web.address=:80",
          "--entrypoints.websecure.address=:443",
          "--entrypoints.admin.address=:8080",
          "--providers.consulcatalog.endpoint.address=consul.service.consul:8500",
          "--providers.consulcatalog.exposedbydefault=false",
          "--providers.consulcatalog.prefix=traefik",
          "--providers.consulcatalog.watch=true",
          "--ping.entrypoint=admin",
          "--log.level=INFO"
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}