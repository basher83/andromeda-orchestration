job "postgresql" {
  datacenters = ["dc1"]
  type        = "service"

  # Pin to nodes labeled for stateful workloads
  constraint {
    attribute = "${node.meta.role}"
    value     = "db"
  }

  group "pg" {
    count = 1

    restart {
      attempts = 3
      interval = "30s"
      delay = "10s"
      mode = "fail"
    }

    network {
      mode = "host"
      port "db" {}
    }

    # Persist data on the host
    volume "pgdata" {
      type      = "host"
      read_only = false
      source    = "pgdata"
    }

    task "postgres" {
      driver = "docker"
      user   = "999:999"

      config {
        image        = "postgres:16-alpine"
        network_mode = "host"
        ports        = ["db"]
        args = [
          "-c", "config_file=/local/postgresql.conf",
          "-c", "hba_file=/local/pg_hba.conf"
        ]
      }

      volume_mount {
        volume      = "pgdata"
        destination = "/var/lib/postgresql/data"
      }

      env {
        PGHOST_ADDR       = "0.0.0.0"
        POSTGRES_USER     = "postgres"
        POSTGRES_DB       = "postgres"
        PGDATA           = "/var/lib/postgresql/data"
      }

      # PostgreSQL configuration
      template {
        destination   = "local/postgresql.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data = <<-EOT
          listen_addresses = '0.0.0.0'
          port = {{ env "NOMAD_PORT_db" }}

          # Memory settings
          shared_buffers = '256MB'
          work_mem = '4MB'
          maintenance_work_mem = '64MB'
          max_connections = 100

          # WAL & durability
          wal_level = replica
          synchronous_commit = on
          max_wal_size = '1GB'
          min_wal_size = '80MB'
          archive_mode = off

          # Logging
          log_connections = on
          log_disconnections = on
        EOT
      }

      # Access control
      template {
        destination   = "local/pg_hba.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data = <<-EOT
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          local   all             all                                     trust
          host    all             all             127.0.0.1/32            md5
          host    all             all             ::1/128                 md5
          # Allow from cluster subnets
          host    all             all             192.168.10.0/24         md5
          host    all             all             192.168.11.0/24         md5
          host    all             all             192.168.30.0/24         md5
        EOT
      }

      # Vault secrets
      template {
        env         = true
        destination = "secrets/env"
        data = <<-EOT
          POSTGRES_PASSWORD={{ with secret "kv/postgres" }}{{ .Data.superuser_password }}{{ end }}
        EOT
      }

      service {
        name = "postgres"
        port = "db"
        tags = ["tcp", "db", "postgres16"]

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 500
        memory = 1024
      }
    }
  }
}
