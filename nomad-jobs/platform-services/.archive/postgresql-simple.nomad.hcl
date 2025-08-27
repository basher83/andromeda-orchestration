job "postgresql" {
  datacenters = ["dc1"]
  type        = "service"

  # Remove constraint for now, can add later if needed
  # constraint {
  #   attribute = "${node.meta.role}"
  #   value     = "db"
  # }

  group "pg" {
    count = 1

    restart {
      attempts = 3
      interval = "30s"
      delay    = "10s"
      mode     = "fail"
    }

    network {
      mode = "host"
      port "db" {} # dynamic (20000-32000 per your standard)
    }

    # Use the existing postgres-data host volume
    volume "pgdata" {
      type      = "host"
      read_only = false
      source    = "postgres-data" # matches what's configured on nodes
    }

    task "postgres" {
      driver = "docker"
      user   = "999:999" # postgres UID:GID inside container

      config {
        image        = "postgres:16-alpine"
        network_mode = "host"
        ports        = ["db"]
        command      = "postgres"
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
        POSTGRES_PASSWORD = "" # Will use Vault later
        POSTGRES_DB       = "postgres"
        PGDATA            = "/var/lib/postgresql/data"
      }

      # PostgreSQL configuration
      template {
        destination   = "local/postgresql.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOT
          listen_addresses = '0.0.0.0'
          port = {{ env "NOMAD_PORT_db" }}

          # Memory settings (adjust for your environment)
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
          log_duration = off
          log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
        EOT
      }

      # Access control
      template {
        destination   = "local/pg_hba.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOT
          # TYPE  DATABASE        USER            ADDRESS                 METHOD
          local   all             all                                     trust
          host    all             all             127.0.0.1/32            md5
          host    all             all             ::1/128                 md5
          # Allow from cluster subnets
          host    all             all             192.168.10.0/24         md5
          host    all             all             192.168.11.0/24         md5
          host    all             all             192.168.30.0/24         md5
          # Allow from Tailscale network
          host    all             all             100.64.0.0/10           md5
        EOT
      }

      service {
        name = "postgres"
        port = "db"

        identity {
          aud = ["consul.io"]
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

    # Initialize PowerDNS database and user
    task "init-pdns" {
      driver = "docker"

      lifecycle {
        hook    = "poststart"
        sidecar = false
      }

      config {
        image        = "postgres:16-alpine"
        network_mode = "host"
        command      = "/bin/sh"
        args         = ["/local/init.sh"]
      }

      env {
        PGPASSWORD    = "" # Same as main postgres password
        PDNS_PASSWORD = ""      # PowerDNS user password
      }

      template {
        destination = "local/init.sh"
        perms       = "755"
        data        = <<-EOT
          #!/bin/sh
          set -e

          echo "Waiting for PostgreSQL to be ready..."
          until pg_isready -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres; do
            sleep 1
          done

          echo "Creating PowerDNS database and user..."
          psql -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres <<-SQL
            -- Create user if not exists
            SELECT 'CREATE USER pdns WITH PASSWORD ''${PDNS_PASSWORD}'''
            WHERE NOT EXISTS (SELECT FROM pg_user WHERE usename = 'pdns')\gexec

            -- Create database if not exists
            SELECT 'CREATE DATABASE powerdns OWNER pdns'
            WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'powerdns')\gexec

            -- Grant privileges
            GRANT ALL PRIVILEGES ON DATABASE powerdns TO pdns;
          SQL

          echo "Creating PowerDNS schema..."
          psql -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres -d powerdns <<-SQL
            -- PowerDNS will create its own schema on first run
            -- Just ensure the database exists and is accessible
            SELECT version();
          SQL

          echo "PowerDNS database initialization complete!"
        EOT
      }

      resources {
        cpu    = 50
        memory = 128
      }
    }
  }
}
