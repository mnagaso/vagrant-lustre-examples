#!/bin/bash
# SLURM configuration script with enhanced Munge authentication setup

HOSTNAME=$(hostname -s)
echo "==== Configuring SLURM for node: $HOSTNAME ===="

# Step 1: Synchronize time on all nodes
echo "Ensuring time synchronization..."
dnf -y install chrony || true
systemctl enable chronyd
systemctl restart chronyd
sleep 2
chronyc makestep || true

# Create required directories with proper permissions
echo "Creating SLURM directories..."
mkdir -p /var/spool/slurmd
mkdir -p /var/spool/slurmctld/state
mkdir -p /var/log/slurm
mkdir -p /var/run/slurm

# Set proper ownership
chown root:root /var/spool/slurmd
chmod 755 /var/spool/slurmd

# Verify hostname resolution works properly
echo "Verifying hostname resolution..."
getent hosts mxs || { echo "ERROR: Cannot resolve hostname 'mxs'"; exit 1; }

# Configure Munge authentication
echo "Configuring munge authentication..."

# First ensure correct permissions for Munge directories
mkdir -p /var/log/munge
mkdir -p /var/lib/munge
mkdir -p /var/run/munge
chmod 700 /etc/munge
chmod 711 /var/lib/munge
chmod 700 /var/log/munge
chmod 755 /var/run/munge
chown -R munge:munge /etc/munge
chown -R munge:munge /var/lib/munge
chown -R munge:munge /var/log/munge
chown -R munge:munge /var/run/munge

if [ "$HOSTNAME" = "mxs" ]; then
    # Stop any existing munge service before recreating key
    systemctl stop munge || true

    # On controller node, create a fresh key with proper entropy
    echo "Creating new munge key..."
    rm -f /etc/munge/munge.key
    dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key
    chmod 400 /etc/munge/munge.key
    chown munge:munge /etc/munge/munge.key

    # Setup passwordless SSH for root to simplify key distribution
    if [ ! -f /root/.ssh/id_rsa ]; then
        mkdir -p /root/.ssh
        ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa

        # Distribute SSH keys
        for node in oss login compute1; do
            echo "Setting up SSH key access to $node..."
            ssh-copy-id -o StrictHostKeyChecking=no root@$node || {
                echo "Failed to set up passwordless SSH. Will continue but may require password prompts."
            }
        done
    fi

    # Copy key to other nodes with proper permissions
    echo "Copying munge key to other nodes..."
    for node in oss login compute1; do
        echo "  Copying to $node..."
        scp -o StrictHostKeyChecking=no /etc/munge/munge.key root@$node:/etc/munge/ || {
            echo "  Failed to copy via scp, trying alternative method..."
            # Alternative method using SSH + cat + redirection
            cat /etc/munge/munge.key | ssh -o StrictHostKeyChecking=no root@$node "cat > /etc/munge/munge.key; chown munge:munge /etc/munge/munge.key; chmod 400 /etc/munge/munge.key"
        }

        # Ensure munge service is stopped before permissions are fixed
        ssh -o StrictHostKeyChecking=no root@$node "systemctl stop munge || true"

        # Fix permissions on the destination node
        ssh -o StrictHostKeyChecking=no root@$node "chown -R munge:munge /etc/munge && \
                                                  chmod 700 /etc/munge && \
                                                  chmod 400 /etc/munge/munge.key && \
                                                  chown -R munge:munge /var/lib/munge && \
                                                  chown -R munge:munge /var/log/munge && \
                                                  chown -R munge:munge /var/run/munge"
    done
fi

# Double check firewall is disabled
echo "Making sure firewall is disabled..."
systemctl stop firewalld
systemctl disable firewalld

# Start munge service with thorough verification
echo "Starting munge service..."
systemctl enable munge
systemctl restart munge

# Wait for munge to fully start
echo "Waiting for munge to become available..."
sleep 5  # Increased wait time for munge to properly initialize

# Test munge authentication with better error reporting
echo "Testing munge authentication..."
if ! munge -n | unmunge; then
    echo "✗ Munge authentication test failed! Checking logs:"
    journalctl -u munge --no-pager | tail -n 20
    echo "Attempting to fix munge configuration..."
    systemctl restart munge
    sleep 5
    if ! munge -n | unmunge; then
        echo "FATAL: Munge authentication still failing. SLURM will not work without functioning munge."
        exit 1
    fi
else
    echo "✓ Munge authentication is working properly locally"
fi

# If on controller node, verify munge works with all nodes
if [ "$HOSTNAME" = "mxs" ]; then
    echo "Verifying munge authentication between nodes..."
    for node in oss login compute1; do
        echo "Testing munge auth from mxs to $node:"
        if ! munge -n | ssh -o StrictHostKeyChecking=no $node unmunge; then
            echo "WARNING: Munge authentication failed between mxs and $node"
            echo "Attempting to fix by restarting munge on $node..."
            ssh -o StrictHostKeyChecking=no $node "systemctl restart munge"
            sleep 3
            if ! munge -n | ssh -o StrictHostKeyChecking=no $node unmunge; then
                echo "CRITICAL: Munge authentication still failing between mxs and $node"
                echo "Job submission is likely to fail!"
            else
                echo "✓ Munge authentication fixed between mxs and $node"
            fi
        else
            echo "✓ Munge authentication working between mxs and $node"
        fi
    done

    # Also test authentication from compute nodes back to controller
    for node in oss login compute1; do
        echo "Testing munge auth from $node to mxs:"
        if ! ssh -o StrictHostKeyChecking=no $node "munge -n" | unmunge; then
            echo "WARNING: Munge authentication failed from $node to mxs"
        else
            echo "✓ Munge authentication working from $node to mxs"
        fi
    done
