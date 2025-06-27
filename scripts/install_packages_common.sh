#!/bin/bash
# Install common packages

# Configure dnf for best mirror performance
echo "Configuring dnf for fastest mirrors..."
cat >> /etc/dnf/dnf.conf <<EOF
fastestmirror=true
max_parallel_downloads=10
deltarpm=true
timeout=60
retries=5
EOF

# Update package cache
dnf makecache

dnf install -y epel-release linux-firmware
dnf install -y wget curl git vim kernel-devel perl
dnf install -y --enablerepo=powertools \
  libyaml-devel \
  libmount-devel

# install collectl
git clone https://github.com/sharkcz/collectl.git
cd collectl
sudo ./INSTALL
cd ..
rm -rf collectl
