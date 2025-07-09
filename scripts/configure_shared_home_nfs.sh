#!/bin/bash
# Configure NFS shared home directories
# Run this on all nodes after basic setup

HOSTNAME=$(hostname)
NFS_SERVER="login"  # Login node will be the NFS server
NFS_SERVER_IP="192.168.10.30"

echo "=== Configuring NFS shared home directories on $HOSTNAME ==="

# Install NFS packages
if command -v dnf >/dev/null 2>&1; then
    dnf install -y nfs-utils
elif command -v yum >/dev/null 2>&1; then
    yum install -y nfs-utils
fi

# Enable and start required services
systemctl enable rpcbind nfs-server
systemctl start rpcbind

if [ "$HOSTNAME" = "login" ]; then
    echo "=== Setting up NFS SERVER on login node ==="

    # Create backup of original home directories on other nodes
    echo "Creating shared home directory structure..."

    # Configure NFS exports
    cat > /etc/exports <<EOF
# NFS exports for shared home directories
/home 192.168.10.0/24(rw,sync,no_root_squash,no_subtree_check)
EOF

    # Export the filesystem
    exportfs -a

    # Start NFS server
    systemctl start nfs-server
    systemctl enable nfs-server

    # Configure firewall (if enabled)
    if systemctl is-active --quiet firewalld; then
        firewall-cmd --permanent --add-service=nfs
        firewall-cmd --permanent --add-service=rpc-bind
        firewall-cmd --permanent --add-service=mountd
        firewall-cmd --reload
    fi

    echo "✓ NFS server configured on login node"

else
    echo "=== Setting up NFS CLIENT on $HOSTNAME ==="

    # Wait for NFS server to be ready
    echo "Waiting for NFS server to be available..."
    for i in {1..30}; do
        if showmount -e $NFS_SERVER_IP >/dev/null 2>&1; then
            echo "✓ NFS server is ready"
            break
        fi
        echo "Waiting for NFS server... ($i/30)"
        sleep 5
    done

    # Backup existing home directories
    echo "Backing up existing home directories..."
    mkdir -p /home.backup
    if [ -d /home ] && [ "$(ls -A /home 2>/dev/null)" ]; then
        cp -a /home/* /home.backup/ 2>/dev/null || true
    fi

    # Create temporary mount point and mount NFS
    umount /home 2>/dev/null || true

    # Add to fstab for persistent mounting
    grep -v "/home" /etc/fstab > /etc/fstab.tmp
    echo "$NFS_SERVER_IP:/home /home nfs defaults,_netdev 0 0" >> /etc/fstab.tmp
    mv /etc/fstab.tmp /etc/fstab

    # Mount the NFS share
    mount /home

    if mountpoint -q /home; then
        echo "✓ NFS home directory mounted successfully"

        # Restore any local users that might not exist on the server
        if [ -d /home.backup ]; then
            echo "Checking for local users to restore..."
            for user_dir in /home.backup/*/; do
                if [ -d "$user_dir" ]; then
                    username=$(basename "$user_dir")
                    if [ ! -d "/home/$username" ] && [ "$username" != "lost+found" ]; then
                        echo "Restoring local user: $username"
                        cp -a "$user_dir" "/home/"
                    fi
                fi
            done
        fi
    else
        echo "ERROR: Failed to mount NFS home directory"
        exit 1
    fi
fi

echo "=== NFS home directory configuration completed on $HOSTNAME ==="
