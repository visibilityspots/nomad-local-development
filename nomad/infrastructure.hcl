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

    network {
      port "consul_dns" {
        static = 8600
        to = 8600
      }
      port "consul" {
        static = 8500
        to = 8500
      }
      port "dns" {
        static = 53
        to = 53
      }
      port "prometheus" {
        static = 9090
        to = 9090
      }
      port "node_exporter" {
        static = 9100
        to = 9100
      }
      port "cadvisor" {
        static = 8080
        to = 8080
      }
    }

    task "consul" {
      driver = "docker"
      env = {
        CONSUL_BIND_INTERFACE="eth0"
      }
      config {
        image = "consul"
        force_pull = true
        network_mode = "host"
        ports = ["consul", "consul_dns"]
        logging {
          type = "journald"
          config {
            tag = "CONSUL"
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
        ports = ["dns"]
        args = [
            "-S", "/consul/${NOMAD_IP_consul_consul_dns}#8600"
        ]
        cap_add = [
            "NET_ADMIN",
        ]
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
        port = "prometheus"

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
        ports = ["cadvisor"]
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

    task "node-exporter" {
      driver = "docker"

      config {
        image = "prom/node-exporter:v0.17.0"
        force_pull = true
        ports = ["node_exporter"]
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
        address_mode = "driver"
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

