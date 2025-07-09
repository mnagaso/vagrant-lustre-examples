#!/bin/bash
# Keycloak Container Management Script
# Provides easy commands to manage the Keycloak container

CONTAINER_NAME="keycloak"
SERVICE_NAME="keycloak-container"

usage() {
    echo "Usage: $0 {start|stop|restart|status|logs|shell|update|backup|restore}"
    echo ""
    echo "Commands:"
    echo "  start    - Start Keycloak container"
    echo "  stop     - Stop Keycloak container"
    echo "  restart  - Restart Keycloak container"
    echo "  status   - Show container status"
    echo "  logs     - Show container logs (use -f to follow)"
    echo "  shell    - Open shell in container"
    echo "  update   - Update to latest Keycloak image"
    echo "  backup   - Backup Keycloak data"
    echo "  restore  - Restore Keycloak data from backup"
    exit 1
}

check_container_exists() {
    if ! podman container exists "$CONTAINER_NAME"; then
        echo "Error: Container '$CONTAINER_NAME' does not exist"
        echo "Please run the install_keycloak.sh script first"
        exit 1
    fi
}

case "$1" in
    start)
        echo "Starting Keycloak container..."
        systemctl start "$SERVICE_NAME"
        echo "Keycloak container started"
        ;;
    stop)
        echo "Stopping Keycloak container..."
        systemctl stop "$SERVICE_NAME"
        echo "Keycloak container stopped"
        ;;
    restart)
        echo "Restarting Keycloak container..."
        systemctl restart "$SERVICE_NAME"
        echo "Keycloak container restarted"
        ;;
    status)
        echo "=== Systemd Service Status ==="
        systemctl status "$SERVICE_NAME" --no-pager -l
        echo ""
        echo "=== Container Status ==="
        if podman container exists "$CONTAINER_NAME"; then
            podman ps -a --filter name="$CONTAINER_NAME"
            echo ""
            echo "=== Container Health Check ==="
            if podman container exists "$CONTAINER_NAME" && [ "$(podman inspect --format='{{.State.Status}}' $CONTAINER_NAME)" = "running" ]; then
                echo "Testing Keycloak API endpoint..."
                if curl -s http://localhost:8080/realms/master/.well-known/openid-configuration >/dev/null; then
                    echo "✓ Keycloak API is responding"
                else
                    echo "✗ Keycloak API is not responding"
                fi
            else
                echo "Container is not running"
            fi
        else
            echo "Container does not exist"
        fi
        ;;
    logs)
        check_container_exists
        if [ "$2" = "-f" ] || [ "$2" = "--follow" ]; then
            echo "Following Keycloak container logs (Ctrl+C to exit)..."
            podman logs -f "$CONTAINER_NAME"
        else
            echo "=== Recent Keycloak Container Logs ==="
            podman logs --tail 50 "$CONTAINER_NAME"
        fi
        ;;
    shell)
        check_container_exists
        if [ "$(podman inspect --format='{{.State.Status}}' $CONTAINER_NAME)" != "running" ]; then
            echo "Error: Container is not running. Start it first."
            exit 1
        fi
        echo "Opening shell in Keycloak container..."
        podman exec -it "$CONTAINER_NAME" /bin/bash
        ;;
    update)
        echo "Updating Keycloak to latest version..."
        echo "This will stop the current container and create a new one with updated image"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Stopping current container..."
            systemctl stop "$SERVICE_NAME"

            echo "Backing up current data..."
            BACKUP_DIR="/opt/keycloak/backup/$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$BACKUP_DIR"
            cp -r /opt/keycloak/data "$BACKUP_DIR/"
            echo "Data backed up to: $BACKUP_DIR"

            echo "Removing old container..."
            podman rm "$CONTAINER_NAME"

            echo "Pulling latest image..."
            podman pull quay.io/keycloak/keycloak:latest

            echo "Creating new container..."
            ADMIN_PASSWORD=$(cat /root/keycloak_admin_password.txt | grep 'Admin password:' | cut -d' ' -f3)
            podman run -d \
              --name keycloak \
              --restart unless-stopped \
              -p 8080:8080 \
              -e KEYCLOAK_ADMIN=admin \
              -e KEYCLOAK_ADMIN_PASSWORD="$ADMIN_PASSWORD" \
              -e KC_HOSTNAME=192.168.10.60 \
              -e KC_HOSTNAME_STRICT=false \
              -e KC_HOSTNAME_STRICT_HTTPS=false \
              -e KC_HTTP_ENABLED=true \
              -e KC_PROXY=edge \
              -e KC_HOSTNAME_STRICT_BACKCHANNEL=false \
              -v /opt/keycloak/data:/opt/keycloak/data:Z \
              -v /opt/keycloak/themes:/opt/keycloak/themes:Z \
              -v /opt/keycloak/providers:/opt/keycloak/providers:Z \
              quay.io/keycloak/keycloak:latest \
              start --optimized

            echo "Starting updated container..."
            systemctl start "$SERVICE_NAME"
            echo "Update complete!"
        else
            echo "Update cancelled"
        fi
        ;;
    backup)
        echo "Creating backup of Keycloak data..."
        BACKUP_DIR="/opt/keycloak/backup/$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$BACKUP_DIR"

        # Stop container for consistent backup
        echo "Stopping container for consistent backup..."
        systemctl stop "$SERVICE_NAME"

        # Backup data
        cp -r /opt/keycloak/data "$BACKUP_DIR/"
        cp /root/keycloak_admin_password.txt "$BACKUP_DIR/" 2>/dev/null || true

        # Restart container
        echo "Restarting container..."
        systemctl start "$SERVICE_NAME"

        echo "Backup completed: $BACKUP_DIR"
        echo "Contents:"
        ls -la "$BACKUP_DIR"
        ;;
    restore)
        if [ -z "$2" ]; then
            echo "Usage: $0 restore <backup_directory>"
            echo "Available backups:"
            ls -la /opt/keycloak/backup/ 2>/dev/null || echo "No backups found"
            exit 1
        fi

        BACKUP_DIR="$2"
        if [ ! -d "$BACKUP_DIR" ]; then
            echo "Error: Backup directory '$BACKUP_DIR' does not exist"
            exit 1
        fi

        echo "Restoring Keycloak data from: $BACKUP_DIR"
        echo "This will replace all current data!"
        read -p "Continue? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Stopping container..."
            systemctl stop "$SERVICE_NAME"

            echo "Backing up current data..."
            CURRENT_BACKUP="/opt/keycloak/backup/pre_restore_$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$CURRENT_BACKUP"
            cp -r /opt/keycloak/data "$CURRENT_BACKUP/" 2>/dev/null || true

            echo "Restoring data..."
            rm -rf /opt/keycloak/data
            cp -r "$BACKUP_DIR/data" /opt/keycloak/

            if [ -f "$BACKUP_DIR/keycloak_admin_password.txt" ]; then
                cp "$BACKUP_DIR/keycloak_admin_password.txt" /root/
            fi

            echo "Starting container..."
            systemctl start "$SERVICE_NAME"
            echo "Restore complete!"
            echo "Previous data backed up to: $CURRENT_BACKUP"
        else
            echo "Restore cancelled"
        fi
        ;;
    *)
        usage
        ;;
esac
