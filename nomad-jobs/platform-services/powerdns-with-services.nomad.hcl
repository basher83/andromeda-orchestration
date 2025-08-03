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
        to = 8081
      }
      port "mysql" {
        to = 3306
      }
    }

    service {
      name = "powerdns"
      port = "dns"
      
      tags = [
        "dns",
        "authoritative",
      ]
      
      check {
        type     = "tcp"
        port     = "dns"
        interval = "10s"
        timeout  = "2s"
      }
      
      # Service identity configuration
      identity {
        aud = ["consul.io"]
      }
    }

    service {
      name = "powerdns-api"
      port = "api"
      
      tags = [
        "api",
        "rest",
      ]
      
      check {
        type     = "http"
        path     = "/api/v1/servers"
        port     = "api"
        interval = "30s"
        timeout  = "5s"
        header {
          X-API-Key = ["${PDNS_API_KEY}"]
        }
      }
      
      identity {
        aud = ["consul.io"]
      }
    }

    service {
      name = "powerdns-mysql"
      port = "mysql"
      
      tags = [
        "database",
        "mysql",
        "internal",
      ]
      
      check {
        type     = "tcp"
        port     = "mysql"
        interval = "10s"
        timeout  = "2s"
      }
      
      identity {
        aud = ["consul.io"]
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

      template {
        data = <<EOF
MYSQL_ROOT_PASSWORD={{ keyOrDefault "powerdns/mysql/root_password" "default_root_pass" }}
MYSQL_DATABASE=powerdns
MYSQL_USER=powerdns
MYSQL_PASSWORD={{ keyOrDefault "powerdns/mysql/password" "default_pass" }}
EOF
        destination = "secrets/mysql.env"
        env         = true
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
    }

    task "powerdns" {
      driver = "docker"

      config {
        image = "powerdns/pdns-auth-48:latest"
        ports = ["dns", "api"]
      }

      template {
        data = <<EOF
PDNS_LAUNCH=gmysql
PDNS_GMYSQL_HOST=${NOMAD_ADDR_mysql}
PDNS_GMYSQL_PORT=${NOMAD_PORT_mysql}
PDNS_GMYSQL_USER=powerdns
PDNS_GMYSQL_PASSWORD={{ keyOrDefault "powerdns/mysql/password" "default_pass" }}
PDNS_GMYSQL_DBNAME=powerdns
PDNS_API=yes
PDNS_API_KEY={{ keyOrDefault "powerdns/api/key" "default_api_key" }}
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

      # Service identity will provide Consul token automatically
      identity {
        env = true
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