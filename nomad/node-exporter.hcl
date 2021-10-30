job "node-exporter" {
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
      port "node_exporter" {
        static = 9100
        to = 9100
      }
    }


    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter"
        ports = ["node_exporter"]
        force_pull = true
        volumes = [
          "/proc:/host/proc",
          "/sys:/host/sys",
          "/:/rootfs"
        ]
        logging {
          type = "journald"
          config {
            tag = "NODE-EXPORTER"
          }
        }

      }

      service {
        name = "node-exporter"
        tags = [
          "metrics"
        ]
        port = "node_exporter"

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

