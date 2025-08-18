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
      delay    = "10s"
      mode     = "fail"
    }

    network {
      mode = "host"
      port "db" {} # dynamic (20000-32000 per your standard)
      # optional admin UI (e.g., pgbouncer/pgadmin later)
    }

    # Persist data on the host (simple + reliable)
    volume "pgdata" {
      type      = "host"
      read_only = false
      source    = "pgdata" # define in client config: host_volume "pgdata" { path = "/srv/nomad/pgdata" }
    }

    task "postgres" {
      driver = "docker"
      user   = "999:999" # postgres UID:GID inside container (helps permissions)
      config {
        image        = "postgres:16-alpine"
        network_mode = "host"
        ports        = ["db"]
        mount {
          type   = "volume"
          target = "/var/lib/postgresql/data"
          source = "pgdata"
        }
        args = [
          "-c", "config_file=/local/postgresql.conf"
        ]
      }

      env {
        # Bind to all, but limit via firewall/ACLs
        PGHOST_ADDR       = "0.0.0.0"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "{{ env `POSTGRES_PASSWORD` }}"
        PGDATA            = "/var/lib/postgresql/data"
      }

      # Base config
      template {
        destination   = "local/postgresql.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOT
          listen_addresses = '${PGHOST_ADDR}'
          port = {{ env "NOMAD_PORT_db" }}

          # sensible starters
          shared_buffers = '1GB'
          work_mem       = '16MB'
          maintenance_work_mem = '256MB'
          max_connections = 200

          # WAL & durability
          wal_level = replica
          synchronous_commit = on
          max_wal_size = '2GB'
          min_wal_size = '80MB'
          archive_mode = off
        EOT
      }

      # Access rules
      template {
        destination   = "local/pg_hba.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOT
          local   all             all                                     trust
          host    all             all             127.0.0.1/32            md5
          host    all             all             ::1/128                 md5
          # Allow from your cluster subnets (tighten as needed)
          host    all             all             192.168.10.0/24         md5
          host    all             all             192.168.11.0/24         md5
          host    all             all             192.168.30.0/24         md5
        EOT
      }

      # Secret env (Vault KV v2 assumed: kv/postgres)
      template {
        env         = true
        destination = "secrets/env"
        data        = <<-EOT
          POSTGRES_PASSWORD={{ with secret "kv/postgres" }}{{ .Data.data.superuser_password }}{{ end }}
        EOT
      }


      service {
        name = "postgres"
        port = "db"
        tags = ["tcp", "db", "postgres16"]
        check {
          name     = "tcp"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 500
        memory = 2048
      }
    }

    # One-shot init to create the PowerDNS DB/user (idempotent)
    task "init-pdns" {
      driver = "docker"
      lifecycle { hook = "poststart" } # run after postgres starts

      template {
        destination = "local/init.sql"
        data        = <<-EOT
          DO
          $do$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'powerdns') THEN
               PERFORM dblink_exec('dbname=' || current_database(), 'CREATE DATABASE powerdns');
            END IF;
          END
          $do$;

          DO
          $do$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pdns') THEN
               CREATE USER pdns WITH PASSWORD '{{ with secret "kv/pdns" }}{{ .Data.data.db_password }}{{ end }}';
            END IF;
          END
          $do$;

          ALTER DATABASE powerdns OWNER TO pdns;

          -- Minimal schema for PowerDNS (gpgsql backend will manage/migrate as needed)
          \connect powerdns
          CREATE TABLE IF NOT EXISTS domains (
            id SERIAL PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            type VARCHAR(6) NOT NULL,
            master VARCHAR(128),
            last_check INT,
            notified_serial INT,
            account VARCHAR(40) DEFAULT NULL
          );
          CREATE UNIQUE INDEX IF NOT EXISTS name_index ON domains(name);

          CREATE TABLE IF NOT EXISTS records (
            id BIGSERIAL PRIMARY KEY,
            domain_id INT REFERENCES domains(id) ON DELETE CASCADE,
            name VARCHAR(255),
            type VARCHAR(10),
            content TEXT,
            ttl INT,
            prio INT,
            change_date INT,
            disabled BOOL DEFAULT 'f',
            ordername VARCHAR(255),
            auth BOOL DEFAULT 't'
          );
          CREATE INDEX IF NOT EXISTS rec_name_index ON records(name);
          CREATE INDEX IF NOT EXISTS rec_type_index ON records(type);
          CREATE INDEX IF NOT EXISTS rec_domain_id ON records(domain_id);

          CREATE TABLE IF NOT EXISTS supermasters (
            ip INET NOT NULL,
            nameserver VARCHAR(255) NOT NULL,
            account VARCHAR(40) DEFAULT NULL
          );
        EOT
      }

      template {
        env         = true
        destination = "secrets/env"
        data        = <<-EOT
          POSTGRES_PASSWORD={{ with secret "kv/postgres" }}{{ .Data.data.superuser_password }}{{ end }}
        EOT
      }

      config {
        image   = "postgres:16-alpine"
        command = "sh"
        args = ["-lc", <<-EOS
          until pg_isready -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres; do sleep 1; done
          psql -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres -f /local/init.sql || true
          # Exit immediately so the hook finishes
          exit 0
        EOS
        ]
        network_mode = "host"
      }

      env {
        PGPASSWORD = "{{ env `POSTGRES_PASSWORD` }}"
      }

      resources {
        cpu    = 50
        memory = 128
      }
    }
  }
}
