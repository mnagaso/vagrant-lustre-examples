#!/bin/bash
# Create Keycloak users to match the cluster users
# This script should be run after Keycloak is installed and configured

# Cluster configuration (embedded for reliability)
CLUSTER_USERS="user1 user2 user3 user4 user5"
CLUSTER_USER_PASSWORD="password123"
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"
KEYCLOAK_REALM="ood"
KEYCLOAK_PORT="8080"

echo "=== Creating Keycloak users to match cluster ==="
echo "Users to create: $CLUSTER_USERS"
echo "Admin user: $ADMIN_USER"
echo "Keycloak: http://localhost:$KEYCLOAK_PORT"

# Get admin access token
echo "Getting admin access token..."
ADMIN_TOKEN=$(curl -s -X POST http://localhost:${KEYCLOAK_PORT}/realms/master/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=admin" \
    -d "password=admin123" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('access_token', ''))" 2>/dev/null)

if [ -z "$ADMIN_TOKEN" ]; then
    echo "ERROR: Failed to get admin access token"
    exit 1
fi

echo "Successfully obtained admin token"

# Function to create a user in Keycloak
create_keycloak_user() {
    local username=$1
    local password=$2
    local firstname=$3
    local lastname=$4

    echo "Creating Keycloak user: $username"
    curl -s -X POST http://localhost:${KEYCLOAK_PORT}/admin/realms/${KEYCLOAK_REALM}/users \
        -H "Authorization: Bearer ${ADMIN_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{
            \"username\": \"$username\",
            \"enabled\": true,
            \"firstName\": \"$firstname\",
            \"lastName\": \"$lastname\",
            \"email\": \"$username@example.com\",
            \"emailVerified\": true,
            \"credentials\": [{
                \"type\": \"password\",
                \"value\": \"$password\",
                \"temporary\": false
            }]
        }"
}

# Create cluster users in Keycloak
user_count=1
for user in $CLUSTER_USERS; do
    create_keycloak_user "$user" "$CLUSTER_USER_PASSWORD" "User" "$user_count"
    ((user_count++))
done

# Create admin user in Keycloak
create_keycloak_user "$ADMIN_USER" "$ADMIN_PASSWORD" "Admin" "User"

echo "=== Keycloak user creation completed ==="
echo "Created users: $CLUSTER_USERS $ADMIN_USER"
echo "All users have consistent passwords as defined in cluster_config.sh"
