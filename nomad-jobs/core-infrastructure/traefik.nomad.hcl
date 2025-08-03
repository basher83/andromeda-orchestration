job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      mode = "host"  # Required to bind to host ports 80/443
      
      port "http" {
        static = 80
      }
      
      port "https" {
        static = 443
      }
      
      port "admin" {
        to = 8080  # Dashboard on dynamic port
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v3.0"
        ports = ["http", "https", "admin"]
        
        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml",
          "local/dynamic:/etc/traefik/dynamic",
          "traefik-certs:/certs"
        ]
      }

      template {
        data = <<EOF
# Static configuration
api:
  dashboard: true
  debug: false

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  
  websecure:
    address: ":443"

providers:
  # File provider for static configs
  file:
    directory: /etc/traefik/dynamic
    watch: true
  
  # Consul Catalog for service discovery
  consulCatalog:
    endpoint:
      address: {{ env "CONSUL_HTTP_ADDR" | default "consul.service.consul:8500" }}
      scheme: http
    exposedByDefault: false
    prefix: traefik
    watch: true

# Enable Consul KV for dynamic config (optional)
# providers:
#   consul:
#     endpoints:
#       - "{{ env "CONSUL_HTTP_ADDR" | default "consul.service.consul:8500" }}"
#     prefix: traefik

ping:
  entryPoint: admin

log:
  level: INFO

accessLog: {}

metrics:
  prometheus:
    entryPoint: admin
    addEntryPointsLabels: true
    addServicesLabels: true
EOF
        destination = "local/traefik.yml"
      }

      # Dynamic configuration for self-signed cert (initial setup)
      template {
        data = <<EOF
tls:
  stores:
    default:
      defaultGeneratedCert:
        resolver: default
        domain:
          main: "lab.local"
          sans:
            - "*.lab.local"
            - "*.doggos.lab.local"
            - "*.service.consul"
EOF
        destination = "local/dynamic/certs.yml"
      }

      resources {
        cpu    = 200
        memory = 256
      }

      service {
        name = "traefik"
        port = "admin"
        
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.api.rule=Host(`traefik.lab.local`)",
          "traefik.http.routers.api.service=api@internal",
          "traefik.http.routers.api.entrypoints=websecure",
          "traefik.http.routers.api.tls=true",
        ]
        
        check {
          type     = "http"
          path     = "/ping"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "traefik-http"
        port = "http"
      }

      service {
        name = "traefik-https"
        port = "https"
      }
    }

    # Volume for certificate storage
    volume "traefik-certs" {
      type      = "host"
      read_only = false
      source    = "traefik-certs"
    }
  }
}