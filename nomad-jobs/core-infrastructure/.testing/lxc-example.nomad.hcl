job "lxc-example" {
  datacenters = ["dc1"]

  group "example" {
    task "lxc-task" {
      driver = "lxc"

      config {
        image = "ubuntu:20.04"
        command = "/bin/bash"
        args = ["-c", "echo Hello from LXC! && sleep 60"]
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
