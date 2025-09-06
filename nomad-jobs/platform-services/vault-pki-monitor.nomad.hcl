job "vault-pki-monitor" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "batch"

  periodic {
    crons            = ["0 */6 * * *"]  # Run every 6 hours
    prohibit_overlap = true
    time_zone        = "UTC"
  }

  group "monitor" {
    count = 1

    task "check-certificates" {
      driver = "docker"

      config {
        image   = "cytopia/ansible:latest-tools"
        command = "/bin/sh"
        args = [
          "-c",
          "git clone https://github.com/basher83/andromeda-orchestration.git /tmp/andromeda && cd /tmp/andromeda && ansible-playbook playbooks/infrastructure/vault/monitor-pki-certificates.yml -i inventory/environments/vault-cluster/production.yaml"
        ]
      }

      env {
        ANSIBLE_HOST_KEY_CHECKING = "False"
        VAULT_ADDR                = "https://vault-prod-1-holly.service.consul:8200"
        VAULT_SKIP_VERIFY         = "false"
      }

      # Infisical authentication is handled via environment variables
      # set on the Nomad client hosts. The ansible playbook will use
      # these to retrieve secrets from Infisical.

      resources {
        cpu    = 500
        memory = 512
      }

      logs {
        max_files     = 3
        max_file_size = 10
      }
    }

    task "alert-on-expiry" {
      driver = "docker"

      lifecycle {
        hook    = "poststop"
        sidecar = false
      }

      config {
        image   = "curlimages/curl:latest"
        command = "/bin/sh"
        args    = ["-c", "echo 'Certificate monitoring complete'"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }

    # Restart policy for the group
    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }
  }
}
