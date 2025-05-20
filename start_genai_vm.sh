#!/bin/bash
# Script to start the genAI test VM and verify Docker installation

set -e

# Check if Hatchling directory exists, if not, clone it
echo "[INFO] Checking for Hatchling directory..."
if [ ! -d "Hatchling" ]; then
    echo "[INFO] Hatchling directory not found. Cloning from GitHub..."
    git clone https://github.com/CrackingShells/Hatchling.git
else
    echo "[INFO] Hatchling directory already exists."
fi

VAGRANTFILE=Vagrantfile.genai
VM_NAME=genai-test

# Start the VM
echo "[INFO] Starting the $VM_NAME VM using $VAGRANTFILE..."
VAGRANT_VAGRANTFILE="$VAGRANTFILE" vagrant up $VM_NAME --provider=virtualbox
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to start the VM. Please check the Vagrantfile and your environment."
    exit 1
fi
echo "[INFO] $VM_NAME VM started successfully."

# Copy the local ./genAI directory into the VM
if command -v vagrant-scp >/dev/null 2>&1 || vagrant scp --help >/dev/null 2>&1; then
    echo "[INFO] Copying ./genAI to /home/vagrant/genAI in the VM..."
    VAGRANT_VAGRANTFILE="$VAGRANTFILE" vagrant scp ./genAI $VM_NAME:/home/vagrant/genAI
    echo "[INFO] genAI directory copied successfully."
else
    echo "[WARNING] vagrant-scp plugin is not installed. Please install it with: vagrant plugin install vagrant-scp"
fi

# Make setup_genai.sh executable and run it inside the VM
echo "[INFO] Making setup_genai.sh executable and running it inside the VM..."
VAGRANT_VAGRANTFILE="$VAGRANTFILE" vagrant ssh $VM_NAME -c "chmod +x /home/vagrant/genAI/setup_genai.sh && cd /home/vagrant/genAI && ./setup_genai.sh"

# SSH into the VM and check Docker
cat <<'EOF'
[INFO] To SSH into the VM, run:
    VAGRANT_VAGRANTFILE=Vagrantfile.genai vagrant ssh genai-test

[INFO] Once inside the VM, check Docker with:
  docker --version
  sudo systemctl status docker
EOF
