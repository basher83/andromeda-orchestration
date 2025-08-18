job "powerdns-auth" {
  datacenters = ["dc1"]
  type        = "service"

  group "auth" {
    count = 2

    network {
      mode = "host"
      port "dns" {
        static = 53
        to     = 53
      }
      port "api" {} # dynamic (Nomad alloc)
    }

    restart {
      attempts = 3
      interval = "30s"
      delay    = "10s"
      mode     = "fail"
    }

    task "pdns-auth" {
      driver = "docker"
      config {
        image        = "powerdns/pdns-auth-46:latest"
        args         = ["--config-dir=/local"]
        cap_add      = ["NET_BIND_SERVICE"]
        network_mode = "host"
      }

      env {
        # Optional: bind to a specific host IP (e.g., your 10G data net)
        BIND_ADDR = "0.0.0.0"
      }

      template {
        destination   = "local/pdns.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOT
          launch=gpgsql
          gpgsql-host={{ key "pdns/db/host" }}
          gpgsql-port={{ key "pdns/db/port" }}
          gpgsql-dbname={{ key "pdns/db/name" }}
          gpgsql-user={{ key "pdns/db/user" }}
          gpgsql-password={{ with secret "secret/data/pdns" }}{{ .Data.data.db_password }}{{ end }}
          gpgsql-dnssec=yes
          gpgsql-prepared-statements=yes

          # Listen on DNS :53 (static) on host network
          local-address=${BIND_ADDR}
          local-port=53
          version-string=anonymous

          # HTTP API (dynamic)
          api=yes
          api-key={{ with secret "secret/data/pdns" }}{{ .Data.data.api_key }}{{ end }}
          webserver=yes
          webserver-address=0.0.0.0
          webserver-port={{ env "NOMAD_PORT_api" }}

          # Security hygiene
          disable-syslog=yes
          loglevel=4
        EOT
      }

      service {
        name = "powerdns-auth"
        port = "dns"
        tags = ["udp", "tcp"]

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        check {
          name     = "dns-tcp-53"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "powerdns-auth-api"
        port = "api"
        tags = [
          # Traefik (Consul Catalog) – adjust host as you like
          "traefik.enable=true",
          "traefik.http.routers.pdnsapi.rule=Host(`pdns-api.internal`)",
          "traefik.http.services.pdnsapi.loadbalancer.server.port=${NOMAD_PORT_api}",
        ]

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        check {
          name     = "api"
          type     = "http"
          path     = "/api/v1/servers/localhost"
          interval = "15s"
          timeout  = "3s"
        }
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }

    # Spread across hosts
    spread {
      attribute = "${node.unique.id}"
      weight    = 100
    }
  }
}
