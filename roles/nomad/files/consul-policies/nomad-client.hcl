# Policy for Nomad clients to integrate with Consul
# This policy allows Nomad clients to:
# - Register and manage services for workloads
# - Update node information
# - Read from KV store for job templating

agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "write"
}

# Allow Nomad clients to update their own node info
node "" {
  policy = "write"
}

# CRITICAL: Allow reading from KV store for templating in jobs
# This is required for jobs that use {{ key "path/to/key" }} templates
key_prefix "" {
  policy = "read"
}

# Allow coordinate updates
coordinate "" {
  policy = "write"
}
