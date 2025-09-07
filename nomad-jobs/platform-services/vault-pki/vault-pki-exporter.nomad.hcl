variable "VAULT_PKI_MONITOR_TOKEN" {
  type        = string
  description = "Vault token for PKI monitoring - injected from Infisical"
  default     = ""
}

job "vault-pki-exporter" {
  datacenters = ["dc1"]
  type        = "system"  # Runs on all nodes

  group "exporter" {
    count = 1

    network {
      port "metrics" {
        static = 9333
        to     = 9333
      }
    }

    service {
      name     = "vault-pki-exporter"
      provider = "consul"
      port     = "metrics"
      tags     = ["metrics", "prometheus", "vault", "pki"]

      identity {
        aud = ["consul.io"]
        ttl = "1h"
      }

      check {
        type     = "http"
        path     = "/metrics"
        interval = "30s"
        timeout  = "5s"
      }

      meta {
        metrics_path = "/metrics"
        job          = "vault-pki-exporter"
      }
    }

    task "exporter" {
      driver = "docker"

      config {
        image = "ghcr.io/aarnaud/vault-pki-exporter:latest"
        ports = ["metrics"]

        command = "./vault-pki-exporter"
        args = [
          "--fetch-interval=5m",
          "--refresh-interval=5m",
          "--log-level=info",
          "--port=9333",
        ]
      }

      env {
        VAULT_ADDR  = "https://192.168.10.31:8200"  # vault-prod-1-holly
        VAULT_SKIP_VERIFY = "true"  # Skip TLS verification for self-signed certs
        # Token injected via environment variable at job submission time
        # Deploy with: infisical run --env=prod --path="/apollo-13/vault" -- nomad job run vault-pki-exporter.nomad.hcl
        VAULT_TOKEN = "${var.VAULT_PKI_MONITOR_TOKEN}"
      }

      resources {
        cpu    = 100
        memory = 64
      }

      restart {
        attempts = 3
        interval = "5m"
        delay    = "30s"
        mode     = "fail"
      }
    }
  }

  update {
    max_parallel     = 1
    health_check     = "checks"
    min_healthy_time = "30s"
    healthy_deadline = "5m"
    progress_deadline = "10m"
    auto_revert      = true
    auto_promote     = false
    canary           = 0
  }
}
