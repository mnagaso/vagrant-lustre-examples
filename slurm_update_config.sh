#!/bin/bash
# Improved SLURM configuration script with robust error handling

HOSTNAME=$(hostname -s)
echo "==== Configuring SLURM for node: $HOSTNAME ===="

# Setup SSH key for passwordless access (only on controller)
if [ "$HOSTNAME" = "mxs" ]; then
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "Setting up passwordless SSH..."
        mkdir -p ~/.ssh
        ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""
        cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys

        # Distribute key to compute nodes (handles password prompt once per node)
        for node in oss login compute1; do
            sshpass -p "vagrant" ssh-copy-id -o StrictHostKeyChecking=no root@$node 2>/dev/null || {
                echo "Could not set up passwordless SSH to $node automatically."
                echo "You may need to enter password for $node multiple times."
            }
        done
    fi
fi

# Ensure time synchronization
echo "Ensuring time synchronization..."
dnf install -y chrony > /dev/null 2>&1
systemctl enable chronyd
systemctl restart chronyd
sleep 2
chronyc makestep > /dev/null 2>&1

# Create required directories
echo "Creating SLURM directories..."
mkdir -p /var/spool/slurmd
mkdir -p /var/spool/slurmctld/state
mkdir -p /var/log/slurm
mkdir -p /var/run/slurm

# Set basic permissions
chown root:root /var/spool/slurmd
chmod 755 /var/spool/slurmd

# Configure Munge authentication with robust setup
echo "Configuring munge authentication..."

# First properly stop any running munge service
systemctl stop munge > /dev/null 2>&1

# Create and properly set permissions for munge directories
mkdir -p /var/log/munge
mkdir -p /var/lib/munge
mkdir -p /var/run/munge
chmod 700 /etc/munge
chmod 711 /var/lib/munge
chmod 700 /var/log/munge
chmod 777 /var/run/munge  # Extra permissive for socket creation
chown -R munge:munge /etc/munge
chown -R munge:munge /var/lib/munge
chown -R munge:munge /var/log/munge
chown -R munge:munge /var/run/munge

# Controller node specific tasks
if [ "$HOSTNAME" = "mxs" ]; then
    # Create and distribute munge key
    echo "Creating new munge key..."
    dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key
    chmod 400 /etc/munge/munge.key
    chown munge:munge /etc/munge/munge.key

    # Copy key to other nodes without password prompt
    echo "Copying munge key to other nodes..."
    for node in oss login compute1; do
        echo "  Copying to $node..."
        scp -o StrictHostKeyChecking=no -o ConnectTimeout=5 /etc/munge/munge.key root@$node:/etc/munge/ || {
            echo "  SCP failed, trying another method..."
            cat /etc/munge/munge.key | ssh -o StrictHostKeyChecking=no root@$node "cat > /etc/munge/munge.key"
        }

        # Set permissions on remote node
        ssh -o StrictHostKeyChecking=no root@$node "
            chmod 400 /etc/munge/munge.key
            chown munge:munge /etc/munge/munge.key
            systemctl stop munge
        "
    done
fi

# Stop firewall
systemctl stop firewalld
systemctl disable firewalld

# Start munge with careful socket handling
echo "Starting munge service..."
systemctl enable munge
systemctl restart munge
echo "Waiting for munge socket to initialize..."

# Wait for socket with retry mechanism
for retry in {1..10}; do
    sleep 2
    if [ -S /var/run/munge/munge.socket.2 ]; then
        echo "Munge socket is ready."
        break
    else
        echo "Waiting for munge socket (attempt $retry/10)..."
        if [ $retry -eq 5 ]; then
            echo "Trying to restart munge service..."
            systemctl restart munge
        fi
    fi
done

# Test munge with better error handling
echo "Testing munge authentication..."
if ! munge -n | unmunge; then
    echo "Munge test failed, trying one more restart..."
    systemctl restart munge
    sleep 5
    if ! munge -n | unmunge; then
        echo "✗ Munge authentication failed!"
        echo "Checking munge logs:"
        journalctl -u munge --no-pager | tail -n 10
        echo "Checking socket directory:"
        ls -la /var/run/munge/
        exit 1
    fi
fi
echo "✓ Munge authentication working"

