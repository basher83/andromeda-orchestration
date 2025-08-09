# Policy for Nomad workload identities
node_prefix "" {
  policy = "read"
}

service_prefix "" {
  policy = "write"
}

# Allow reading agent info
agent_prefix "" {
  policy = "read"
}

# Allow key-value access for service configuration
key_prefix "service/" {
  policy = "read"
}

# Allow Consul catalog queries
query_prefix "" {
  policy = "read"
}