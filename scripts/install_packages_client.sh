#!/bin/bash
# Install Lustre client packages

dnf install -y --enablerepo=lustre-client \
kmod-lustre-client \
lustre-client-dkms \
lustre-client
