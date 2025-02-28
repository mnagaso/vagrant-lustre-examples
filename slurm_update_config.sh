#!/bin/bash
# SLURM configuration script - run on each node after Vagrant provisioning

HOSTNAME=$(hostname -s)
echo "==== Configuring SLURM for node: $HOSTNAME ===="

# Create required directories with proper permissions
echo "Creating SLURM directories..."
mkdir -p /var/spool/slurmd
mkdir -p /var/spool/slurmctld
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

    # Set controller-specific directory permissions
    chown slurm:slurm /var/spool/slurmctld
    chown slurm:slurm /var/log/slurm
    chown slurm:slurm /var/run/slurm
    chmod 755 /var/spool/slurmctld
    chmod 755 /var/log/slurm
    chmod 755 /var/run/slurm

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

# Process tracking - Updated to be more compatible with newer OS
ProctrackType=proctrack/linuxproc
TaskPlugin=task/none

# Scheduling
SchedulerType=sched/backfill
SelectType=select/linear
SelectTypeParameters=CR_Core

# Logging
SlurmctldDebug=verbose
SlurmdDebug=verbose
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log
DebugFlags=backfill

# Job completion handling
JobCompType=jobcomp/none

# Paths and directories
SlurmdSpoolDir=/var/spool/slurmd
StateSaveLocation=/var/spool/slurmctld
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

    # Check if port 6817 is already in use
    echo "Checking if SLURM controller port is available..."
    if ss -tulpn | grep -q ":6817"; then
        echo "WARNING: Port 6817 is already in use. SLURM controller may not start properly."
    fi

    # Copy configuration to other nodes
    echo "Copying SLURM configuration to other nodes..."
    for node in oss login compute1; do
        echo "  Copying to $node..."
        scp -o StrictHostKeyChecking=no /etc/slurm/slurm.conf root@$node:/etc/slurm/ || echo "  Failed to copy to $node, please copy manually"
    done

    # Start controller service
    echo "Starting SLURM controller service..."
    systemctl enable slurmctld
    systemctl restart slurmctld

    # Wait for controller to start - give it more time
    echo "Waiting for SLURM controller to start..."
    sleep 10

    # Check controller status with better error handling
    if ! systemctl is-active --quiet slurmctld; then
        echo "ERROR: SLURM controller failed to start. Checking logs:"
        journalctl -u slurmctld --no-pager | tail -n 20
    else
        echo "SLURM controller started successfully!"
        systemctl status slurmctld --no-pager
    fi

    # Check node status with better error handling
    echo "Checking node status:"
    sinfo -N || echo "Failed to get node info. Check controller status with 'journalctl -u slurmctld'"
else
    # On compute nodes, just start slurmd
    echo "Configuring SLURM compute node..."
    systemctl stop slurmd || true
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