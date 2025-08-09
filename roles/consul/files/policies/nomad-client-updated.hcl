# Policy for Nomad clients
agent_prefix "" {
  policy = "read"
}

node_prefix "" {
  policy = "write"
}

service_prefix "" {
  policy = "write"
}

# Allow coordinate updates
coordinate "" {
  policy = "write"
}