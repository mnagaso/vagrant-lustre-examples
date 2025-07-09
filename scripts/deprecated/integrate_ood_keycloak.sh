#!/bin/bash
# Update Open OnDemand configuration to integrate with local Keycloak
# This script should be run after both Keycloak and Open OnDemand are installed

echo "==== Updating Open OnDemand Configuration for Keycloak Integration ===="

# Check if Keycloak is running
if ! curl -s http://192.168.10.60:8080/health/ready > /dev/null; then
    echo "ERROR: Keycloak is not running or not accessible at http://192.168.10.60:8080"
    echo "Please ensure Keycloak is installed and running before running this script."
    exit 1
fi

# Check if Open OnDemand is installed
if [ ! -f "/etc/httpd/conf.d/auth_openidc.conf" ]; then
    echo "ERROR: Open OnDemand auth_openidc.conf not found."
    echo "Please install and configure Open OnDemand first."
    exit 1
fi

# Backup existing configuration
echo "Backing up existing Open OnDemand configuration..."
cp /etc/httpd/conf.d/auth_openidc.conf /etc/httpd/conf.d/auth_openidc.conf.bak.$(date +%Y%m%d_%H%M%S)

# Update the OIDC provider metadata URL to point to local Keycloak
echo "Updating OIDC provider metadata URL..."
sed -i 's|OIDCProviderMetadataURL "https://idp.example.com/.well-known/openid-configuration"|OIDCProviderMetadataURL "http://192.168.10.60:8080/realms/ood/.well-known/openid-configuration"|' /etc/httpd/conf.d/auth_openidc.conf

# Verify the Keycloak realm is accessible
echo "Verifying Keycloak OIDC configuration..."
if curl -s http://192.168.10.60:8080/realms/ood/.well-known/openid-configuration > /dev/null; then
    echo "✓ Keycloak OIDC configuration is accessible"
else
    echo "⚠ WARNING: Keycloak OIDC configuration may not be ready yet. Wait a moment and try again."
fi

# Restart Apache to apply changes
echo "Restarting Apache to apply configuration changes..."
systemctl restart httpd

# Check Apache status
if systemctl is-active --quiet httpd; then
    echo "✓ Apache restarted successfully"
else
    echo "✗ Apache failed to restart. Check logs with: journalctl -u httpd"
    exit 1
fi

echo ""
echo "==== Open OnDemand - Keycloak Integration Complete ===="
echo ""
echo "Access URLs:"
echo "  Open OnDemand: https://192.168.10.50"
echo "  Keycloak Admin: http://192.168.10.60:8080/admin"
echo "  Keycloak Realm: http://192.168.10.60:8080/realms/ood"
echo ""
echo "Test Login Credentials:"
echo "  Username: testuser"
echo "  Password: password123"
echo ""
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "Configuration Details:"
echo "  OIDC Provider: http://192.168.10.60:8080/realms/ood/.well-known/openid-configuration"
echo "  Client ID: ood-test"
echo "  Redirect URI: https://192.168.10.50/oidc"
