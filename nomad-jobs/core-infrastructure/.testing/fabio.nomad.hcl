job "fabio" {
  datacenters = ["dc1"]
  type = "system"  // Deploy on all client nodes

  group "fabio" {
    network {
      mode = "host"
      port "http" {
        static = 9999
      }
      port "admin" {
        static = 9998
      }
    }

    # Add a restart policy for production stability
    restart {
      attempts = 3
      interval = "5m"
      delay = "15s"
      mode = "delay"
    }

    task "fabio" {
      driver = "docker"

      config {
        image = "fabiolb/fabio:${var.fabio_version}"
        ports = ["http", "admin"]
        volumes = [
          "local/fabio.properties:/etc/fabio/fabio.properties",
          "/mnt/nomad-volumes/fabio:/var/fabio",
          "/etc/ssl/certs:/etc/ssl/certs:ro"
        ]
      }

      # Use a properties file for configuration
      template {
        data = <<EOH
# Fabio Configuration
proxy.addr = :${var.fabio_http_port};proto=http
ui.addr = :${var.fabio_admin_port}
registry.consul.addr = ${var.consul_service_name}:8500
registry.consul.register.name = fabio
registry.consul.register.addr = ${NOMAD_IP_http}:${NOMAD_PORT_http}
registry.consul.register.tags = ${var.fabio_tags}
registry.consul.refresh = ${var.fabio_consul_refresh}
proxy.strategy = ${var.fabio_proxy_strategy}
proxy.maxconn = ${var.fabio_max_conn}
proxy.dialtimeout = ${var.fabio_dial_timeout}
proxy.readtimeout = ${var.fabio_read_timeout}
proxy.writetimeout = ${var.fabio_write_timeout}
metrics.target = ${var.fabio_metrics_target}
metrics.prefix = ${var.fabio_metrics_prefix}
metrics.interval = ${var.fabio_metrics_interval}
ui.title = ${var.fabio_ui_title}
log.access.target = stdout

# Custom Routes
${var.fabio_routes}
EOH
        destination = "local/fabio.properties"
        change_mode = "signal"
        change_signal = "SIGHUP"
      }

      resources {
        cpu    = var.fabio_cpu
        memory = var.fabio_memory
      }

      service {
        name = "fabio"
        port = "http"
        tags = ["${var.fabio_tags}"]

        check {
          name     = "fabio-admin-check"
          type     = "http"
          port     = "admin"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
