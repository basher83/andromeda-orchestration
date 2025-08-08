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

    service {
      name = "traefik"
      port = "admin"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.api.rule=Host(`traefik.lab.local`)",
        "traefik.http.routers.api.service=api@internal",
        "traefik.http.routers.api.entrypoints=websecure",
        "traefik.http.routers.api.tls=true",
      ]

      check {
        type     = "http"
        path     = "/ping"
        port     = "admin"
        interval = "10s"
        timeout  = "2s"
      }

      # Service identity configuration
      identity {
        aud = ["consul.io"]
      }
    }

    service {
      name = "traefik-http"
      port = "http"

      tags = [
        "http",
        "loadbalancer",
      ]

      identity {
        aud = ["consul.io"]
      }
    }

    service {
      name = "traefik-https"
      port = "https"

      tags = [
        "https",
        "loadbalancer",
      ]

      identity {
        aud = ["consul.io"]
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

      # Service identity will provide Consul token automatically
      identity {
        env = true
      }
    }
  }
}
