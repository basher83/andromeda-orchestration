job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      mode = "host"
      
      port "http" {
        static = 80
      }
      
      port "https" {
        static = 443
      }
      
      port "admin" {
        to = 8080
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v3.0"
        ports = ["http", "https", "admin"]
        
        volumes = [
          "local/traefik.yml:/etc/traefik/traefik.yml"
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
  # Consul Catalog for service discovery
  consulCatalog:
    endpoint:
      address: consul.service.consul:8500
      scheme: http
    exposedByDefault: false
    prefix: traefik
    watch: true

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

      resources {
        cpu    = 100
        memory = 128
      }

      # Register services WITHOUT identity blocks
      service {
        name = "traefik"
        port = "admin"
        tags = [
          "traefik.enable=true",
          "traefik.http.routers.api.rule=Host(`traefik.lab.local`)",
          "traefik.http.routers.api.service=api@internal",
          "traefik.http.routers.api.entrypoints=websecure",
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
  }
}