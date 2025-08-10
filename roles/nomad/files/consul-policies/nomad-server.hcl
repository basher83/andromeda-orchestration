# Policy for Nomad servers to integrate with Consul
# This policy allows Nomad servers to:
# - Register and manage services
# - Create and manage ACL tokens for workloads
# - Read agent and node information

agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "write"
}

# Allow Nomad servers to manage ACL tokens for workloads
acl = "write"

# Allow reading from KV store for templating in jobs
key_prefix "" {
  policy = "read"
}

# Allow coordinate updates
coordinate "" {
  policy = "write"
}
