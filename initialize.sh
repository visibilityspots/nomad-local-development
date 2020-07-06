#!/bin/bash

#echo "[virt7-rkt-common-candidate]
#name=virt7-rkt-common-candidate
#baseurl=http://cbs.centos.org/repos/virt7-rkt-common-candidate/x86_64/os/
#enabled=1
#gpgcheck=0" > /etc/yum.repos.d/rkt.repo
#
#sudo yum clean all
#
#sudo yum install rkt -y

sudo yum install unzip -y

NOMAD_VERSION=0.11.3

echo "Fetching Nomad..."
cd /tmp/
curl -sSL https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip -o nomad.zip

echo "Installing Nomad..."
unzip nomad.zip
sudo install nomad /usr/bin/nomad

sudo mkdir -p /etc/nomad.d
sudo chmod a+w /etc/nomad.d

sudo yum install -y yum-utils device-mapper-persistent-data lvm2 bind-utils nmap

sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce

sudo systemctl enable docker.service
sudo systemctl restart docker.service

sudo usermod -aG docker vagrant

(
cat <<-EOF
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
After=network-online.target
Wants=network-online.target

[Service]
KillMode=process
KillSignal=SIGINT
ExecStart=/usr/bin/nomad agent -config /opt/nomad/server.hcl
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
) | sudo tee /usr/lib/systemd/system/nomad-server.service


sudo systemctl enable nomad-server.service
sudo systemctl start nomad-server.service

(
cat <<-EOF
[Unit]
Description=Nomad
Documentation=https://nomadproject.io/docs/
After=nomad-server.service
Wants=nomad-server.service

[Service]
KillMode=process
KillSignal=SIGINT
ExecStart=/usr/bin/nomad agent -config /opt/nomad/client.hcl
ExecReload=/bin/kill -HUP $MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
) | sudo tee /usr/lib/systemd/system/nomad-client.service


sudo systemctl enable nomad-client.service
sudo systemctl start nomad-client.service

for bin in cfssl cfssl-certinfo cfssljson
do
        echo "Installing $bin..."
        curl -sSL https://pkg.cfssl.org/R1.2/${bin}_linux-amd64 > /tmp/${bin}
        sudo install /tmp/${bin} /usr/local/bin/${bin}
done

echo "Installing autocomplete..."
nomad -autocomplete-install

#echo "Start containers through nomad"
#nomad run /opt/nomad/infrastructure.hcl
