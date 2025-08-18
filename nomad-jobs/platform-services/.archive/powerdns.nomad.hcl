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
        to = 8081 # Dynamic port allocation
      }
      port "mysql" {
        to = 3306
      }
    }

    task "mariadb" {
      driver = "docker"

      config {
        image = "mariadb:10.11"
        ports = ["mysql"]

        volumes = [
          "local/mysql-init:/docker-entrypoint-initdb.d",
          "powerdns-mysql:/var/lib/mysql"
        ]
      }

      # Secrets should be injected via Consul KV or Nomad variables
      template {
        data        = <<EOF
MYSQL_ROOT_PASSWORD={{ keyOrDefault "powerdns/mysql/root_password" "" }}
MYSQL_DATABASE=powerdns
MYSQL_USER=powerdns
MYSQL_PASSWORD={{ keyOrDefault "powerdns/mysql/password" "" }}
EOF
        destination = "secrets/mysql.env"
        env         = true
      }

      template {
        data        = <<EOF
CREATE TABLE IF NOT EXISTS domains (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255) NOT NULL,
  master                VARCHAR(128) DEFAULT NULL,
  last_check            INT DEFAULT NULL,
  type                  VARCHAR(8) NOT NULL,
  notified_serial       INT UNSIGNED DEFAULT NULL,
  account               VARCHAR(40) CHARACTER SET 'utf8' DEFAULT NULL,
  PRIMARY KEY (id)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE UNIQUE INDEX name_index ON domains(name);

CREATE TABLE IF NOT EXISTS records (
  id                    BIGINT AUTO_INCREMENT,
  domain_id             INT DEFAULT NULL,
  name                  VARCHAR(255) DEFAULT NULL,
  type                  VARCHAR(10) DEFAULT NULL,
  content               VARCHAR(64000) DEFAULT NULL,
  ttl                   INT DEFAULT NULL,
  prio                  INT DEFAULT NULL,
  disabled              TINYINT(1) DEFAULT 0,
  ordername             VARCHAR(255) BINARY DEFAULT NULL,
  auth                  TINYINT(1) DEFAULT 1,
  PRIMARY KEY (id)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE INDEX nametype_index ON records(name,type);
CREATE INDEX domain_id ON records(domain_id);
CREATE INDEX ordername ON records (ordername);
EOF
        destination = "local/mysql-init/schema.sql"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "powerdns-mysql"
        port = "mysql"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }

    task "powerdns" {
      driver = "docker"

      config {
        image = "powerdns/pdns-auth-48:latest"
        ports = ["dns", "api"]
      }

      # API key and database password from Consul KV
      template {
        data        = <<EOF
PDNS_LAUNCH=gmysql
PDNS_GMYSQL_HOST=${NOMAD_ADDR_mysql}
PDNS_GMYSQL_PORT=${NOMAD_PORT_mysql}
PDNS_GMYSQL_USER=powerdns
PDNS_GMYSQL_PASSWORD={{ keyOrDefault "powerdns/mysql/password" "" }}
PDNS_GMYSQL_DBNAME=powerdns
PDNS_API=yes
PDNS_API_KEY={{ keyOrDefault "powerdns/api/key" "" }}
PDNS_WEBSERVER=yes
PDNS_WEBSERVER_ADDRESS=0.0.0.0
PDNS_WEBSERVER_ALLOW_FROM=0.0.0.0/0
EOF
        destination = "secrets/powerdns.env"
        env         = true
      }

      resources {
        cpu    = 500
        memory = 256
      }

      service {
        name = "powerdns"
        port = "dns"

        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "powerdns-api"
        port = "api"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.powerdns.rule=Host(`powerdns.lab.local`)",
          "traefik.http.routers.powerdns.entrypoints=websecure",
          "traefik.http.routers.powerdns.tls=true",
          "traefik.http.services.powerdns.loadbalancer.server.port=${NOMAD_PORT_api}",
        ]

        check {
          type = "http"
          path = "/api/v1/servers"
          header {
            X-API-Key = ["{{ keyOrDefault \"powerdns/api/key\" \"\" }}"]
          }
          interval = "30s"
          timeout  = "5s"
        }
      }
    }

    # Volume for MySQL data persistence
    volume "powerdns-mysql" {
      type      = "host"
      read_only = false
      source    = "powerdns-mysql"
    }
  }
}
