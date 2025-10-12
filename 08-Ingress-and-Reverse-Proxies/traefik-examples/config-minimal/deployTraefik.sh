#!/bin/bash

#Install Docker
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

#add docekr to Ubuntu Repos
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

#Update Repos
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#Install NVIM Optional
git clone https://github.com/MilanVives/nvim
./nvim/install/install-ubuntu.sh
#source ~/.bashrc

#Create Docker network
docker network create traefik

#Add acme.json file for certs and change permissions
touch acme.json
chmod 600 acme.json
rm ~/nvim-linux64.tar.gz
# docker compose up -d