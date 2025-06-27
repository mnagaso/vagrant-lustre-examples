#!/bin/bash
# Install Lustre-patched kernel

curl -O https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server/RPMS/x86_64/kernel-4.18.0-553.27.1.el8_lustre.x86_64.rpm
curl -O https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server/RPMS/x86_64/kernel-core-4.18.0-553.27.1.el8_lustre.x86_64.rpm
curl -O https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server/RPMS/x86_64/kernel-modules-4.18.0-553.27.1.el8_lustre.x86_64.rpm
curl -O https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server/RPMS/x86_64/kernel-devel-4.18.0-553.27.1.el8_lustre.x86_64.rpm
curl -O https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server/RPMS/x86_64/kernel-headers-4.18.0-553.27.1.el8_lustre.x86_64.rpm
dnf install -y kernel-4.18.0-553.27.1.el8_lustre.x86_64.rpm \
kernel-core-4.18.0-553.27.1.el8_lustre.x86_64.rpm \
kernel-modules-4.18.0-553.27.1.el8_lustre.x86_64.rpm \
kernel-devel-4.18.0-553.27.1.el8_lustre.x86_64.rpm \
kernel-headers-4.18.0-553.27.1.el8_lustre.x86_64.rpm
rm -f *.rpm

# install e2fsprogs
dnf install -y --nogpgcheck --disablerepo=* --enablerepo=e2fsprogs-wc \
  e2fsprogs
