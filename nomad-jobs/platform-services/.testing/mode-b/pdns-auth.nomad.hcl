job "powerdns-auth" {
  datacenters = ["dc1"]
  type        = "service"

  group "auth" {
    count = 2

    network {
      mode = "host"
      port "dns" { to = 5301 } # local backend port (not :53)
      port "api" {}
    }

    task "pdns-auth" {
      driver = "docker"
      config {
        image        = "powerdns/pdns-auth-46:latest"
        args         = ["--config-dir=/local"]
        network_mode = "host"
      }

      template {
        destination   = "local/pdns.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOT
          launch=gmysql
          gmysql-host={{ key "pdns/db/host" }}
          gmysql-port={{ key "pdns/db/port" }}
          gmysql-dbname={{ key "pdns/db/name" }}
          gmysql-user={{ key "pdns/db/user" }}
          gmysql-password={{ with secret "kv/pdns" }}{{ .Data.data.db_password }}{{ end }}

          local-address=0.0.0.0
          local-port=5301

          api=yes
          api-key={{ with secret "kv/pdns" }}{{ .Data.data.api_key }}{{ end }}
          webserver=yes
          webserver-address=0.0.0.0
          webserver-port={{ env "NOMAD_PORT_api" }}

          disable-syslog=yes
          loglevel=4
        EOT
      }

      service {
        name = "powerdns-auth-backend"
        port = "dns"
        tags = ["udp", "tcp"]
        check {
          name     = "tcp5301"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "powerdns-auth-api"
        port = "api"
        tags = [
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

      resources {
        cpu    = 200
        memory = 256
      }
    }

    constraint {
      operator = "distinct_hosts"
      value    = "true"
    }
  }
}
