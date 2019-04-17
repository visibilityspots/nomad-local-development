job "infrastructure" {
  region = "global"
  datacenters = ["dc1"]
  type = "service"

  group "infra" {
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

    task "dnsmasq" {
      driver = "docker"

      config {
        image = "andyshinn/dnsmasq:2.78"
        force_pull = true
        args = [
            "-S", "/consul/${NOMAD_IP_consul_consul_dns}#8600"
        ]
        cap_add = [
            "NET_ADMIN",
        ]
        port_map {
          dns = 53
        }
        logging {
          type = "journald"
          config {
            tag = "DNSMASQ"
          }
        }
      }

      service {
        name = "dnsmasq"
        port = "dns"
        address_mode = "driver"

        check {
          type     = "tcp"
          port     = "dns"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 50
        memory = 100

        network {
          port "dns" { static = "53" }
        }
      }
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v2.8.1"
        force_pull = true
        dns_servers = ["${NOMAD_IP_dnsmasq_dns}"]
        volumes = [
          "/opt/prometheus/:/etc/prometheus/"
        ]
        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
          "--web.enable-admin-api"
        ]
        port_map {
            http = 9090
        }
        logging {
          type = "journald"
          config {
            tag = "PROMETHEUS"
          }
        }
      }

      service {
        name = "prometheus"
        address_mode = "driver"
        tags = [
          "metrics"
        ]
        port = "http"

        check {
          type = "http"
          path = "/targets"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu    = 50
        memory = 100

        network {
          port "http" {
            static = "9090"
          }
        }
      }
    }

    task "cadvisor" {
      driver = "docker"

      config {
        image = "google/cadvisor:v0.33.0"
        force_pull = true
        dns_servers = ["${NOMAD_IP_dnsmasq_dns}"]
        volumes = [
          "/:/rootfs:ro",
          "/var/run:/var/run:rw",
          "/sys:/sys:ro",
          "/var/lib/docker/:/var/lib/docker:ro",
          "/cgroup:/cgroup:ro"
        ]
        port_map {
          http = 8080
        }
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
        port = "http"

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

        network {
          port "http" { static = "8080" }
        }
      }
    }

    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter:v0.17.0"
        force_pull = true
        volumes = [
          "/proc:/host/proc",
          "/sys:/host/sys",
          "/:/rootfs"
        ]
        port_map {
          http = 9100
        }
        logging {
          type = "journald"
          config {
            tag = "NODE-EXPORTER"
          }
        }

      }

      service {
        name = "node-exporter"
        address_mode = "driver"
        tags = [
          "metrics"
        ]
        port = "http"


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

        network {
          port "http" { static = "9100" }
        }
      }
    }
  }
}

