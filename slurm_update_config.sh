#!/bin/bash
# Simplified SLURM configuration script - now with external munge key distribution

HOSTNAME=$(hostname -s)
echo "==== Configuring SLURM for node: $HOSTNAME ===="

# Ensure time synchronization
dnf install -y chrony > /dev/null 2>&1
systemctl enable chronyd
systemctl restart chronyd

# Stop firewall (though already handled in Vagrantfile in most cases)
systemctl stop firewalld
systemctl disable firewalld

# Ensure munge has proper permissions
systemctl stop munge > /dev/null 2>&1
chmod 755 /var/run/munge
chown munge:munge /var/run/munge

# Start munge service
systemctl enable munge
systemctl restart munge
sleep 3

# Test munge
munge -n | unmunge || {
    echo "Munge test failed, restarting service..."
    systemctl restart munge
    sleep 3
}

# Configure SLURM based on node role
if [ "$HOSTNAME" = "mxs" ]; then
    echo "Configuring SLURM controller..."
    systemctl stop slurmctld > /dev/null 2>&1

    # Ensure essential directories exist with correct permissions
    # These should already be created by Vagrantfile, but double-check critical ones
    mkdir -p /var/spool/slurmctld/state
    chown slurm:slurm /var/spool/slurmctld/state
    chmod 755 /var/spool/slurmctld/state

    # Ensure proper permissions are set
    chmod 644 /etc/slurm/slurm.conf

    # Start controller service
    systemctl enable slurmctld
    systemctl restart slurmctld
    sleep 3

else
    # Compute node configuration
    echo "Configuring SLURM compute node..."
    systemctl stop slurmd > /dev/null 2>&1

    # Ensure spool directory exists with proper permissions
    mkdir -p /var/spool/slurmd
    chown slurm:slurm /var/spool/slurmd
    chmod 755 /var/spool/slurmd

    # Start slurmd
    systemctl enable slurmd
    systemctl restart slurmd
fi

echo "SLURM configuration complete on $(hostname)."
