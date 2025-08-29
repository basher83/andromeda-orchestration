# Policy for Vault Consul client agents
# This allows Vault nodes to join the Consul cluster and register services

# Agent operations
agent_prefix "" {
  policy = "read"
}

agent "vault-master-lloyd" {
  policy = "write"
}

agent "vault-prod-1-holly" {
  policy = "write"
}

agent "vault-prod-2-mable" {
  policy = "write"
}

agent "vault-prod-3-lloyd" {
  policy = "write"
}

# Node operations - allow Vault nodes to register themselves
node_prefix "" {
  policy = "read"
}

node "vault-master-lloyd" {
  policy = "write"
}

node "vault-prod-1-holly" {
  policy = "write"
}

node "vault-prod-2-mable" {
  policy = "write"
}

node "vault-prod-3-lloyd" {
  policy = "write"
}

# Service registration for Vault
service_prefix "" {
  policy = "read"
}

# Allow write access to any vault-related service
service_prefix "vault" {
  policy = "write"
}

# Also allow test services for debugging
service_prefix "test-vault" {
  policy = "write"
}

# Allow KV operations for Vault metadata
key_prefix "vault/" {
  policy = "write"
}

# Session operations for health checks
session_prefix "" {
  policy = "write"
}

# Allow coordinate updates for network tomography
coordinate "" {
  policy = "write"
}