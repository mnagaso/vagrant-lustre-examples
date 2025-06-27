#!/bin/bash
# Configure login node

# Install user environment packages
dnf install -y vim emacs nano screen tmux environment-modules

# Create shared applications directory
mkdir -p /opt/apps
chmod 755 /opt/apps

# Create example module file
mkdir -p /usr/share/modulefiles/example
cat > /usr/share/modulefiles/example/1.0 <<EOF
#%Module
proc ModulesHelp { } {
  puts stderr "This module sets up the example application environment"
}
module-whatis "Example application"
prepend-path PATH /opt/apps/example/bin
EOF

echo "Login node setup complete"
