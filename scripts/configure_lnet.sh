#!/bin/bash
# Configure LNET networking

echo "options lnet networks=tcp0(eth1)" > /etc/modprobe.d/lnet.conf
