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

# Configure Munge authentication
echo "Configuring munge authentication..."
if [ "$HOSTNAME" = "mxs" ]; then
    # On controller node, create the key
    echo "Creating new munge key..."
    dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key
    chmod 700 /etc/munge
    chmod 400 /etc/munge/munge.key
    chown -R munge:munge /etc/munge
    chown -R munge:munge /var/lib/munge
    chown -R munge:munge /var/log/munge
    chown -R munge:munge /var/run/munge 2>/dev/null || true

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
    chown -R munge:munge /var/run/munge 2>/dev/null || true
fi

# Start/restart munge service
echo "Starting munge service..."
systemctl enable munge
systemctl restart munge

# Test munge authentication
echo "Testing munge authentication..."
if munge -n | unmunge >/dev/null 2>&1; then
    echo "✓ Munge authentication is working properly"
else
    echo "✗ Munge authentication test failed!"
fi

# Configure SLURM
if [ "$HOSTNAME" = "mxs" ]; then
    echo "Configuring SLURM controller..."

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
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log
SlurmctldDebug=info
SlurmdDebug=info
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

    # Wait for controller to start
    sleep 5

    # Check controller status
    systemctl status slurmctld --no-pager

    # Check node status
    echo "Checking node status:"
    sinfo -N || echo "Failed to get node info. Check controller status."
else
    # On compute nodes, just start slurmd
    echo "Configuring SLURM compute node..."
    systemctl enable slurmd
    systemctl restart slurmd

    # Check status
    systemctl status slurmd --no-pager
fi

echo "SLURM configuration complete on $(hostname)."
echo "Run 'sinfo' to check cluster status."