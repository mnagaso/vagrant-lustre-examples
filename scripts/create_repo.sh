#!/bin/bash
# Create Lustre repositories

cat > /etc/yum.repos.d/e2fsprogs-wc.repo <<EOF
[e2fsprogs-wc]
name=e2fsprogs-wc
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/1.47.1.wc2/el8
gpgcheck=0
enabled=0
EOF

cat > /etc/yum.repos.d/lustre-server.repo <<EOF
[lustre-server]
name=lustre-server
baseurl=https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server
gpgcheck=0
enabled=0
EOF

cat > /etc/yum.repos.d/lustre-client.repo <<EOF
[lustre-client]
name=lustre-client
baseurl=https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/client
gpgcheck=0
enabled=0
EOF
