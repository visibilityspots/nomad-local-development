# Full configuration options can be found at https://www.nomadproject.io/docs/configuration

data_dir = "/opt/nomad/data"
bind_addr = "{% raw %}{{{% endraw %} GetInterfaceIP \"{{ nomad__interface }}\" {% raw %}}}{% endraw %}"

server {
  enabled = {{ nomad__server | bool | lower }}
  bootstrap_expect = 1
}

disable_update_check = true

telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}


client {
  enabled = {{ nomad__client | bool | lower }}
  network_interface = "{{ nomad__interface }}"
}

plugin "docker" {
  config {
    allow_caps = [ "ALL" ],
    volumes {
      enabled = true
    }
  }
}
