#!/bin/bash

# Script to distribute rocky95.sif container to all cluster users
# This script should be run after user creation to ensure all users have access

set -e

# Variables
MASTER_CONTAINER="/home/vagrant/rocky95.sif"
#USERS=("user1" "user2" "user3" "user4" "user5")
USERS=("user1")

# Function to print colored output
print_status() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

print_status "Distributing rocky95.sif container to cluster users..."

# Check if master container exists
if [[ ! -f "$MASTER_CONTAINER" ]]; then
    print_error "Master container not found at $MASTER_CONTAINER"
    print_error "Please run install_singularity.sh first"
    exit 1
fi

print_status "Master container found: $MASTER_CONTAINER"
print_status "Size: $(du -h $MASTER_CONTAINER | cut -f1)"

# Distribute to each user
for user in "${USERS[@]}"; do
    if id "$user" &>/dev/null; then
        USER_HOME="/home/$user"

        print_status "Copying container to $user..."

        # Copy the container
        cp "$MASTER_CONTAINER" "$USER_HOME/rocky95.sif"
        chown "$user:$user" "$USER_HOME/rocky95.sif"

        # Create convenience script
        cat <<EOF > "$USER_HOME/run_container.sh"
#!/bin/bash
# Convenience script to run the Rocky 9.5 container

CONTAINER_PATH="$USER_HOME/rocky95.sif"

if [[ ! -f "\${CONTAINER_PATH}" ]]; then
    echo "Error: Container file not found at \${CONTAINER_PATH}"
    exit 1
fi

echo "Running Rocky Linux 9.5 container..."
echo "Available commands:"
echo "  shell  - Interactive shell"
echo "  run    - Run container's default runscript"
echo "  exec   - Execute a specific command"
echo ""

case "\$1" in
    shell)
        singularity shell "\${CONTAINER_PATH}"
        ;;
    run)
        shift
        singularity run "\${CONTAINER_PATH}" "\$@"
        ;;
    exec)
        shift
        singularity exec "\${CONTAINER_PATH}" "\$@"
        ;;
    *)
        echo "Usage: \$0 {shell|run|exec} [arguments...]"
        echo ""
        echo "Examples:"
        echo "  \$0 shell                    # Interactive shell"
        echo "  \$0 run                      # Show container info"
        echo "  \$0 exec python3 --version  # Execute python3 command"
        exit 1
        ;;
esac
EOF

        chmod +x "$USER_HOME/run_container.sh"
        chown "$user:$user" "$USER_HOME/run_container.sh"

        print_status "✓ Container and script copied to $user"

        # Test the container for this user
        if su - "$user" -c "singularity exec $USER_HOME/rocky95.sif echo 'Container test for $user successful!'" &>/dev/null; then
            print_status "✓ Container test passed for $user"
        else
            print_error "✗ Container test failed for $user"
        fi

    else
        print_status "User $user does not exist, skipping..."
    fi
done

print_status ""
print_status "Container distribution summary:"
for user in "${USERS[@]}"; do
    if [[ -f "/home/$user/rocky95.sif" ]]; then
        print_status "✓ $user: /home/$user/rocky95.sif ($(du -h /home/$user/rocky95.sif | cut -f1))"
    else
        print_status "✗ $user: Not available"
    fi
done

print_status ""
print_status "Container distribution completed!"
print_status ""
print_status "Users can now run:"
print_status "  ~/run_container.sh shell"
print_status "  singularity shell ~/rocky95.sif"
print_status "  singularity exec ~/rocky95.sif python3 --version"
