job "postgresql" {
  datacenters = ["dc1"]
  type        = "service"

  # Pin to nodes labeled for stateful workloads
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
      # optional admin UI (e.g., pgbouncer/pgadmin later)
    }

    # Persist data on the host (simple + reliable)
    volume "postgres-data" {
      type      = "host"
      read_only = false
      source    = "postgres-data" # matches standard naming convention
    }

    task "postgres" {
      driver = "docker"
      user   = "999:999" # postgres UID:GID inside container (helps permissions)
      config {
        image        = "postgres:16-alpine"
        network_mode = "host"
        ports        = ["db"]
        args = [
          "-c", "config_file=/local/postgresql.conf"
        ]
      }

      volume_mount {
        volume      = "postgres-data"
        destination = "/var/lib/postgresql/data"
      }


      # Base config
      template {
        destination   = "local/postgresql.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOT
          listen_addresses = '{{ env "PGHOST_ADDR" }}'
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

          # Socket configuration (avoid permission issues)
          unix_socket_directories = '/tmp'
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

      # Container environment with temporary bootstrap password
      env {
        PGHOST_ADDR       = "0.0.0.0"
        POSTGRES_USER     = "postgres"
        POSTGRES_PASSWORD = "temporary-bootstrap-password"
        PGDATA            = "/var/lib/postgresql/data/pgdata"
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
          name     = "postgres-tcp" # Add descriptive name
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
          port     = "db" # Add explicit port reference
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
      lifecycle {
        hook = "poststart"
      }
      config {
        image        = "postgres:16-alpine"
        network_mode = "host"
        command      = "sh"
        args         = ["/local/create-db.sh"]
      }

      template {
        destination = "local/init.sql"
        data        = <<-EOT
          -- Create PowerDNS user if it doesn't exist
          DO
          $do$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pdns') THEN
               CREATE USER pdns WITH PASSWORD 'temporary-pdns-password';
            END IF;
          END
          $do$;

          -- Create netdata monitoring user if it doesn't exist
          DO
          $do$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'netdata') THEN
               CREATE USER netdata WITH PASSWORD 'netdata_readonly_pass';
            END IF;
          END
          $do$;

          -- Grant minimal privileges to netdata user
          GRANT CONNECT ON DATABASE postgres TO netdata;
          GRANT USAGE ON SCHEMA public TO netdata;
          GRANT SELECT ON ALL TABLES IN SCHEMA public TO netdata;

          -- Create vault management user if it doesn't exist
          DO
          $do$
          BEGIN
            IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'vaultuser') THEN
               CREATE USER vaultuser WITH CREATEDB CREATEROLE LOGIN PASSWORD 'vaultpass';
            END IF;
          END
          $do$;
        EOT
      }

      template {
        destination = "local/create-db.sh"
        data        = <<-EOT
          #!/bin/sh

          # Wait for PostgreSQL to be ready
          until pg_isready -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres; do sleep 1; done

          # First, create the user and database
          psql -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres -f /local/init.sql

          # Check if database exists, create if not
          if ! psql -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres -lqt | cut -d \| -f 1 | grep -qw powerdns; then
            echo "Creating powerdns database..."
            createdb -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres -O pdns powerdns
          fi

          # Apply the PowerDNS schema
          psql -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres -d powerdns -f /local/powerdns-schema.sql

          # Grant vaultuser permissions on PowerDNS database
          echo "Granting vaultuser permissions on PowerDNS database..."
          psql -h 127.0.0.1 -p ${NOMAD_PORT_db} -U postgres -d powerdns -c \
            "GRANT SELECT, INSERT, UPDATE, DELETE ON domains, records, supermasters, comments, domainmetadata, cryptokeys, tsigkeys TO vaultuser WITH GRANT OPTION;
             GRANT SELECT, USAGE ON domains_id_seq, records_id_seq, comments_id_seq, domainmetadata_id_seq, cryptokeys_id_seq, tsigkeys_id_seq TO vaultuser WITH GRANT OPTION;"

          echo "PowerDNS database initialization complete"
        EOT
      }

      template {
        destination = "local/powerdns-schema.sql"
        data        = <<-EOT
          -- PowerDNS PostgreSQL schema
          -- Based on: https://doc.powerdns.com/authoritative/backends/generic-postgresql.html

          -- Main domains table
          CREATE TABLE IF NOT EXISTS domains (
            id                    SERIAL PRIMARY KEY,
            name                  VARCHAR(255) NOT NULL,
            master                VARCHAR(128) DEFAULT NULL,
            last_check            INT DEFAULT NULL,
            type                  VARCHAR(6) NOT NULL,
            notified_serial       INT DEFAULT NULL,
            account               VARCHAR(40) DEFAULT NULL,
            options               TEXT DEFAULT NULL,
            catalog               VARCHAR(255) DEFAULT NULL
          );
          CREATE UNIQUE INDEX IF NOT EXISTS name_index ON domains(name);

          -- Records table
          CREATE TABLE IF NOT EXISTS records (
            id                    BIGSERIAL PRIMARY KEY,
            domain_id             INT DEFAULT NULL,
            name                  VARCHAR(255) DEFAULT NULL,
            type                  VARCHAR(10) DEFAULT NULL,
            content               TEXT DEFAULT NULL,
            ttl                   INT DEFAULT NULL,
            prio                   INT DEFAULT NULL,
            change_date           INT DEFAULT NULL,
            disabled              BOOL DEFAULT 'f',
            ordername             VARCHAR(255),
            auth                  BOOL DEFAULT 't',
            CONSTRAINT domain_exists
              FOREIGN KEY(domain_id) REFERENCES domains(id) ON DELETE CASCADE
          );

          CREATE INDEX IF NOT EXISTS records_name_index ON records(name);
          CREATE INDEX IF NOT EXISTS nametype_index ON records(name,type);
          CREATE INDEX IF NOT EXISTS domain_id ON records(domain_id);
          CREATE INDEX IF NOT EXISTS recordorder ON records (domain_id, ordername text_pattern_ops);

          -- Supermasters table
          CREATE TABLE IF NOT EXISTS supermasters (
            ip                    INET NOT NULL,
            nameserver            VARCHAR(255) NOT NULL,
            account               VARCHAR(40) NOT NULL,
            PRIMARY KEY (ip, nameserver)
          );

          -- Comments table
          CREATE TABLE IF NOT EXISTS comments (
            id                    SERIAL PRIMARY KEY,
            domain_id             INT NOT NULL,
            name                  VARCHAR(255) NOT NULL,
            type                  VARCHAR(10) NOT NULL,
            modified_at           INT NOT NULL,
            account               VARCHAR(40) DEFAULT NULL,
            comment               TEXT NOT NULL,
            CONSTRAINT domain_exists_comments
              FOREIGN KEY(domain_id) REFERENCES domains(id) ON DELETE CASCADE
          );

          CREATE INDEX IF NOT EXISTS comments_name_type_idx ON comments (name, type);
          CREATE INDEX IF NOT EXISTS comments_order_idx ON comments (domain_id, modified_at);

          -- Domain metadata table
          CREATE TABLE IF NOT EXISTS domainmetadata (
            id                    SERIAL PRIMARY KEY,
            domain_id             INT NOT NULL,
            kind                  VARCHAR(32),
            content               TEXT,
            CONSTRAINT domain_exists_metadata
              FOREIGN KEY(domain_id) REFERENCES domains(id) ON DELETE CASCADE
          );

          CREATE INDEX IF NOT EXISTS domainmetadata_idx ON domainmetadata (domain_id, kind);

          -- Cryptographic keys for DNSSEC
          CREATE TABLE IF NOT EXISTS cryptokeys (
            id                    SERIAL PRIMARY KEY,
            domain_id             INT NOT NULL,
            flags                 INT NOT NULL,
            active                BOOL,
            published             BOOL DEFAULT TRUE,
            content               TEXT,
            CONSTRAINT domain_exists_cryptokeys
              FOREIGN KEY(domain_id) REFERENCES domains(id) ON DELETE CASCADE
          );

          CREATE INDEX IF NOT EXISTS domainidindex ON cryptokeys(domain_id);

          -- TSIG keys
          CREATE TABLE IF NOT EXISTS tsigkeys (
            id                    SERIAL PRIMARY KEY,
            name                  VARCHAR(255),
            algorithm             VARCHAR(50),
            secret                VARCHAR(255)
          );

          CREATE UNIQUE INDEX IF NOT EXISTS namealgoindex ON tsigkeys(name, algorithm);

          -- Grant permissions to PowerDNS user (pdns)
          GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO pdns;
          GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO pdns;
          GRANT USAGE ON SCHEMA public TO pdns;

          -- Set default privileges for future tables
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO pdns;
          ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO pdns;
        EOT
      }

      env {
        PGPASSWORD = "temporary-bootstrap-password"
      }


      resources {
        cpu    = 50
        memory = 128
      }
    }
  }
}
