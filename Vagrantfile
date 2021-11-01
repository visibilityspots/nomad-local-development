# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.synced_folder_opts = {
      type: :rsync,
    }
  end

  config.vm.box = "centos/8"

  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "visibilityspots/centos-8.x-minimal"
    lxc.container_name = :machine
  end

  config.vm.provider :virtualbox do |virtualbox, override|
    virtualbox.customize ["modifyvm", :id, "--memory", 3072]
  end

  config.vm.define "nomad"
  config.vm.hostname = "nomad"

  config.vm.network "forwarded_port", guest: 8500, host: 8500
  config.vm.network "forwarded_port", guest: 4646, host: 4646
  config.vm.network "forwarded_port", guest: 9090, host: 9090

  config.vm.synced_folder "nomad", "/opt/nomad", type: "rsync"
  config.vm.synced_folder "prometheus", "/opt/prometheus", type: "rsync"
  config.vm.provision "ansible" do |ansible|
      ansible.config_file = "ansible.cfg"
      ansible.playbook = "plays/nomad.yml"
      ansible.groups = {
        "servers" => ["nomad"],
      }
  end
end
