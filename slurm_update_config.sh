#!/bin/bash
# Simplified SLURM configuration script - removes operations already handled in Vagrantfile

HOSTNAME=$(hostname -s)
echo "==== Configuring SLURM for node: $HOSTNAME ===="

# Ensure time synchronization
dnf install -y chrony > /dev/null 2>&1
systemctl enable chronyd
systemctl restart chronyd

# Define cluster nodes
CLUSTER_NODES=("oss" "login" "compute1")

# Controller node specific tasks - only create the munge key on the controller
if [ "$HOSTNAME" = "mxs" ]; then
    # Create munge key
    echo "Creating munge key on controller..."
    dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key
    chmod 400 /etc/munge/munge.key
    chown munge:munge /etc/munge/munge.key

    # Copy munge key to all other nodes
    echo "Distributing munge key to other nodes..."
    for NODE in "${CLUSTER_NODES[@]}"; do
        echo "  - Copying to $NODE..."
        scp -o StrictHostKeyChecking=no /etc/munge/munge.key ${NODE}:/etc/munge/
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to copy munge key to $NODE"
            exit 1
        fi

        # Set proper permissions on remote node
        ssh -o StrictHostKeyChecking=no ${NODE} "chmod 400 /etc/munge/munge.key && chown munge:munge /etc/munge/munge.key"
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to set permissions on $NODE"
            exit 1
        fi
    done
    echo "Munge key distribution complete."
fi

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
SlurmctldDebug=info
SlurmdDebug=info
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdLogFile=/var/log/slurm/slurmd.log

# Job completion handling
JobCompType=jobcomp/none
AccountingStorageType=accounting_storage/none

# Paths and directories
SlurmdSpoolDir=/var/spool/slurmd
StateSaveLocation=/var/spool/slurmctld/state
SlurmctldPidFile=/var/run/slurm/slurmctld.pid
SlurmdPidFile=/var/run/slurm/slurmd.pid

# Users
SlurmUser=slurm
SlurmdUser=root

# Node configuration - IMPORTANT to match actual hardware
# Update these values based on your actual hardware
NodeName=mxs CPUs=2 Boards=1 SocketsPerBoard=1 CoresPerSocket=2 ThreadsPerCore=1 RealMemory=400 State=UNKNOWN
NodeName=oss CPUs=2 Boards=1 SocketsPerBoard=1 CoresPerSocket=2 ThreadsPerCore=1 RealMemory=400 State=UNKNOWN
NodeName=login CPUs=2 Boards=1 SocketsPerBoard=1 CoresPerSocket=2 ThreadsPerCore=1 RealMemory=400 State=UNKNOWN
NodeName=compute1 CPUs=2 Boards=1 SocketsPerBoard=1 CoresPerSocket=2 ThreadsPerCore=1 RealMemory=400 State=UNKNOWN

## Node definitions - Set non-compute nodes to NOT_IDLE to prevent job scheduling
#NodeName=mxs NodeAddr=192.168.10.10 CPUs=2 RealMemory=400 State=UNKNOWN Features=controller
#NodeName=oss NodeAddr=192.168.10.20 CPUs=2 RealMemory=400 State=UNKNOWN Features=storage
#NodeName=login NodeAddr=192.168.10.30 CPUs=2 RealMemory=400 State=UNKNOWN Features=login
#NodeName=compute1 NodeAddr=192.168.10.40 CPUs=2 RealMemory=400 State=UNKNOWN Features=compute

# Partition definitions - Only include compute1 in the compute partition
PartitionName=controller Nodes=mxs Default=NO MaxTime=INFINITE State=UP AllowGroups=root
PartitionName=storage Nodes=oss Default=NO MaxTime=INFINITE State=UP AllowGroups=root
PartitionName=login Nodes=login Default=NO MaxTime=INFINITE State=UP AllowGroups=root
PartitionName=compute Nodes=compute1 Default=YES MaxTime=INFINITE State=UP
EOF

    chmod 644 /etc/slurm/slurm.conf

    # Copy slurm.conf to all compute nodes
    for NODE in "${CLUSTER_NODES[@]}"; do
        echo "Copying slurm.conf to $NODE..."
        scp -o StrictHostKeyChecking=no /etc/slurm/slurm.conf ${NODE}:/etc/slurm/
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to copy slurm.conf to $NODE"
        fi
    done

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