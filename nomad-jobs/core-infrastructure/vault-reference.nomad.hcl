# HashiCorp Vault - Reference Nomad Job Specification
# WARNING: This is for REFERENCE ONLY - Vault should NOT run as a Nomad job in production
#
# Research findings strongly recommend deploying Vault as a separate service because:
# 1. Vault requires persistent storage and state management
# 2. Unsealing process is complex and not suited for container orchestration
# 3. Vault should be the foundation service that Nomad workloads depend on
# 4. Recovery and backup procedures are more complex in containerized environments
#
# Use the Ansible playbooks in playbooks/infrastructure/vault/ for proper deployment

job "vault-dev-reference" {
  datacenters = ["dc1"]
  type        = "service"

  # WARNING: This job is for development/reference only
  meta {
    warning = "NOT FOR PRODUCTION - Vault should be deployed as a standalone service"
    reference = "See playbooks/infrastructure/vault/ for proper deployment"
  }

  constraint {
    # Only run on nodes explicitly tagged for vault dev testing
    attribute = "${meta.vault_dev_allowed}"
    value     = "true"
  }

  group "vault" {
    count = 1

    # Vault requires stable placement
    constraint {
      operator = "distinct_hosts"
      value    = "true"
    }

    network {
      mode = "host"  # Host networking for Vault

      port "http" {
        static = 8200
      }

      port "cluster" {
        static = 8201
      }
    }

    # Persistent storage - critical for Vault
    volume "vault-data" {
      type      = "host"
      source    = "vault-data"
      read_only = false
    }

    task "vault" {
      driver = "docker"

      # Vault cannot be killed/restarted without data loss in dev mode
      kill_timeout = "30s"

      config {
        image = "hashicorp/vault:1.15.5"
        ports = ["http", "cluster"]

        # Dev mode command - data is lost on restart!
        command = "vault"
        args = [
          "server",
          "-dev",
          "-dev-root-token-id=root",
          "-dev-listen-address=0.0.0.0:8200"
        ]

        # For production, you would mount config and data volumes
        # volumes = [
        #   "local/vault.hcl:/vault/config/vault.hcl",
        #   "vault-data:/vault/data"
        # ]

        # Required for mlock
        cap_add = ["IPC_LOCK"]
      }

      volume_mount {
        volume      = "vault-data"
        destination = "/vault/data"
      }

      env {
        VAULT_DEV_ROOT_TOKEN_ID = "root"
        VAULT_LOG_LEVEL = "debug"
        VAULT_UI = "true"
      }

      # Resources
      resources {
        cpu    = 500
        memory = 256
      }

      # Service registration
      service {
        name = "vault-dev"
        port = "http"
        tags = [
          "vault",
          "dev",
          "reference-only",
          "traefik.enable=true",
          "traefik.http.routers.vault.rule=Host(`vault.service.consul`)"
        ]

        check {
          name     = "vault-health"
          type     = "http"
          path     = "/v1/sys/health"
          interval = "10s"
          timeout  = "5s"

          # Vault health endpoint returns different codes based on state
          # 200 - initialized, unsealed, active
          # 429 - unsealed, standby
          # 472 - data recovery mode
          # 501 - not initialized
          # 503 - sealed
          success_before_passing   = 2
          failures_before_critical = 3
        }
      }

      # Template for basic configuration (not used in dev mode)
      template {
        data = <<EOF
# This configuration would be used for production mode
# Dev mode ignores configuration files

ui = true
disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = true
}

storage "raft" {
  path = "/vault/data"
  node_id = "{{ env "node.unique.name" }}"
}

api_addr = "http://{{ env "NOMAD_IP_http" }}:8200"
cluster_addr = "http://{{ env "NOMAD_IP_cluster" }}:8201"
EOF
        destination = "local/vault.hcl"
        change_mode = "noop"  # Don't restart on change in dev mode
      }
    }
  }
}

# IMPORTANT NOTES:
#
# 1. This job will lose all data when restarted (dev mode uses in-memory storage)
# 2. The root token is hardcoded as "root" - never do this in production
# 3. No TLS is configured - all traffic is unencrypted
# 4. No high availability - single instance only
# 5. No unsealing required in dev mode - but production Vault requires unsealing
#
# For production Vault deployment:
# - Use the Ansible playbooks in playbooks/infrastructure/vault/
# - Deploy Vault as a systemd service on dedicated nodes
# - Configure proper storage backend (Raft or Consul)
# - Implement auto-unseal with cloud KMS or transit engine
# - Enable TLS with proper certificates
# - Set up monitoring and alerting
# - Plan disaster recovery procedures
