# -*- mode: ruby -*-
# vi: set ft=ruby :
VAGRANTFILE_API_VERSION = "2"
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  config.vm.box = "centos/8"
  config.vm.synced_folder ".", "/vagrant", type: "rsync"


  config.vm.provider :lxc do |lxc, override|
    override.vm.box = "visibilityspots/centos-8.x-minimal"
    lxc.container_name = :machine
  end

  config.vm.provider :virtualbox do |virtualbox, override|
    virtualbox.customize ["modifyvm", :id, "--memory", 3072]
  end

  config.vm.define "nomad"

  config.vm.hostname = "nomad"
  config.vm.synced_folder "nomad", "/opt/nomad", type: "rsync", rsync__chown: false
  config.vm.synced_folder "prometheus", "/opt/prometheus", type: "rsync", rsync__chown: false
  config.vm.network "forwarded_port", guest: 8500, host: 8500
  config.vm.network "forwarded_port", guest: 4646, host: 4646
  config.vm.network "forwarded_port", guest: 9090, host: 9090
  config.vm.provision "ansible" do |ansible|
      ansible.config_file = "ansible.cfg"
      ansible.playbook = "plays/nomad.yml"
      ansible.groups = {
        "servers" => ["nomad"],
      }
  end
end
