#!/bin/bash
# Configure SSH keys for OOD access

echo "==== Configuring SSH for Open OnDemand access ===="

# Configure SSH for vagrant user
sudo -u vagrant mkdir -p /home/vagrant/.ssh
sudo -u vagrant chmod 700 /home/vagrant/.ssh

# Generate SSH key if it doesn't exist
if [ ! -f /home/vagrant/.ssh/id_rsa ]; then
    sudo -u vagrant ssh-keygen -t rsa -f /home/vagrant/.ssh/id_rsa -N ""
fi

# Set up SSH config to avoid host key checking within the cluster
sudo -u vagrant tee /home/vagrant/.ssh/config > /dev/null <<EOF
Host 192.168.10.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel QUIET
EOF
sudo -u vagrant chmod 600 /home/vagrant/.ssh/config

# Create authorized_keys if it doesn't exist
if [ ! -f /home/vagrant/.ssh/authorized_keys ]; then
    sudo -u vagrant touch /home/vagrant/.ssh/authorized_keys
    sudo -u vagrant chmod 600 /home/vagrant/.ssh/authorized_keys
fi

# Configure SSH for user1-user5 if they exist
for i in {1..5}; do
    username="user$i"
    if id "$username" &>/dev/null; then
        echo "Configuring SSH for $username..."

        # Create .ssh directory
        sudo -u "$username" mkdir -p "/home/$username/.ssh"
        sudo -u "$username" chmod 700 "/home/$username/.ssh"

        # Generate SSH key if it doesn't exist
        if [ ! -f "/home/$username/.ssh/id_rsa" ]; then
            sudo -u "$username" ssh-keygen -t rsa -f "/home/$username/.ssh/id_rsa" -N ""
        fi

        # Set up SSH config
        sudo -u "$username" tee "/home/$username/.ssh/config" > /dev/null <<EOF
Host 192.168.10.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel QUIET
EOF
        sudo -u "$username" chmod 600 "/home/$username/.ssh/config"

        # Create authorized_keys if it doesn't exist
        if [ ! -f "/home/$username/.ssh/authorized_keys" ]; then
            sudo -u "$username" touch "/home/$username/.ssh/authorized_keys"
            sudo -u "$username" chmod 600 "/home/$username/.ssh/authorized_keys"
        fi
    fi
done

echo "SSH configuration for OOD access complete."
