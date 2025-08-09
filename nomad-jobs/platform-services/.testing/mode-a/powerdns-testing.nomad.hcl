job "powerdns-auth" {
  datacenters = ["dc1"]
  type        = "service"

  group "auth" {
    count = 2

    network {
      mode = "host"
      port "dns" {}     # host:53 (set below)
      port "api" {}     # dynamic (Nomad alloc)
    }

    restart { attempts = 3, interval = "30s", delay = "10s", mode = "fail" }

    task "pdns-auth" {
      driver = "docker"
      config {
        image   = "powerdns/pdns-auth-46:latest"
        args    = ["--config-dir=/local"]
        cap_add = ["NET_BIND_SERVICE"]
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
        data = <<-EOT
          launch=gmysql
          gmysql-host={{ key "pdns/db/host" }}
          gmysql-port={{ key "pdns/db/port" }}
          gmysql-dbname={{ key "pdns/db/name" }}
          gmysql-user={{ key "pdns/db/user" }}
          gmysql-password={{ with secret "kv/pdns" }}{{ .Data.data.db_password }}{{ end }}

          # Listen on DNS :53 (static) on host network
          local-address=${BIND_ADDR}
          local-port=53
          version-string=anonymous

          # HTTP API (dynamic)
          api=yes
          api-key={{ with secret "kv/pdns" }}{{ .Data.data.api_key }}{{ end }}
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

        check {
          name     = "api"
          type     = "http"
          path     = "/api/v1/servers/localhost"
          interval = "15s"
          timeout  = "3s"
        }
      }

      resources { cpu = 200, memory = 256 }
    }

    # pin :53 explicitly
    network {
      mode = "host"
      port "dns" { static = 53, to = 53 }
    }

    # Spread across hosts
    affinity { attribute = "${node.unique.id}", operator = "distinct_hosts", weight = 100 }
  }
}
