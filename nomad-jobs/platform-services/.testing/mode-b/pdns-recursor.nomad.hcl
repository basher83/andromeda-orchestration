job "powerdns-recursor" {
  datacenters = ["dc1"]
  type        = "service"

  group "recursor" {
    count = 2

    network {
      mode = "host"
      port "dns" { to = 5300 }
      port "web" {} # optional web interface (read-only)
    }

    task "recursor" {
      driver = "docker"
      config {
        image        = "powerdns/pdns-recursor-49:latest"
        args         = ["--config-dir=/local"]
        network_mode = "host"
      }

      template {
        destination   = "local/recursor.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data = <<-EOT
          local-address=0.0.0.0
          local-port=5300

          # Optional web status
          webserver=yes
          webserver-address=0.0.0.0
          webserver-port={{ env "NOMAD_PORT_web" }}
          webserver-allow-from=0.0.0.0/0

          # Upstreams (tweak to your infra)
          forward-zones-recurse=.=1.1.1.1;9.9.9.9

          dnssec=validate
          loglevel=4
        EOT
      }

      service {
        name = "powerdns-recursor-backend"
        port = "dns"
        tags = ["udp","tcp"]
        check { name="tcp5300", type="tcp", interval="10s", timeout="2s" }
      }

      resources { cpu=200, memory=256 }
    }

    affinity { attribute="${node.unique.id}", operator="distinct_hosts", weight=100 }
  }
}
