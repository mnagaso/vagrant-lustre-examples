#!/bin/bash

# Navigate to the app directory
cd "$(dirname "$0")"

# Install required packages
echo "Installing required packages..."
npm install --save @xterm/xterm @xterm/addon-fit @xterm/addon-web-links

echo "Installation complete."
chmod +x "$0"
