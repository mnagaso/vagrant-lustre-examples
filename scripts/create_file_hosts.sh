#!/bin/bash
# Create /etc/hosts file for cluster communication

hosts='127.0.0.1     localhost localhost.localdomain localhost4 localhost4.localdomain4
::1           localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.10.10 mxs
192.168.10.20 oss
192.168.10.30 login
192.168.10.40 compute1
192.168.10.50 ood
192.168.10.60 keycloak'

echo "$hosts" > /etc/hosts
