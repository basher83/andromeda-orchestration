job "powerdns-test" {
  datacenters = ["dc1"]
  type        = "service"
  
  group "powerdns" {
    count = 1
    
    network {
      port "dns" {
        static = 5353  # Test port to avoid conflict
        to     = 53
      }
      port "api" {}
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
      }
      
      volume_mount {
        volume      = "powerdns-mysql"
        destination = "/var/lib/mysql"
      }
      
      env {
        MYSQL_ROOT_PASSWORD = "testpassword123"
        MYSQL_DATABASE      = "powerdns"
        MYSQL_USER          = "powerdns"
        MYSQL_PASSWORD      = "testpdnspass456"
      }
      
      resources {
        cpu    = 500
        memory = 512
      }
      
      # Service registration WITH identity block (REQUIRED)
      service {
        name = "powerdns-test-mysql"
        port = "mysql"
        
        identity {
          aud = ["consul.io"]
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
      }
      
      env {
        PDNS_api      = "yes"
        PDNS_api_key  = "testkey789"
        PDNS_webserver = "yes"
        PDNS_webserver_address = "0.0.0.0"
        PDNS_webserver_allow_from = "0.0.0.0/0"
        PDNS_launch = "gmysql"
        PDNS_gmysql_host = "${NOMAD_ADDR_mysql}"
        PDNS_gmysql_port = "${NOMAD_PORT_mysql}"
        PDNS_gmysql_user = "powerdns"
        PDNS_gmysql_password = "testpdnspass456"
        PDNS_gmysql_dbname = "powerdns"
        PDNS_default_soa_content = "ns1.lab.local hostmaster.lab.local 1 10800 3600 604800 3600"
      }
      
      resources {
        cpu    = 500
        memory = 256
      }
      
      # Service registrations WITH identity blocks (REQUIRED)
      service {
        name = "powerdns-test-dns"
        port = "dns"
        
        identity {
          aud = ["consul.io"]
        }
        
        check {
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }
      
      service {
        name = "powerdns-test-api"
        port = "api"
        
        identity {
          aud = ["consul.io"]
        }
        
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.powerdns-test.rule=Host(`powerdns-test.lab.local`)",
          "traefik.http.routers.powerdns-test.entrypoints=websecure",
          "traefik.http.routers.powerdns-test.tls=true",
        ]
        
        check {
          type     = "http"
          path     = "/api/v1/servers"
          interval = "10s"
          timeout  = "2s"
          header {
            X-API-Key = ["testkey789"]
          }
        }
      }
    }
  }
}