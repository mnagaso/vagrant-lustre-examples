#!/bin/bash
# Configure Lustre client

mkdir -p /lustre
mount -t lustre mxs@tcp0:/testhpc /lustre
# Set proper permissions for the Lustre mount point
# Allow all users to access the filesystem, but keep root ownership
chmod 755 /lustre
