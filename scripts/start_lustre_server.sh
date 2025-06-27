#!/bin/bash
# Start Lustre server services

systemctl stop firewalld
systemctl disable firewalld
systemctl enable lnet
systemctl start lnet
systemctl enable lustre
systemctl start lustre
