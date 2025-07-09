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
#NODES=("mxs" "oss" "login" "compute1" "ood")
NODES=("login" "compute1" "ood")

# Copy configuration script to all nodes
echo "Copying configuration script to all nodes..."
for NODE in "${NODES[@]}"; do
    echo "  - Copying to $NODE..."
    vagrant scp ./slurm_update_config.sh ${NODE}:~/
done

# Copy slurm.conf to all nodes
echo "Copying slurm.conf to all nodes..."
for NODE in "${NODES[@]}"; do
    vagrant scp ./slurm.conf ${NODE}:~/
    vagrant ssh ${NODE} -c "sudo mv ~/slurm.conf /etc/slurm/slurm.conf && sudo chmod 644 /etc/slurm/slurm.conf"
done

# Copy munge key to all nodes
echo "Copying munge.key to all nodes..."
for NODE in "${NODES[@]}"; do
    echo "  - Copying to $NODE..."
    vagrant scp ./munge.key ${NODE}:~/
    vagrant ssh ${NODE} -c "sudo mv ~/munge.key /etc/munge/munge.key && sudo chmod 400 /etc/munge/munge.key && sudo chown munge:munge /etc/munge/munge.key"
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
vagrant ssh login -c "sinfo"

# Resume compute nodes to make them idle/available for jobs
echo "Resuming compute nodes to make them available for jobs..."
# Note:
# - mxs: controller node (shows as 'unk*' - normal)
# - oss: storage node (should remain in restricted partition)
# - login: login node (should remain in restricted partition)
# - compute1: actual compute node for running jobs

# Check if compute1 needs to be resumed (only if it's in drain/down state)
COMPUTE1_STATE=$(vagrant ssh login -c "sinfo -h -n compute1 -o %T" 2>/dev/null | tr -d '\r\n')
echo "Current compute1 state: $COMPUTE1_STATE"

if [[ "$COMPUTE1_STATE" == *"drain"* ]] || [[ "$COMPUTE1_STATE" == *"down"* ]]; then
    echo "Resuming compute1 node..."
    vagrant ssh login -c "sudo scontrol update NodeName=compute1 State=RESUME"
else
    echo "compute1 is already in working state ($COMPUTE1_STATE), no need to resume"
fi

# Wait a moment for nodes to register properly
echo "Waiting for nodes to register..."
sleep 5

# Test munge
#echo "Testing munge authentication between nodes..."
#vagrant ssh mxs -c "munge -n | ssh login unmunge" && echo "Munge authentication is working correctly!" || echo "Munge authentication failed!"

echo "Setting jobid_var for Lustre to enable job accounting."
# Wait for MDT to become available
vagrant ssh mxs -c "sudo lctl wait_for_param mdt.*.state=active"

vagrant ssh mxs -c "sudo lctl set_param -P jobid_var=SLURM_JOB_ID"
#vagrant ssh mxs -c "sudo lctl set_param -P jobid_var=procname_uid"

# check jobid_var on mxs
vagrant ssh mxs -c "sudo lctl get_param jobid_var"

# scp ./job_samples/*.sh to login node
echo "Copying job samples to login node..."
vagrant scp ./job_samples/*.sh login:/lustre/vagrant/
vagrant scp ./job_samples/*.sh login:/lustre/user1/

# Final status check - show all nodes should be idle/available
echo "Final SLURM cluster status:"
vagrant ssh login -c "sinfo -a"
#echo "Detailed node information:"
#vagrant ssh mxs -c "sinfo -Nel"

echo "SLURM cluster setup completed successfully!"
