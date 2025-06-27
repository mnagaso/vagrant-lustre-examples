#!/bin/bash
# Create users on compute nodes

echo "Creating users on compute node..."

# Create example users user1-user5
for i in {1..5}; do
  username="user$i"
  if ! id -u $username &>/dev/null; then
    useradd -m $username
    echo "password123" | passwd --stdin $username
    echo "export SLURM_CONF=/etc/slurm/slurm.conf" >> /home/$username/.bashrc
    echo "Created user: $username"
  else
    echo "User $username already exists"
  fi
done

echo "Compute node user creation complete"
