#!/bin/bash
# Install Keycloak latest version (25.x) usin    -e KC_HOSTNAME=192.168.10.60 \
    -e KC_HOSTNAME_STRICT=false \
    -e KC_HTTP_ENABLED=true \
    -e KC_PROXY=edge \ntainer image
# Updated for 2025 - using official Keycloak container with Podman for better security

echo "==== Installing Keycloak (25.x) using Container Image ===="

# Configure dnf for fastest mirrors
echo "Configuring dnf for fastest mirrors..."
cat >> /etc/dnf/dnf.conf <<EOF
fastestmirror=true
max_parallel_downloads=10
deltarpm=true
timeout=60
retries=5
EOF

# Install Podman and required dependencies
echo "Installing Podman and dependencies..."
dnf install -y podman podman-docker container-selinux curl python3

# Set up Keycloak environment variables
KEYCLOAK_ADMIN="admin"
KEYCLOAK_ADMIN_PASSWORD="admin123"
KEYCLOAK_PORT="8080"
KEYCLOAK_VERSION="25.0"

echo "Setting up Keycloak container..."

# Pull Keycloak image
echo "Pulling Keycloak ${KEYCLOAK_VERSION} image..."
podman pull quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}

# Create Keycloak systemd service
echo "Creating Keycloak systemd service..."
cat > /etc/systemd/system/keycloak.service <<EOF
[Unit]
Description=Keycloak Container
After=network.target

[Service]
Type=exec
User=root
ExecStartPre=/usr/bin/podman rm -f keycloak || true
ExecStart=/usr/bin/podman run --name keycloak \\
    --rm \\
    -p ${KEYCLOAK_PORT}:8080 \\
    -e KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN} \\
    -e KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD} \\
    -e KC_HOSTNAME=192.168.10.60 \\
    -e KC_HOSTNAME_STRICT=false \\
    -e KC_HTTP_ENABLED=true \\
    -e KC_PROXY=edge \\
    quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} start-dev
ExecStop=/usr/bin/podman stop keycloak
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Keycloak service
echo "Enabling and starting Keycloak service..."
systemctl daemon-reload
systemctl enable keycloak

# Start Keycloak and check for immediate errors
echo "Starting Keycloak service..."
systemctl start keycloak

# Give it a moment to start
sleep 5

# Check if the service is running
if ! systemctl is-active --quiet keycloak; then
    echo "ERROR: Keycloak service failed to start. Checking logs..."
    journalctl -u keycloak --no-pager -l
    echo "Trying to start Keycloak manually to see error details..."
    podman run --rm -p ${KEYCLOAK_PORT}:8080 \
        -e KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN} \
        -e KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD} \
        -e KC_HOSTNAME=192.168.10.60 \
        -e KC_HOSTNAME_STRICT=false \
        -e KC_HTTP_ENABLED=true \
        -e KC_PROXY=edge \
        quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} start-dev &

    # Wait a moment for manual start
    sleep 10
fi

# Wait for Keycloak to be ready
echo "Waiting for Keycloak to start..."
sleep 30

# Check if Keycloak is running
echo "Checking Keycloak health endpoint..."
for i in {1..30}; do
    if curl -s http://localhost:${KEYCLOAK_PORT}/health/ready > /dev/null 2>&1; then
        echo "Keycloak is ready!"
        break
    elif curl -s http://localhost:${KEYCLOAK_PORT}/ > /dev/null 2>&1; then
        echo "Keycloak is responding but not fully ready yet... (attempt $i/30)"
    else
        echo "Waiting for Keycloak to be ready... (attempt $i/30)"
        # Check if the service is still running
        if ! systemctl is-active --quiet keycloak; then
            echo "WARNING: Keycloak service is not active. Checking logs..."
            journalctl -u keycloak --no-pager -l --lines=20
        fi
    fi
    sleep 10
done

# Final check
if ! curl -s http://localhost:${KEYCLOAK_PORT}/health/ready > /dev/null 2>&1; then
    echo "ERROR: Keycloak failed to start properly after 5 minutes"
    echo "Service status:"
    systemctl status keycloak
    echo "Recent logs:"
    journalctl -u keycloak --no-pager -l --lines=50
    exit 1
fi

# Configure Keycloak for Open OnDemand integration
echo "Configuring Keycloak for Open OnDemand..."

# Get admin access token
echo "Getting admin access token..."
ADMIN_TOKEN=$(curl -s -X POST http://localhost:${KEYCLOAK_PORT}/realms/master/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${KEYCLOAK_ADMIN}" \
    -d "password=${KEYCLOAK_ADMIN_PASSWORD}" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | \
    python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('access_token', ''))" 2>/dev/null)

