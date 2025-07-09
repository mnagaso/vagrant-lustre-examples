#!/bin/bash

# Create system users for Open OnDemand
# These users need to exist on the system for OOD to work properly

echo "Creating system users for Open OnDemand..."

# Create user1-user5 to match login node
for i in {1..5}; do
    username="user$i"
    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash "$username"
        echo "$username:password123" | chpasswd
        echo "Created user: $username"
    else
        echo "User $username already exists"
    fi
done

# Create admin user
if ! id "admin" &>/dev/null; then
    useradd -m -s /bin/bash admin
    echo "admin:admin123" | chpasswd
    # Add admin to wheel group for sudo access
    usermod -aG wheel admin
    echo "Created user: admin"
else
    echo "User admin already exists"
fi

# Create a general ood user group if needed
if ! getent group oodusers &>/dev/null; then
    groupadd oodusers
    echo "Created group: oodusers"
fi

# Add users to oodusers group
for i in {1..5}; do
    usermod -aG oodusers "user$i"
done
usermod -aG oodusers admin

echo "System users created successfully!"
echo "Users can now log in to Open OnDemand with their Keycloak credentials"
