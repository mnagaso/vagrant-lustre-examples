#!/bin/bash

# Define Lustre mount point
LUSTRE_MOUNT_POINT="/lustre"

# Ensure the Lustre file system is mounted
if mount | grep "$LUSTRE_MOUNT_POINT" > /dev/null; then
    echo "Lustre file system is already mounted at $LUSTRE_MOUNT_POINT."
else
    echo "Lustre file system is not mounted. Attempting to mount..."
    mount -t lustre <Lustre_Server>:/<Lustre_Share> $LUSTRE_MOUNT_POINT
    if [ $? -eq 0 ]; then
        echo "Lustre file system mounted successfully."
    else
        echo "Failed to mount Lustre file system. Exiting script."
        exit 1
    fi
fi

# Set Lustre environment variables
echo "Setting Lustre environment variables..."
export LUSTRE_HOME=$LUSTRE_MOUNT_POINT
export PATH=$PATH:/opt/lustre/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/lustre/lib

# Persist environment variables for Slurm jobs
echo "Persisting environment variables for Slurm jobs..."
echo "export LUSTRE_HOME=$LUSTRE_HOME" >> /etc/profile.d/lustre.sh
echo "export PATH=$PATH" >> /etc/profile.d/lustre.sh
echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> /etc/profile.d/lustre.sh
chmod +x /etc/profile.d/lustre.sh

# Configure Slurm to use Lustre accounting
echo "Configuring Slurm for Lustre accounting..."
SLURM_CONF="/etc/slurm/slurm.conf"

# Check if AcctGatherFilesystemType is already set
if grep -q "AcctGatherFilesystemType=acct_gather_filesystem/lustre" $SLURM_CONF; then
    echo "Slurm accounting is already configured for Lustre."
else
    # Add or modify AcctGatherFilesystemType in slurm.conf
    sed -i '/^AcctGatherFilesystemType=/d' $SLURM_CONF
    echo "AcctGatherFilesystemType=acct_gather_filesystem/lustre" >> $SLURM_CONF
    echo "AccountingStorageTRES=cpu,mem,fs/lustre" >> $SLURM_CONF
    echo "AccountingStorageType=accounting_storage/slurmdbd" >> $SLURM_CONF
    echo "Slurm accounting configured for Lustre."
fi

# Restart Slurm services to apply changes
echo "Restarting Slurm services..."
systemctl restart slurmctld
systemctl restart slurmd

# Verify Slurm accounting configuration
echo "Verifying Slurm accounting configuration..."
sacct -o JobID,JobName,MaxRSS,MaxDiskRead,MaxDiskWrite

echo "Setting jobid_var for Lustre to enable job accounting."
if [ "$(hostname)" = "mxs" ]; then
    lctl set_param -P jobid_var=SLURM_JOB_ID
fi

echo "Slurm and Lustre integration script completed successfully."
