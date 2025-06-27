#!/bin/bash
# Configure Lustre OSS server with ZFS

modprobe -v lnet
modprobe -v lustre
modprobe -v zfs

# Check if mounts exist and unmount them
if mountpoint -q /lustre/testhpc/ost0; then
  umount -f /lustre/testhpc/ost0
fi
if mountpoint -q /lustre/testhpc/ost1; then
  umount -f /lustre/testhpc/ost1
fi

# Destroy existing ZFS pools if they exist
if zpool list | grep -q ostpool0; then
  zpool destroy -f ostpool0
fi
if zpool list | grep -q ostpool1; then
  zpool destroy -f ostpool1
fi

# Now create the pools and OSTs
zpool create ostpool0 /dev/sdb
zpool create ostpool1 /dev/sdc
mkfs.lustre --reformat --backfstype=zfs --ost --fsname testhpc --index 0 --mgsnode mxs@tcp0 ostpool0/ost0
mkfs.lustre --reformat --backfstype=zfs --ost --fsname testhpc --index 1 --mgsnode mxs@tcp0 ostpool1/ost1
mkdir -p /lustre/testhpc/ost0
mkdir -p /lustre/testhpc/ost1
mount -t lustre ostpool0/ost0 /lustre/testhpc/ost0
mount -t lustre ostpool1/ost1 /lustre/testhpc/ost1
