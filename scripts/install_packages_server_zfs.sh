#!/bin/bash
# Install Lustre server packages with ZFS

dnf install -y https://zfsonlinux.org/epel/zfs-release-2-3$(rpm --eval "%{dist}").noarch.rpm
dnf install -y --enablerepo=powertools libaec
sudo dnf --enablerepo=lustre-server install -y lustre-dkms lustre-osd-zfs-mount lustre