# Configure SLURM based on node role
if [ "$HOSTNAME" = "mxs" ]; then
    echo "Configuring SLURM controller..."
    systemctl stop slurmctld || true

    # Set controller-specific permissions
    chown -R slurm:slurm /var/spool/slurmctld
    chown -R slurm:slurm /var/log/slurm
    chown -R slurm:slurm /var/run/slurm
    chmod 755 /var/spool/slurmctld
    chmod 755 /var/log/slurm
    chmod 755 /var/run/slurm
    chmod 700 /var/spool/slurmctld/state

    # Install mail
    dnf install -y mailx > /dev/null 2>&1

    # Create slurm.conf
    cat > /etc/slurm/slurm.conf <<EOF
# SLURM configuration for Lustre cluster
ClusterName=lustre_cluster
SlurmctldHost=mxs(192.168.10.10)

# Authentication
AuthType=auth/munge
CryptoType=crypto/munge
MpiDefault=none

# Communication settings
SlurmctldPort=6817
SlurmdPort=6818
ReturnToService=1

# Process tracking
ProctrackType=proctrack/linuxproc
TaskPlugin=task/none

# Scheduling
SchedulerType=sched/backfill
SelectType=select/linear

# Logging
SlurmctldDebug=debug3
SlurmdDebug=debug3
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log

# Job completion handling
JobCompType=jobcomp/none
AccountingStorageType=accounting_storage/none
MailProg=/usr/bin/mail

# Paths and directories
SlurmdSpoolDir=/var/spool/slurmd
StateSaveLocation=/var/spool/slurmctld/state
SlurmctldPidFile=/var/run/slurm/slurmctld.pid
SlurmdPidFile=/var/run/slurm/slurmd.pid

# Users
SlurmUser=slurm
SlurmdUser=root

# Node definitions with explicit IP addresses
NodeName=mxs NodeAddr=192.168.10.10 CPUs=2 RealMemory=400 State=UNKNOWN
NodeName=oss NodeAddr=192.168.10.20 CPUs=2 RealMemory=400 State=UNKNOWN
NodeName=login NodeAddr=192.168.10.30 CPUs=2 RealMemory=400 State=UNKNOWN
NodeName=compute1 NodeAddr=192.168.10.40 CPUs=2 RealMemory=400 State=UNKNOWN

# Partition definitions
PartitionName=debug Nodes=mxs,oss,login,compute1 Default=YES MaxTime=INFINITE State=UP
EOF

    chmod 644 /etc/slurm/slurm.conf

    # Copy configuration to other nodes with failover methods
    for node in oss login compute1; do
        echo "  Copying config to $node..."
        scp -o StrictHostKeyChecking=no /etc/slurm/slurm.conf root@$node:/etc/slurm/ || {
            echo "  SCP failed, trying another method..."
            cat /etc/slurm/slurm.conf | ssh -o StrictHostKeyChecking=no root@$node "cat > /etc/slurm/slurm.conf"
        }
        ssh -o StrictHostKeyChecking=no root@$node "systemctl restart slurmd" || echo "  Failed to restart slurmd on $node"
    done

    # Start controller service
    systemctl enable slurmctld
    systemctl restart slurmctld
    sleep 10

    # Check status
    if systemctl is-active --quiet slurmctld; then
        echo "SLURM controller started successfully!"
        sinfo -N || echo "Failed to get node info"
    else
        echo "ERROR: SLURM controller failed to start"
        journalctl -u slurmctld --no-pager | tail -n 10
    fi

else
    # Compute node configuration
    echo "Configuring SLURM compute node..."
    systemctl stop slurmd || true

    # Make sure slurm directories exist and have proper permissions
    mkdir -p /var/spool/slurmd
    chown root:root /var/spool/slurmd
    chmod 755 /var/spool/slurmd

    # Start slurmd
    systemctl enable slurmd
    systemctl restart slurmd
    sleep 2

    if systemctl is-active --quiet slurmd; then
        echo "SLURM compute daemon started successfully!"
    else
        echo "ERROR: SLURM compute daemon failed to start"
        journalctl -u slurmd --no-pager | tail -n 10
    fi
fi

echo "SLURM configuration complete on $(hostname)."