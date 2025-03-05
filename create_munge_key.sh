#!/bin/bash

# Script to create a munge key outside of VMs for consistent authentication

# Check if dd command is available
if ! command -v dd &> /dev/null; then
    echo "Error: dd command not found. Please install coreutils."
    exit 1
fi

echo "Creating munge key..."

# Create munge key
dd if=/dev/urandom bs=1 count=1024 > munge.key 2>/dev/null

# Set appropriate permissions - still secure but readable by Vagrant
chmod 600 munge.key

echo "Munge key created successfully as 'munge.key'"
echo "Use setup_slurm.sh to distribute this key to all nodes."