if [ -z "$ADMIN_TOKEN" ]; then
    echo "ERROR: Failed to get admin access token. Checking if Keycloak is responding..."
    curl -v http://localhost:${KEYCLOAK_PORT}/realms/master/protocol/openid-connect/token \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=${KEYCLOAK_ADMIN}" \
        -d "password=${KEYCLOAK_ADMIN_PASSWORD}" \
        -d "grant_type=password" \
        -d "client_id=admin-cli"
    exit 1
fi

echo "Successfully obtained admin token"

# Create a new realm for Open OnDemand
echo "Creating OOD realm..."
curl -s -X POST http://localhost:${KEYCLOAK_PORT}/admin/realms \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
        "realm": "ood",
        "enabled": true,
        "displayName": "Open OnDemand",
        "registrationAllowed": true,
        "loginWithEmailAllowed": true,
        "duplicateEmailsAllowed": false,
        "resetPasswordAllowed": true,
        "editUsernameAllowed": false,
        "bruteForceProtected": true
    }'

# Create OIDC client for Open OnDemand
echo "Creating OIDC client for Open OnDemand..."
curl -s -X POST http://localhost:${KEYCLOAK_PORT}/admin/realms/ood/clients \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{
        "clientId": "ood-test",
        "name": "Open OnDemand Client",
        "enabled": true,
        "clientAuthenticatorType": "client-secret",
        "secret": "4eb876cd-acdb-4355-ba6e-3cefbb54f420",
        "standardFlowEnabled": true,
        "implicitFlowEnabled": false,
        "directAccessGrantsEnabled": true,
        "serviceAccountsEnabled": false,
        "publicClient": false,
        "protocol": "openid-connect",
        "redirectUris": [
            "https://192.168.10.50/oidc",
            "https://192.168.10.50/*"
        ],
        "webOrigins": [
            "https://192.168.10.50"
        ],
        "attributes": {
            "access.token.lifespan": "28800",
            "client.session.idle.timeout": "28800",
            "client.session.max.lifespan": "28800"
        }
    }'

# Create users using the unified script
echo "Creating Keycloak users..."
if [ -f "/vagrant/scripts/create_keycloak_users.sh" ]; then
    chmod +x /vagrant/scripts/create_keycloak_users.sh
    /vagrant/scripts/create_keycloak_users.sh
else
    echo "Warning: create_keycloak_users.sh not found, skipping user creation"
fi

# Configure firewall for Keycloak
echo "Configuring firewall for Keycloak..."
firewall-cmd --permanent --add-port=${KEYCLOAK_PORT}/tcp
firewall-cmd --reload

# Create a script to update Open OnDemand configuration with correct Keycloak URLs
echo "Creating update script for Open OnDemand configuration..."
cat > /tmp/update_ood_keycloak_config.sh <<'EOF'
#!/bin/bash
# Update Open OnDemand configuration to use local Keycloak

# Update the OIDC provider metadata URL
sed -i 's|OIDCProviderMetadataURL "https://idp.example.com/.well-known/openid-configuration"|OIDCProviderMetadataURL "http://192.168.10.60:8080/realms/ood/.well-known/openid-configuration"|' /etc/httpd/conf.d/auth_openidc.conf

# Restart Apache to apply changes
systemctl restart httpd
EOF

chmod +x /tmp/update_ood_keycloak_config.sh

echo "==== Keycloak Installation Complete ===="
echo ""
echo "Keycloak is now running on: http://192.168.10.60:${KEYCLOAK_PORT}"
echo "Admin console: http://192.168.10.60:${KEYCLOAK_PORT}/admin"
echo "Admin username: ${KEYCLOAK_ADMIN}"
echo "Admin password: ${KEYCLOAK_ADMIN_PASSWORD}"
echo ""
echo "Test users created:"
echo "  Username: user1, Password: password123"
echo "  Username: user2, Password: password123"
echo "  Username: user3, Password: password123"
echo "  Username: user4, Password: password123"
echo "  Username: user5, Password: password123"
echo "  Username: admin, Password: admin123"
echo ""
echo "To complete Open OnDemand integration, run:"
echo "  /tmp/update_ood_keycloak_config.sh"
echo ""
echo "OIDC Configuration:"
echo "  Realm: ood"
echo "  Client ID: ood-test"
echo "  Client Secret: 4eb876cd-acdb-4355-ba6e-3cefbb54f420"
echo "  Provider Metadata URL: http://192.168.10.60:${KEYCLOAK_PORT}/realms/ood/.well-known/openid-configuration"
echo "  Redirect URI: https://192.168.10.50/oidc"

