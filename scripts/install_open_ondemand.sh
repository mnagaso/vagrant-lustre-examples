#!/bin/bash
# Install Open OnDemand

echo "==== Installing Open OnDemand ===="

# Install basic dependencies
dnf install -y epel-release
dnf module enable ruby:3.3 nodejs:20 -y
dnf install -y --enablerepo=powertools lua-posix

# Install Open OnDemand repository
dnf install -y https://yum.osc.edu/ondemand/4.0/ondemand-release-web-4.0-1.el8.noarch.rpm
dnf install -y ondemand

dnf install -y mod_auth_openidc

echo "Open OnDemand installation complete."
