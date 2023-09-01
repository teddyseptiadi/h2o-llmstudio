#!/bin/bash

# Install core packages
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository universe -y
sudo apt update
sudo apt -y install curl
sudo apt -y install make

# Verify make installation
ls /usr/bin/make

# System installs (Python 3.10)
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt -y install python3.10
sudo apt-get -y install python3.10-distutils
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# GPU requirements
set -eo pipefail
set -x

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/11.8.0/local_installers/cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2004-11-8-local_11.8.0-520.61.05-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2004-11-8-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda

distribution=$(. /etc/os-release;echo $ID$VERSION_ID) && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey \
| sudo apt-key add - && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list \
| sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get -y update
sudo apt-get install -y nvidia-container-runtime
rm cuda-repo-ubuntu2004-*.deb

echo "Clone llm studio"

# Clone h2o-llmstudio
git clone https://github.com/h2oai/h2o-llmstudio.git
cd h2o-llmstudio

git checkout v0.1.0


echo "Create the script.sh file with the desired commands"

printf '#!/bin/bash\n\n' > script.sh
printf 'export H2O_WAVE_LISTEN=":80"\n' >> script.sh
printf 'export H2O_WAVE_ADDRESS="http://127.0.0.1:80"\n\n' >> script.sh
printf 'make setup\n' >> script.sh
printf 'make lmstudio\n' >> script.sh

# Make the script.sh file executable
chmod +x script.sh


# Running application as a service in systemd
cd /etc/systemd/system
sudo chown -R ubuntu:ubuntu .

cd /etc/systemd/system
printf """
[Unit]
Description=LLM Studio Service
After=network.target
[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/h2o-llmstudio
ExecStart=bash /home/ubuntu/h2o-llmstudio/script.sh
Restart=always
[Install]
WantedBy=multi-user.target
""" >> llm_studio.service


sudo systemctl daemon-reload
sudo systemctl enable llm_studio.service
sudo systemctl start llm_studio.service