#!/bin/bash

# Check for vagrant-scp plugin
if ! vagrant plugin list | grep -q vagrant-scp; then
    echo "vagrant-scp plugin not installed. Installing now..."
    vagrant plugin install vagrant-scp
fi

# Generate munge key if it doesn't exist
if [ ! -f "./munge.key" ]; then
    echo "Munge key not found. Generating a new one..."
    bash ./create_munge_key.sh
    if [ $? -ne 0 ]; then
        echo "Failed to create munge key. Exiting."
        exit 1
    fi
fi

# Define nodes
NODES=("mxs" "oss" "login" "compute1")

# Copy configuration script to all nodes
echo "Copying configuration script to all nodes..."
for NODE in "${NODES[@]}"; do
    vagrant scp ./slurm_update_config.sh ${NODE}:~/
done

# Copy slurm.conf to all nodes
echo "Copying slurm.conf to all nodes..."
for NODE in "${NODES[@]}"; do
    vagrant scp ./slurm.conf ${NODE}:~/
    vagrant ssh ${NODE} -c "sudo cp ~/slurm.conf /etc/slurm/slurm.conf && sudo chmod 644 /etc/slurm/slurm.conf"
done

# Copy munge key to all nodes
echo "Copying munge.key to all nodes..."
for NODE in "${NODES[@]}"; do
    echo "  - Copying to $NODE..."
    vagrant scp ./munge.key ${NODE}:~/
    vagrant ssh ${NODE} -c "sudo cp ~/munge.key /etc/munge/munge.key && sudo chmod 400 /etc/munge/munge.key && sudo chown munge:munge /etc/munge/munge.key"
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to copy or set permissions on munge key for $NODE"
        exit 1
    fi
done

# Fix permissions for munge
echo "Fixing munge permissions on all nodes..."
for NODE in "${NODES[@]}"; do
    vagrant ssh ${NODE} -c "sudo chmod 755 /var/run/munge"
done

# Configure all nodes with the updated slurm_update_config.sh script
echo "Configuring all nodes..."
for NODE in "${NODES[@]}"; do
    echo "Configuring $NODE..."
    vagrant ssh ${NODE} -c "sudo bash /home/vagrant/slurm_update_config.sh"
done

echo "SLURM configuration completed on all nodes"

# Test SLURM status
echo "Testing SLURM status..."
vagrant ssh mxs -c "sinfo"

# Test munge
#echo "Testing munge authentication between nodes..."
#vagrant ssh mxs -c "munge -n | ssh login unmunge" && echo "Munge authentication is working correctly!" || echo "Munge authentication failed!"

echo "Setting jobid_var for Lustre to enable job accounting."
vagrant ssh mxs -c "sudo lctl set_param -P jobid_var=SLURM_JOB_ID"

# check jovid_var on login
vagrant ssh login -c "sudo lctl get_param jobid_var"

# scp ./job_samples/*.sh to login node
echo "Copying job samples to login node..."
vagrant scp ./job_samples/*.sh login:/lustre/vagrant/
