job "powerdns" {
  datacenters = ["dc1"]
  type        = "service"

  group "powerdns" {
    count = 1

    network {
      port "dns" {
        static = 53
        to     = 53
      }
      port "api" {
        to = 8081 # PowerDNS API port inside container
      }
    }

    task "powerdns" {
      driver = "docker"

      config {
        image = "powerdns/pdns-auth-48:latest"
        ports = ["dns", "api"]

        # Pass arguments directly - container has pdns_server as entrypoint
        args = [
          "--daemon=no",
          "--guardian=no",
          "--launch=gsqlite3",
          "--gsqlite3-database=/var/lib/powerdns/pdns.sqlite3",
          "--webserver=yes",
          "--webserver-address=0.0.0.0",
          "--webserver-port=8081",
          "--webserver-allow-from=0.0.0.0/0",
          "--api=yes",
          "--api-key=changeme789xyz"
        ]
      }

      resources {
        cpu    = 500
        memory = 256
      }

      service {
        name = "powerdns-dns"
        port = "dns"

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        tags = [
          "dns",
          "authoritative",
          "primary"
        ]

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "powerdns-api"
        port = "api"

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        tags = [
          "api",
          "traefik.enable=true",
          "traefik.http.routers.powerdns.rule=Host(`powerdns.{{ homelab_domain }}`)",
          "traefik.http.routers.powerdns.entrypoints=websecure",
          "traefik.http.routers.powerdns.tls=true",
          "traefik.http.services.powerdns.loadbalancer.server.port=${NOMAD_PORT_api}",
        ]

        check {
          type     = "http"
          path     = "/api/v1/servers"
          interval = "30s"
          timeout  = "5s"
          header {
            X-API-Key = ["changeme789xyz"]
          }
        }
      }
    }
  }
}
