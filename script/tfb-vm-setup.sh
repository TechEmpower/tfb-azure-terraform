#!/bin/bash

sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
sudo apt-get update
sudo apt-get -y install docker-ce
sudo sed -i '/^ExecStart=/ s/$/ -H 0.0.0.0:2375 -g \/mnt\/docker/' /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo service docker restart

