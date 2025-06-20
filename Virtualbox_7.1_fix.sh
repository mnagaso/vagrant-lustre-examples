#!/bin/bash

# virtualbox_7.1_fix.sh - Script to apply the workaround for VirtualBox 7.1 with Vagrant

set -e  # Exit on error

VBOX_PATH="/usr/bin/VBox"
BACKUP_PATH="/usr/bin/VBox.backup"

echo "=========================================="
echo "VirtualBox 7.1 Workaround for Vagrant"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script needs to be run as root (sudo)."
    exit 1
fi

# Check if VirtualBox is installed
if ! command -v VBoxManage &> /dev/null; then
    echo "Error: VirtualBox doesn't appear to be installed."
    exit 1
fi

# Check VirtualBox version
VBOX_VERSION=$(VBoxManage --version)
echo "Detected VirtualBox version: $VBOX_VERSION"

# Check if the VBox script exists
if [ ! -f "$VBOX_PATH" ]; then
    echo "Error: $VBOX_PATH file not found."
    exit 1
fi

# Check if backup already exists
if [ -f "$BACKUP_PATH" ]; then
    echo "Backup file already exists. Either the fix has already been applied, or a previous attempt was interrupted."
    read -p "Do you want to proceed anyway? (y/n): " PROCEED
    if [[ ! "$PROCEED" =~ ^[Yy]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi
fi

# Create backup
echo "Creating backup of $VBOX_PATH at $BACKUP_PATH..."
cp "$VBOX_PATH" "$BACKUP_PATH"

# Apply the fix
echo "Applying workaround to $VBOX_PATH..."
sed -i '/VBoxManage|vboxmanage)/,/;;/c\    VBoxManage|vboxmanage)\n\tif [[ $@ == "--version" ]]; then\n\t  echo "7.0.0r164728"\n\telse\n          exec "$INSTALL_DIR/VBoxManage" "$@"\n\tfi\n        ;;' "$VBOX_PATH"

# Verify the fix was applied
if grep -q '7.0.0r164728' "$VBOX_PATH"; then
    echo "Workaround successfully applied!"
    echo ""
    echo "VirtualBox will now report version 7.0.0 to Vagrant"
    echo "but will otherwise function as version $VBOX_VERSION"
else
    echo "Error: Failed to apply the workaround."
    echo "Restoring backup..."
    cp "$BACKUP_PATH" "$VBOX_PATH"
    exit 1
fi

echo "=========================================="
echo "Workaround Applied Successfully!"
echo "You can now use Vagrant with VirtualBox 7.1"
echo "To revert this change, run: sudo cp $BACKUP_PATH $VBOX_PATH"
echo "=========================================="