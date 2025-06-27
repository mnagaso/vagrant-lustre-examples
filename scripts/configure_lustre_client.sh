#!/bin/bash
# Configure Lustre client

mkdir -p /lustre
mount -t lustre mxs@tcp0:/testhpc /lustre
chown -R vagrant:vagrant /lustre
