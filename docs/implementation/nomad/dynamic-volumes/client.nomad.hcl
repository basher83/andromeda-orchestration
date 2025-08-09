# On each client that should host dynamic volumes:

client {
  host_volume "dynamic-data" {
    path   = "/opt/nomad/volumes/dynamic"
    dynamic = true
    plugin  = "ext4-volume"
  }
}

# Use in jobs:

group "g" {
  volume "alloc-data" {
    type   = "host"
    source = "dynamic-data"
    # size in GiB for "create" (Nomad passes to plugin)
    # size is set in task stanza, e.g., volume_mount options are not used here.
  }

  task "t" {
    driver = "docker"
    volume_mount {
      volume      = "alloc-data"
      destination = "/data"
      # Optional: size request for plugin (Nomad 1.6+ dynamic host vols)
      size        = "10GiB"
    }
  }
}
