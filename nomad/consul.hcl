job "infrastructure" {
  region = "global"
  datacenters = ["dc1"]
  type = "service"

  group "consul" {
    count = 1

    restart {
      attempts = 3
      delay    = "20s"
      mode     = "delay"
    }

    task "consul" {
      driver = "docker"
      env = {
        CONSUL_BIND_INTERFACE="eth0"
      }
      config {
        image = "consul:1.4.4"
        force_pull = true
        network_mode = "host"
        logging {
          type = "journald"
          config {
            tag = "CONSUL"
          }
        }
      }
      resources {
        network {
            port "consul_dns" {
                static = 8600
            }
            port "consul" {
                static = 8500
            }
        }
      }
      service {
        name = "consul"
        address_mode = "driver"

        check {
          type = "http"
          path = "/ui"
          interval = "10s"
          timeout = "2s"
          port = "consul"
        }
      }
    }
  }
}

