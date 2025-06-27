# Cluster User Configuration
# This file centralizes all user account settings for the Lustre cluster

# Standard users (created on all compute nodes)
CLUSTER_USERS="user1 user2 user3 user4 user5"
CLUSTER_USER_PASSWORD="password123"

# Administrative user
ADMIN_USER="admin"
ADMIN_PASSWORD="admin123"

# Keycloak configuration
KEYCLOAK_REALM="ood"
KEYCLOAK_CLIENT_ID="ood-test"
KEYCLOAK_CLIENT_SECRET="4eb876cd-acdb-4355-ba6e-3cefbb54f420"

# Network configuration
KEYCLOAK_IP="192.168.10.60"
KEYCLOAK_PORT="8080"
OOD_IP="192.168.10.50"

# Function to source this configuration
load_cluster_config() {
    echo "Loaded cluster configuration:"
    echo "  Users: $CLUSTER_USERS"
    echo "  Admin: $ADMIN_USER"
    echo "  Keycloak: http://$KEYCLOAK_IP:$KEYCLOAK_PORT"
    echo "  OOD: https://$OOD_IP"
}
