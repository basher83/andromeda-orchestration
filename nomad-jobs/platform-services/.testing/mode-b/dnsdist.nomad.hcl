job "dnsdist" {
  datacenters = ["dc1"]
  type        = "service"

  group "edge" {
    count = 2

    network {
      mode = "host"
      port "dns" {}
      port "api" {} # optional console API if you want to manage remotely
    }

    task "dnsdist" {
      driver = "docker"
      config {
        image        = "powerdns/dnsdist-19:latest"
        args         = ["--supervised", "--disable-syslog", "--config", "/local/dnsdist.conf"]
        network_mode = "host"
        cap_add      = ["NET_BIND_SERVICE"]
      }

      env {
        BIND_ADDR = "0.0.0.0"
      }

      template {
        destination   = "local/dnsdist.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<-EOT
          setLocal("${BIND_ADDR}:53")
          setACL({"0.0.0.0/0"})  -- tighten to your subnets later

          -- Backends discovered via Consul SRV (or static if you prefer)
          -- For simplicity, use static for first deploy; swap to SRV later.
          newServer({address="127.0.0.1:5300", pool="recursor"})
          newServer({address="127.0.0.1:5301", pool="auth"})

          -- Policy:
          -- - If RD bit set → recursor
          -- - If qname matches an authoritative zone → auth
          -- In practice, load zones list dynamically; here's a starter:
          addAction("example.lab.", PoolAction("auth"))
          addAction(AllRule(), PoolAction("recursor"))
        EOT
      }

      service {
        name = "dnsdist"
        port = "dns"
        tags = ["udp", "tcp"]
        check {
          name     = "tcp53"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 200
        memory = 256
      }
    }

    # :53 static
    network {
      mode = "host"
      port "dns" {
        static = 53
        to     = 53
      }
    }

    affinity {
      attribute = "${node.unique.id}"
      operator  = "distinct_hosts"
      weight    = 100
    }
  }
}
