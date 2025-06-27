#!/bin/bash
# Test script to diagnose Keycloak startup issues

echo "==== Keycloak Diagnostic Script ===="

KEYCLOAK_PORT="8080"

echo "1. Checking if Podman is installed..."
if command -v podman &> /dev/null; then
    echo "✓ Podman is installed: $(podman --version)"
else
    echo "✗ Podman is not installed"
    exit 1
fi

echo ""
echo "2. Checking Keycloak systemd service status..."
systemctl status keycloak --no-pager -l

echo ""
echo "3. Checking if Keycloak port is listening..."
if netstat -tlnp | grep :${KEYCLOAK_PORT}; then
    echo "✓ Port ${KEYCLOAK_PORT} is listening"
else
    echo "✗ Port ${KEYCLOAK_PORT} is not listening"
fi

echo ""
echo "4. Checking Keycloak container status..."
podman ps -a | grep keycloak || echo "No Keycloak containers found"

echo ""
echo "5. Checking Keycloak logs..."
echo "Recent systemd logs:"
journalctl -u keycloak --no-pager -l --lines=20

echo ""
echo "6. Testing Keycloak connectivity..."
if curl -s http://localhost:${KEYCLOAK_PORT}/ > /dev/null; then
    echo "✓ Keycloak is responding on port ${KEYCLOAK_PORT}"

    echo "Testing health endpoint..."
    if curl -s http://localhost:${KEYCLOAK_PORT}/health/ready > /dev/null; then
        echo "✓ Keycloak health endpoint is ready"
    else
        echo "⚠ Keycloak is responding but health endpoint is not ready"
    fi

    echo "Testing admin console..."
    if curl -s http://localhost:${KEYCLOAK_PORT}/admin > /dev/null; then
        echo "✓ Keycloak admin console is accessible"
    else
        echo "⚠ Keycloak admin console is not accessible"
    fi
else
    echo "✗ Keycloak is not responding on port ${KEYCLOAK_PORT}"
fi

echo ""
echo "7. Manual container test..."
echo "Trying to run Keycloak manually for debugging..."
podman run --rm --name keycloak-test \
    -p 8081:8080 \
    -e KEYCLOAK_ADMIN=admin \
    -e KEYCLOAK_ADMIN_PASSWORD=admin123 \
    -e KC_HOSTNAME=192.168.10.60 \
    -e KC_HOSTNAME_STRICT=false \
    -e KC_HTTP_ENABLED=true \
    -e KC_PROXY=edge \
    quay.io/keycloak/keycloak:25.0 start-dev &

MANUAL_PID=$!
echo "Manual container started with PID $MANUAL_PID on port 8081"
echo "Waiting 30 seconds for startup..."
sleep 30

if curl -s http://localhost:8081/ > /dev/null; then
    echo "✓ Manual Keycloak container is working"
    kill $MANUAL_PID
else
    echo "✗ Manual Keycloak container is not working"
    kill $MANUAL_PID
fi

echo ""
echo "==== Diagnostic Complete ===="
