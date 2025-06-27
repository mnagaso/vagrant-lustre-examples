#!/bin/bash
# Configure Lustre MGS/MDS server

modprobe -v lnet
modprobe -v lustre
mkdir /mnt/mdt
mkfs.lustre --reformat --backfstype=ldiskfs --fsname=testhpc --mgs --mdt --index=0 /dev/sdb
mount -t lustre /dev/sdb /mnt/mdt
