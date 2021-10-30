job "cadvisor" {
  region = "global"
  datacenters = ["dc1"]
  type = "service"

  group "app" {
    count = 1

    restart {
      attempts = 3
      delay    = "20s"
      mode     = "delay"
    }

    network {
      port "cadvisor" {
        static = 8080
        to = 8080
      }
    }


    task "cadvisor" {
      driver = "docker"

      config {
        image = "google/cadvisor"
        ports = ["cadvisor"]
        force_pull = true
        volumes = [
          "/:/rootfs:ro",
          "/var/run:/var/run:rw",
          "/sys:/sys:ro",
          "/var/lib/docker/:/var/lib/docker:ro",
          "/cgroup:/cgroup:ro"
        ]
        logging {
          type = "journald"
          config {
            tag = "CADVISOR"
          }
        }
      }

      service {
        address_mode = "driver"
        name = "cadvisor"
        tags = [
          "metrics"
        ]
        port = "cadvisor"

        check {
          type = "http"
          path = "/metrics/"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu    = 50
        memory = 100
      }
    }
  }
}

