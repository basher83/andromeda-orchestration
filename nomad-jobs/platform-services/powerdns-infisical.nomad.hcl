variable "pdns_db_password" {
  type        = string
  default     = ""
  description = "PostgreSQL password for pdns user"
}

variable "pdns_api_key" {
  type        = string  
  default     = ""
  description = "PowerDNS API key"
}

job "powerdns-auth" {
  datacenters = ["dc1"]
  type        = "service"

  group "auth" {
    count = 1  # Start with 1 for testing

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
          # Password passed as HCL2 variable from Infisical
          gpgsql-password=${var.pdns_db_password}
          gpgsql-dnssec=yes
          gpgsql-prepared-statements=yes

          # Listen on DNS :53 (static) on host network
          local-address={{ env "BIND_ADDR" }}
          local-port=53
          version-string=anonymous

          # HTTP API (dynamic)
          api=yes
          # API key passed as HCL2 variable from Infisical
          api-key=${var.pdns_api_key}
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
          type     = "tcp"
          port     = "dns"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "powerdns-api"
        port = "api"
        tags = ["http", "api"]

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        check {
          type     = "http"
          path     = "/api/v1/servers/localhost"
          port     = "api"
          interval = "30s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}