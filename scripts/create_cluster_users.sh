#!/bin/bash
# Unified user creation script for all VMs
# Creates user1-user5 and admin accounts consistently across the cluster

# Cluster configuration (embedded for reliability)
CLUSTER_USERS="user1 user2 user3 user4 user5"
CLUSTER_USER_PASSWORD="password123"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"

echo "=== Creating cluster users ==="
echo "Users to create: $CLUSTER_USERS"
echo "Admin user: $ADMIN_USER"

# Function to create a user with standard settings
create_user() {
    local username=$1
    local password=$2
    local is_admin=${3:-false}

    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash "$username"
        echo "$username:$password" | chpasswd

        # Add Slurm environment for all users
        echo "export SLURM_CONF=/etc/slurm/slurm.conf" >> "/home/$username/.bashrc"

        # Add admin to wheel group if specified
        if [[ "$is_admin" == "true" ]]; then
            usermod -aG wheel "$username"
            echo "Created admin user: $username"
        else
            echo "Created user: $username"
        fi
    else
        echo "User $username already exists"
    fi
}

# Create standard cluster users
for user in $CLUSTER_USERS; do
    create_user "$user" "$CLUSTER_USER_PASSWORD"
done

# Create admin user
create_user "$ADMIN_USER" "$ADMIN_PASSWORD" "true"

# Create oodusers group if on OOD node (detect by checking if ood-portal-generator exists)
if [[ -x "/opt/ood/ood-portal-generator/sbin/update_ood_portal" ]]; then
    echo "Detected OOD node - creating oodusers group"
    if ! getent group oodusers &>/dev/null; then
        groupadd oodusers
        echo "Created group: oodusers"
    fi

    # Add all users to oodusers group
    for user in $CLUSTER_USERS; do
        usermod -aG oodusers "$user"
    done
    usermod -aG oodusers "$ADMIN_USER"
    echo "Added users to oodusers group"
fi

echo "=== User creation completed ==="
