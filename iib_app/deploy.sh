#!/bin/bash
# Ensure the script is executed from its own directory
cd "$(dirname "$0")"

echo "Creating /home/vagrant/iib_app on login node..."
vagrant ssh login -c "mkdir -p /home/vagrant/iib_app"

echo "Copying Dockerfile to login node..."
vagrant scp Dockerfile login:/home/vagrant/iib_app/Dockerfile

echo "Checking Docker installation on Vagrant VM (machine: 'login')..."
vagrant ssh login -c "
if ! command -v docker > /dev/null 2>&1; then
  echo 'Docker is not installed. Installing Docker using dnf...';
  sudo dnf install -y docker;
fi
if ! docker info > /dev/null 2>&1; then
  echo 'Docker service is not running. Starting Docker service...';
  sudo systemctl start docker;
fi
# Create /etc/containers/nodocker to suppress Podman emulation warning
if [ ! -f /etc/containers/nodocker ]; then
  echo 'Creating /etc/containers/nodocker to suppress Podman warning...';
  sudo touch /etc/containers/nodocker;
fi
echo 'Docker is installed and running. Building Docker image...'
cd /home/vagrant/iib_app && sudo docker build -t iib_app . && sudo docker run -d -p 3000:3000 iib_app
"
