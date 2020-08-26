#!/bin/bash -x

export DEBIAN_FRONTEND=noninteractive
curl -sL https://releases.rancher.com/install-docker/18.09.sh | sh
sudo usermod -aG docker rancher