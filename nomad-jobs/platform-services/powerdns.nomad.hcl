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
        to = 8081  # PowerDNS API port inside container
      }
      port "mysql" {
        to = 3306
      }
    }

    volume "powerdns-mysql" {
      type      = "host"
      source    = "powerdns-mysql"
      read_only = false
    }

    task "mysql" {
      driver = "docker"

      config {
        image = "mariadb:10"
        ports = ["mysql"]
        volumes = [
          "local/init.sql:/docker-entrypoint-initdb.d/init.sql"
        ]
      }

      volume_mount {
        volume      = "powerdns-mysql"
        destination = "/var/lib/mysql"
      }

      template {
        data = <<EOF
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

CREATE UNIQUE INDEX IF NOT EXISTS name_index ON domains(name);

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

CREATE INDEX IF NOT EXISTS nametype_index ON records(name,type);
CREATE INDEX IF NOT EXISTS domain_id ON records(domain_id);
CREATE INDEX IF NOT EXISTS ordername ON records (ordername);

CREATE TABLE IF NOT EXISTS supermasters (
  ip                    VARCHAR(64) NOT NULL,
  nameserver            VARCHAR(255) NOT NULL,
  account               VARCHAR(40) CHARACTER SET 'utf8' NOT NULL,
  PRIMARY KEY (ip, nameserver)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE TABLE IF NOT EXISTS comments (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  name                  VARCHAR(255) NOT NULL,
  type                  VARCHAR(10) NOT NULL,
  modified_at           INT NOT NULL,
  account               VARCHAR(40) CHARACTER SET 'utf8' DEFAULT NULL,
  comment               TEXT CHARACTER SET 'utf8' NOT NULL,
  PRIMARY KEY (id)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE INDEX IF NOT EXISTS comments_name_type_idx ON comments (name, type);
CREATE INDEX IF NOT EXISTS comments_order_idx ON comments (domain_id, modified_at);

CREATE TABLE IF NOT EXISTS domainmetadata (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  kind                  VARCHAR(32),
  content               TEXT,
  PRIMARY KEY (id)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE INDEX IF NOT EXISTS domainmetadata_idx ON domainmetadata (domain_id, kind);

CREATE TABLE IF NOT EXISTS cryptokeys (
  id                    INT AUTO_INCREMENT,
  domain_id             INT NOT NULL,
  flags                 INT NOT NULL,
  active                BOOL,
  published             BOOL DEFAULT 1,
  content               TEXT,
  PRIMARY KEY(id)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE INDEX IF NOT EXISTS domainidindex ON cryptokeys(domain_id);

CREATE TABLE IF NOT EXISTS tsigkeys (
  id                    INT AUTO_INCREMENT,
  name                  VARCHAR(255),
  algorithm             VARCHAR(50),
  secret                VARCHAR(255),
  PRIMARY KEY (id)
) Engine=InnoDB CHARACTER SET 'latin1';

CREATE UNIQUE INDEX IF NOT EXISTS namealgoindex ON tsigkeys(name, algorithm);

GRANT ALL ON powerdns.* TO 'root'@'%' IDENTIFIED BY 'supersecurepassword123';
FLUSH PRIVILEGES;
EOF
        destination = "local/init.sql"
      }

      env {
        MYSQL_ROOT_PASSWORD = "supersecurepassword123"
        MYSQL_DATABASE      = "powerdns"
        MYSQL_USER          = "powerdns"
        MYSQL_PASSWORD      = "pdnspassword456"
      }

      resources {
        cpu    = 500
        memory = 512
      }

      service {
        name = "powerdns-mysql"
        port = "mysql"

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
    }

    task "powerdns" {
      driver = "docker"

      config {
        image = "powerdns/pdns-auth-48:latest"
        ports = ["dns", "api"]
        volumes = [
          "local/pdns.conf:/etc/powerdns/pdns.conf"
        ]
      }

      template {
        data = <<EOF
local-address=0.0.0.0,::
launch=gmysql
gmysql-host={{ env "NOMAD_IP_mysql" }}
gmysql-port={{ env "NOMAD_HOST_PORT_mysql" }}
gmysql-user=root
gmysql-password=supersecurepassword123
gmysql-dbname=powerdns
webserver=yes
webserver-address=0.0.0.0
webserver-port=8081
webserver-allow-from=0.0.0.0/0
api=yes
api-key=changeme789xyz
default-soa-content=ns1.lab.local hostmaster.lab.local 1 10800 3600 604800 3600
EOF
        destination = "local/pdns.conf"
      }

      env {
        # API Configuration
        PDNS_api = "yes"
        PDNS_api_key = "changeme789xyz"

        # Webserver Configuration
        PDNS_webserver = "yes"
        PDNS_webserver_address = "0.0.0.0"
        PDNS_webserver_port = "${NOMAD_PORT_api}"
        PDNS_webserver_allow_from = "0.0.0.0/0"

        # MySQL Backend Configuration
        PDNS_launch = "gmysql"
        PDNS_gmysql_host = "${NOMAD_ADDR_mysql}"
        PDNS_gmysql_port = "${NOMAD_PORT_mysql}"
        PDNS_gmysql_user = "powerdns"
        PDNS_gmysql_password = "pdnspassword456"
        PDNS_gmysql_dbname = "powerdns"

        # Default SOA
        PDNS_default_soa_content = "ns1.lab.local hostmaster.lab.local 1 10800 3600 604800 3600"
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
          "traefik.enable=true",
          "traefik.http.routers.powerdns.rule=Host(`powerdns.lab.local`)",
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
