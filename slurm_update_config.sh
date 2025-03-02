#!/bin/bash
# SLURM configuration script - run on each node after Vagrant provisioning

HOSTNAME=$(hostname -s)
echo "==== Configuring SLURM for node: $HOSTNAME ===="

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
if [ "$HOSTNAME" = "mxs" ]; then
    # Make sure any existing munge service is stopped
    systemctl stop munge || true

    # On controller node, create the key
    echo "Creating new munge key..."
    dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key
    chmod 700 /etc/munge
    chmod 400 /etc/munge/munge.key
    chown -R munge:munge /etc/munge
    chown -R munge:munge /var/lib/munge
    chown -R munge:munge /var/log/munge
    mkdir -p /var/run/munge
    chown -R munge:munge /var/run/munge

    # Copy key to other nodes
    echo "Copying munge key to other nodes..."
    for node in oss login compute1; do
        echo "  Copying to $node..."
        scp -o StrictHostKeyChecking=no /etc/munge/munge.key root@$node:/etc/munge/ || echo "  Failed to copy to $node, please copy manually"
    done
else
    # On compute nodes, ensure proper permissions
    chmod 700 /etc/munge
    chmod 400 /etc/munge/munge.key
    chown -R munge:munge /etc/munge
    chown -R munge:munge /var/lib/munge
    chown -R munge:munge /var/log/munge
    mkdir -p /var/run/munge
    chown -R munge:munge /var/run/munge
fi

# Double check firewall is disabled
echo "Making sure firewall is disabled..."
systemctl stop firewalld
systemctl disable firewalld

# Start/restart munge service and wait for it to be fully operational
echo "Starting munge service..."
systemctl enable munge
systemctl restart munge

# Wait for munge to fully start
echo "Waiting for munge to become available..."
sleep 3

# Test munge authentication with better error reporting
echo "Testing munge authentication..."
if ! munge -n | unmunge; then
    echo "✗ Munge authentication test failed! Check munge logs with 'journalctl -u munge'"
    echo "SLURM will not work without functioning munge authentication"
    exit 1
else
    echo "✓ Munge authentication is working properly"
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

    # Copy configuration to other nodes
    echo "Copying SLURM configuration to other nodes..."
    for node in oss login compute1; do
        echo "  Copying to $node..."
        scp -o StrictHostKeyChecking=no /etc/slurm/slurm.conf root@$node:/etc/slurm/ || echo "  Failed to copy to $node, please copy manually"

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
    sleep 10

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
    echo "Testing configuration with test job submission..."
    sudo -u vagrant bash -c "cd /home/vagrant && sbatch simple_job.sh" || {
        echo "WARNING: Job submission test failed. Checking configuration issues..."
        grep -i "SelectType" /etc/slurm/slurm.conf
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