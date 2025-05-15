#!/bin/bash
# provision_iib_app.sh
# Copy iib_app to login node and set up/start Next.js server

set -e

LOGIN_NODE=login
LOGIN_USER=vagrant
IIB_APP_SRC="$(dirname "$0")/iib_app/"
IIB_APP_DEST="/home/vagrant/iib_app"
START_SCRIPT="/home/vagrant/start_nextjs.sh"

# Use vagrant scp if available, else use rsync with vagrant ssh-config
if command -v vagrant-scp &>/dev/null; then
  vagrant scp "$IIB_APP_SRC" "$LOGIN_NODE:$IIB_APP_DEST"
else
  # Generate SSH config for the login node
  vagrant ssh-config $LOGIN_NODE > /tmp/vagrant-ssh-$LOGIN_NODE
  # Remove old iib_app if exists
  vagrant ssh $LOGIN_NODE -c "rm -rf $IIB_APP_DEST"
  # Use rsync with the generated SSH config
  rsync -avz -e "ssh -F /tmp/vagrant-ssh-$LOGIN_NODE" "$IIB_APP_SRC" vagrant@192.168.10.30:$IIB_APP_DEST
fi

# Create start_nextjs.sh on the login node
vagrant ssh $LOGIN_NODE -c "cat > $START_SCRIPT <<'EOF'
#!/bin/bash
cd /home/vagrant/iib_app
sudo docker compose up -d
EOF
chmod +x $START_SCRIPT
chown vagrant:vagrant $START_SCRIPT"

echo "iib_app copied and start script created on login node."
echo "To start the Next.js server, run: vagrant ssh $LOGIN_NODE -c 'bash $START_SCRIPT'"
