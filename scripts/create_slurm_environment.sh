#!/bin/bash
# Create SLURM environment

echo "==== Creating SLURM environment ===="

# Create required users
echo "Creating munge user..."
id -u munge &>/dev/null || useradd -r -m munge

# Create required directories
echo "Creating SLURM directories..."
mkdir -p /var/spool/slurmd
mkdir -p /var/spool/slurmctld/state
mkdir -p /var/log/slurm
mkdir -p /var/run/slurm

# Set up munge directories
echo "Creating munge directories..."
mkdir -p /var/log/munge
mkdir -p /var/lib/munge
mkdir -p /var/run/munge

# Set directory permissions
echo "Setting directory permissions..."
chown root:root /var/spool/slurmd
chmod 755 /var/spool/slurmd

chown root:root /var/spool/slurmctld
chown root:root /var/log/slurm
chown root:root /var/run/slurm
chmod 755 /var/spool/slurmctld
chmod 755 /var/log/slurm
chmod 755 /var/run/slurm

chmod 700 /etc/munge
chmod 711 /var/lib/munge
chmod 700 /var/log/munge
chmod 755 /var/run/munge
chown -R munge:munge /etc/munge
chown -R munge:munge /var/lib/munge
chown -R munge:munge /var/log/munge
chown -R munge:munge /var/run/munge

echo "SLURM environment setup complete."
