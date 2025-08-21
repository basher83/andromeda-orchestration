variable "homelab_domain" {
  type        = string
  default     = "spaceships.work"
  description = "The domain for the homelab environment"
}

job "traefik" {
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      mode = "host" # Required to bind to host ports 80/443

      port "http" {
        static = 80
      }

      port "https" {
        static = 443
      }

      port "admin" {
        to = 8080 # Dashboard on dynamic port
      }
    }

    # Volume for certificate storage - MOVED TO GROUP LEVEL
    volume "traefik-certs" {
      type      = "host"
      read_only = false
      source    = "traefik-certs"
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

      env {
        CONSUL_HTTP_ADDR = "${attr.unique.consul.name}.node.consul:8500"
      }

      template {
        data        = <<EOF
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

  admin:
    address: ":8080"

providers:
  # File provider for static configs
  file:
    directory: /etc/traefik/dynamic
    watch: true

  # Consul Catalog for service discovery
  consulCatalog:
    endpoint:
      address: {{ if env "CONSUL_HTTP_ADDR" }}{{ env "CONSUL_HTTP_ADDR" }}{{ else }}consul.service.consul:8500{{ end }}
      scheme: http
    exposedByDefault: false
    prefix: traefik
    watch: true

# Enable Consul KV for dynamic config (optional)
# providers:
#   consul:
#     endpoints:
#       - "consul.service.consul:8500"
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
        data        = <<EOF
tls:
  stores:
    default:
      defaultGeneratedCert:
        resolver: default
        domain:
          main: "${var.homelab_domain}"
          sans:
            - "*.${var.homelab_domain}"
            - "*.doggos.${var.homelab_domain}"
            - "*.service.consul"
EOF
        destination = "local/dynamic/certs.yml"
      }

      resources {
        cpu    = 200
        memory = 256
      }

      # Main admin/API service
      service {
        name = "traefik"
        port = "admin"

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.api.rule=Host(`traefik.${var.homelab_domain}`)",
          "traefik.http.routers.api.service=api@internal",
          "traefik.http.routers.api.entrypoints=websecure",
          "traefik.http.routers.api.tls=true",
          "prometheus",
          "metrics",
        ]

        check {
          name     = "traefik-api-ping"
          type     = "http"
          path     = "/ping"
          port     = "admin"
          interval = "10s"
          timeout  = "2s"
        }

        check {
          name     = "traefik-dashboard"
          type     = "http"
          path     = "/dashboard/"
          port     = "admin"
          interval = "30s"
          timeout  = "5s"
        }
      }

      # HTTP entrypoint service
      service {
        name = "traefik-http"
        port = "http"

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        tags = ["entrypoint", "http"]

        check {
          name     = "http-entrypoint"
          type     = "tcp"
          port     = "http"
          interval = "10s"
          timeout  = "2s"
        }
      }

      # HTTPS entrypoint service
      service {
        name = "traefik-https"
        port = "https"

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        tags = ["entrypoint", "https", "tls"]

        check {
          name     = "https-entrypoint"
          type     = "tcp"
          port     = "https"
          interval = "10s"
          timeout  = "2s"
        }
      }

      # Dedicated metrics service for Prometheus
      service {
        name = "traefik-metrics"
        port = "admin"

        identity {
          aud = ["consul.io"]
          ttl = "1h"
        }

        tags = [
          "prometheus",
          "metrics",
          "path:/metrics",
        ]

        check {
          name     = "prometheus-metrics"
          type     = "http"
          path     = "/metrics"
          port     = "admin"
          interval = "30s"
          timeout  = "5s"
        }
      }
    } # CLOSE TASK BLOCK
  }   # CLOSE GROUP BLOCK
}     # CLOSE JOB BLOCK
