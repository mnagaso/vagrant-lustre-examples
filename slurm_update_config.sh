#!/bin/bash
# Simplified SLURM configuration script

HOSTNAME=$(hostname -s)
echo "==== Configuring SLURM for node: $HOSTNAME ===="

# Ensure time synchronization
systemctl restart chronyd
chronyc makestep || true

# Create required directories
mkdir -p /var/spool/slurmd
mkdir -p /var/spool/slurmctld/state
mkdir -p /var/log/slurm
mkdir -p /var/run/slurm

# Set basic permissions
chown root:root /var/spool/slurmd
chmod 755 /var/spool/slurmd

# Configure Munge authentication
echo "Configuring munge authentication..."
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

# Controller node specific tasks
if [ "$HOSTNAME" = "mxs" ]; then
    # Create and distribute munge key
    systemctl stop munge
    dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key
    chmod 400 /etc/munge/munge.key
    chown munge:munge /etc/munge/munge.key

    # Copy key to other nodes
    echo "Copying munge key to other nodes..."
    for node in oss login compute1; do
        echo "  Copying to $node..."
        scp -o StrictHostKeyChecking=no /etc/munge/munge.key root@$node:/etc/munge/
        ssh -o StrictHostKeyChecking=no root@$node "chmod 400 /etc/munge/munge.key; chown munge:munge /etc/munge/munge.key"
        ssh -o StrictHostKeyChecking=no root@$node "systemctl stop munge"
    done
fi

# Stop firewall
systemctl stop firewalld
systemctl disable firewalld

# Start munge and wait for socket initialization
systemctl enable munge
systemctl restart munge
sleep 5  # Wait for munge to initialize

# Test munge
if ! munge -n | unmunge; then
    echo "✗ Munge authentication failed!"
    exit 1
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

    # Install mail if needed
    dnf install -y mailx || true

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

    # Copy configuration to other nodes
    for node in oss login compute1; do
        echo "  Copying config to $node..."
        scp -o StrictHostKeyChecking=no /etc/slurm/slurm.conf root@$node:/etc/slurm/
        ssh -o StrictHostKeyChecking=no root@$node "systemctl restart slurmd"
    done

    # Start controller service
    systemctl enable slurmctld
    systemctl restart slurmctld
    sleep 10

    # Check status
    if systemctl is-active --quiet slurmctld; then
        echo "SLURM controller started successfully!"
    else
        echo "ERROR: SLURM controller failed to start"
        journalctl -u slurmctld --no-pager | tail -n 10
    fi

    # Show node status
    sinfo -N || echo "Failed to get node info"

else
    # Compute node configuration
    echo "Configuring SLURM compute node..."
    systemctl stop slurmd || true
    systemctl enable slurmd
    systemctl restart slurmd

    if systemctl is-active --quiet slurmd; then
        echo "SLURM compute daemon started successfully!"
    else
        echo "ERROR: SLURM compute daemon failed to start"
        journalctl -u slurmd --no-pager | tail -n 10
    fi
fi

echo "SLURM configuration complete on $(hostname)."