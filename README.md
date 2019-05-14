# Nomad local development

The aim of this project is to provide a development environment like docker-compose but without a vendor locking on docker based on [consul](https://www.consul.io/) by using [nomad](https://www.nomadproject.io)

bring up the environment by using [vagrant](https://www.vagrantup.com) which will bring up a centos 7 virtualbox machine or lxc container. It will use the intialize.sh bash script to install both nomad and consul and also start a nomad job for a prometheus setup.

The proved working vagrant providers used on an [ArchLinux](https://www.archlinux.org/) system are
* [vagrant-lxc](https://github.com/fgrehm/vagrant-lxc)
* [vagrant-libvirt](https://github.com/vagrant-libvirt/)
* [virtualbox](https://www.virtualbox.org/)

```bash
    $ vagrant up --provider lxc
    OR
    $ vagrant up --provider libvirt
    OR
    $ vagrant up --provider virtualbox
```

Once it is finished, you should be able to connect to the vagrant environment through SSH and interact with Nomad to start a development environment:

```bash
    $ vagrant ssh
    [vagrant@nomad ~]$ nomad run /opt/nomad/infrastructure.hcl
==> Monitoring evaluation "ad6e7c2e"
    Evaluation triggered by job "infrastructure"
    Allocation "60f6c5ec" created: node "4b966e54", group "infra"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "ad6e7c2e" finished with status "complete"
```

get the nomad state

```
[vagrant@nomad ~]$ nomad status infrastructure
ID            = infrastructure
Name          = infrastructure
Submit Date   = 2019-04-17T20:03:23Z
Type          = service
Priority      = 50
Datacenters   = dc1
Status        = running
Periodic      = false
Parameterized = false

Summary
Task Group  Queued  Starting  Running  Failed  Complete  Lost
infra       0       0         1        0       0         0

Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created  Modified
60f6c5ec  4b966e54  infra       0        run      running  55s ago  32s ago
```

get the allocation state

```
[vagrant@nomad ~]$ nomad alloc-status 60f6c5ec
ID                  = 60f6c5ec
Eval ID             = ad6e7c2e
Name                = infrastructure.infra[0]
Node ID             = 4b966e54
Job ID              = infrastructure
Job Version         = 0
Client Status       = running
Client Description  = Tasks are running
Desired Status      = run
Desired Description = <none>
Created             = 1m16s ago
Modified            = 53s ago

Task "cadvisor" is "running"
Task Resources
CPU        Memory          Disk     Addresses
44/50 MHz  23 MiB/100 MiB  300 MiB  http: 10.0.3.185:8080

Task Events:
Started At     = 2019-04-17T20:03:26Z
Finished At    = N/A
Total Restarts = 0
Last Restart   = N/A

Recent Events:
Time                  Type        Description
2019-04-17T20:03:26Z  Started     Task started by client
2019-04-17T20:03:23Z  Driver      Downloading image
2019-04-17T20:03:23Z  Task Setup  Building Task Directory
2019-04-17T20:03:23Z  Received    Task received by client

Task "consul" is "running"
Task Resources
CPU         Memory          Disk     Addresses
97/100 MHz  16 MiB/300 MiB  300 MiB  consul_dns: 10.0.3.185:8600
                                                                  consul: 10.0.3.185:8500

Task Events:
Started At     = 2019-04-17T20:03:26Z
Finished At    = N/A
Total Restarts = 0
Last Restart   = N/A

Recent Events:
Time                  Type        Description
2019-04-17T20:03:26Z  Started     Task started by client
2019-04-17T20:03:23Z  Driver      Downloading image
2019-04-17T20:03:23Z  Task Setup  Building Task Directory
2019-04-17T20:03:23Z  Received    Task received by client

Task "dnsmasq" is "running"
Task Resources
CPU       Memory       Disk     Addresses
4/50 MHz  0 B/100 MiB  300 MiB  dns: 10.0.3.185:53

Task Events:
Started At     = 2019-04-17T20:03:26Z
Finished At    = N/A
Total Restarts = 0
Last Restart   = N/A

Recent Events:
Time                  Type        Description
2019-04-17T20:03:26Z  Started     Task started by client
2019-04-17T20:03:23Z  Driver      Downloading image
2019-04-17T20:03:23Z  Task Setup  Building Task Directory
2019-04-17T20:03:23Z  Received    Task received by client

Task "node-exporter" is "running"
Task Resources
CPU       Memory           Disk     Addresses
0/50 MHz  4.4 MiB/100 MiB  300 MiB  http: 10.0.3.185:9100

Task Events:
Started At     = 2019-04-17T20:03:26Z
Finished At    = N/A
Total Restarts = 0
Last Restart   = N/A

Recent Events:
Time                  Type        Description
2019-04-17T20:03:26Z  Started     Task started by client
2019-04-17T20:03:23Z  Driver      Downloading image
2019-04-17T20:03:23Z  Task Setup  Building Task Directory
2019-04-17T20:03:23Z  Received    Task received by client

Task "prometheus" is "running"
Task Resources
CPU       Memory          Disk     Addresses
0/50 MHz  21 MiB/100 MiB  300 MiB  http: 10.0.3.185:9090

Task Events:
Started At     = 2019-04-17T20:03:25Z
Finished At    = N/A
Total Restarts = 0
Last Restart   = N/A

Recent Events:
Time                  Type        Description
2019-04-17T20:03:25Z  Started     Task started by client
2019-04-17T20:03:23Z  Driver      Downloading image
2019-04-17T20:03:23Z  Task Setup  Building Task Directory
2019-04-17T20:03:23Z  Received    Task received by client
```

As you could have seen the allocation has been splitted by tasks. This can be configured in the nomad/infrastructure.hcl file.

The consul container is used to register the different services and the dnsmasq container will be used as a dns forwarder towards the consul dns interface so the services are resolvable between each other.
