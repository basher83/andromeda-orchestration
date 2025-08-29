job "vault-pki-monitor" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "batch"

  periodic {
    cron             = "0 */6 * * *"  # Run every 6 hours
    prohibit_overlap = true
    time_zone        = "UTC"
  }

  group "monitor" {
    count = 1

    task "check-certificates" {
      driver = "docker"

      config {
        image   = "cytopia/ansible:latest-tools"
        command = "ansible-playbook"
        args = [
          "/workspace/playbooks/infrastructure/vault/monitor-pki-certificates.yml",
          "-i", "/workspace/inventory/environments/vault-cluster/production.yaml"
        ]
        
        volumes = [
          "/opt/netbox-ansible:/workspace:ro"
        ]
        
        network_mode = "host"
      }

      env {
        ANSIBLE_HOST_KEY_CHECKING = "False"
        VAULT_ADDR                = "https://192.168.10.33:8200"
        VAULT_SKIP_VERIFY         = "false"
      }

      template {
        data = <<EOH
INFISICAL_UNIVERSAL_AUTH_CLIENT_ID={{ with secret "kv/data/infisical/auth" }}{{ .Data.data.client_id }}{{ end }}
INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET={{ with secret "kv/data/infisical/auth" }}{{ .Data.data.client_secret }}{{ end }}
EOH
        destination = "secrets/env.txt"
        env         = true
      }

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
  }

  # Restart policy
  restart {
    attempts = 2
    interval = "30m"
    delay    = "15s"
    mode     = "fail"
  }
}