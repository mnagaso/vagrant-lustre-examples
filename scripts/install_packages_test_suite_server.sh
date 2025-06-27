#!/bin/bash
# Install Lustre test suite for server

sudo dnf install -y --enablerepo=lustre-server lustre-devel kmod-lustre-tests lustre-iokit lustre-tests