fi

# Configure SLURM
if [ "$HOSTNAME" = "mxs" ]; then
    echo "Configuring SLURM controller..."

    # Stop any existing services first
    systemctl stop slurmctld || true

    # Set controller-specific directory permissions more thoroughly
    chown -R slurm:slurm /var/spool/slurmctld
    chown -R slurm:slurm /var/log/slurm
    chown -R slurm:slurm /var/run/slurm
    chmod 755 /var/spool/slurmctld
    chmod 755 /var/log/slurm
    chmod 755 /var/run/slurm

    # Ensure state directory is properly set up
    mkdir -p /var/spool/slurmctld/state
    chown -R slurm:slurm /var/spool/slurmctld/state
    chmod 700 /var/spool/slurmctld/state

    # Make sure mail is installed before creating config
    dnf install -y mailx || true

    # Create slurm.conf with corrected configuration
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

# Scheduling - FIX: Removed CR_Core parameter that's incompatible with select/linear
SchedulerType=sched/backfill
SelectType=select/linear
# NOTE: SelectTypeParameters=CR_Core is removed as it's invalid for select/linear

# Logging
SlurmctldDebug=debug5
SlurmdDebug=debug3
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log
DebugFlags=backfill

# Job completion handling
JobCompType=jobcomp/none
AccountingStorageType=accounting_storage/none

# Mail program configuration
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

    # Copy configuration to other nodes using more robust method
    echo "Copying SLURM configuration to other nodes..."
    for node in oss login compute1; do
        echo "  Copying to $node..."
        scp -o StrictHostKeyChecking=no /etc/slurm/slurm.conf root@$node:/etc/slurm/ || {
            echo "  Failed to copy via scp, trying alternative method..."
            cat /etc/slurm/slurm.conf | ssh -o StrictHostKeyChecking=no root@$node "cat > /etc/slurm/slurm.conf"
        }

        # Restart slurmd on each node to ensure the new config is loaded
        echo "  Restarting slurmd on $node..."
        ssh -o StrictHostKeyChecking=no root@$node "systemctl restart slurmd" || echo "  Failed to restart slurmd on $node"
    done

    # Start controller service
    echo "Starting SLURM controller service..."
    systemctl enable slurmctld
    systemctl restart slurmctld

    # Wait for controller to start
    echo "Waiting for SLURM controller to start..."
    sleep 15  # Increased wait time

    # Check controller status with better error handling
    if ! systemctl is-active --quiet slurmctld; then
        echo "ERROR: SLURM controller failed to start. Checking logs:"
        journalctl -u slurmctld --no-pager | tail -n 20
        echo "Detailed error information from log file:"
        cat /var/log/slurm/slurmctld.log | grep -i "error\|fail\|fatal" | tail -n 20
    else
        echo "SLURM controller started successfully!"
        systemctl status slurmctld --no-pager
    fi

    # Check node status
    echo "Checking node status:"
    sinfo -N || echo "Failed to get node info. Check controller status with 'journalctl -u slurmctld'"

    # Verify the configuration is correct for job submission
    echo "Testing configuration with test job submission from controller..."
    sleep 5  # Give a little more time for nodes to register
    sudo -u vagrant bash -c "cd /home/vagrant && sbatch simple_job.sh" || {
        echo "WARNING: Job submission test failed from controller. Will try from login node next."
    }
else
    # On compute nodes, make sure we get the latest config
    echo "Ensuring compute node has the latest configuration..."

    # Quick test for problematic configuration
    if grep -q "SelectTypeParameters=CR_Core" /etc/slurm/slurm.conf; then
        echo "WARNING: Found invalid SelectTypeParameters, removing from config..."
        sed -i '/SelectTypeParameters=CR_Core/d' /etc/slurm/slurm.conf
    fi

    # Configure compute node
    echo "Configuring SLURM compute node..."
    systemctl stop slurmd || true

    # More thorough setup of compute node directories
    mkdir -p /var/spool/slurmd
    chown root:root /var/spool/slurmd
    chmod 755 /var/spool/slurmd

    systemctl enable slurmd
    systemctl restart slurmd

    # Check status with better error handling
    if ! systemctl is-active --quiet slurmd; then
        echo "ERROR: SLURM compute daemon failed to start. Checking logs:"
        journalctl -u slurmd --no-pager | tail -n 20
    else
        echo "SLURM compute daemon started successfully!"
        systemctl status slurmd --no-pager
    fi
fi

echo "SLURM configuration complete on $(hostname)."
echo "Run 'sinfo' to check cluster status."