job "test-cni-bridge" {
  datacenters = ["dc1"]
  type = "service"

  group "test" {
    network {
      mode = "bridge"

      port "http" {
        to = 80
      }
    }

    service {
      name = "test-nginx"
      port = "http"

      connect {
        sidecar_service {}
      }

      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "nginx:alpine"
        ports = ["http"]
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }
  }
}
