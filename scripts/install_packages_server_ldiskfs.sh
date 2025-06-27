#!/bin/bash
# Install Lustre server packages with ldiskfs

yum --nogpgcheck --enablerepo=lustre-server install -y \
lustre-osd-ldiskfs-mount \
lustre
