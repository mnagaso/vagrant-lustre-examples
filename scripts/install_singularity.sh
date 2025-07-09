#!/bin/bash

# Script to install Singularity and create a SIF file from a definition file
# This script should be run at the end of login VM provisioning

set -e

echo "Starting Singularity installation and container build..."

# Variables
SINGULARITY_VERSION="4.2.1"
GOPATH="/usr/local/go"
GO_VERSION="1.22.8"
SINGULARITY_USER="vagrant"
SINGULARITY_HOME="/home/${SINGULARITY_USER}"
SIF_OUTPUT_DIR="${SINGULARITY_HOME}"
DEF_FILE_NAME="rocky95.def"
SIF_FILE_NAME="rocky95.sif"

# Function to print colored output
print_status() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root"
   exit 1
fi

print_status "Installing dependencies for Singularity..."

# Install required packages
dnf groupinstall -y "Development Tools"
sudo dnf install -y \
   autoconf \
   automake \
   crun \
   cryptsetup \
   fuse \
   fuse3 \
   fuse3-devel \
   git \
   glib2-devel \
   libseccomp-devel \
   libtool \
   squashfs-tools \
   squashfs-tools-ng \
   wget \
   zlib-devel

print_status "Installing Go ${GO_VERSION}..."

# Remove any existing Go installation
rm -rf /usr/local/go

# Download and install Go
cd /tmp
wget "https://dl.google.com/go/go${GO_VERSION}.linux-amd64.tar.gz"
tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"

# Set up Go environment
export PATH="/usr/local/go/bin:${PATH}"
echo 'export PATH="/usr/local/go/bin:${PATH}"' >> /etc/profile.d/go.sh

print_status "Installing SingularityCE ${SINGULARITY_VERSION}..."

# Download and build SingularityCE
cd /tmp
wget "https://github.com/sylabs/singularity/releases/download/v${SINGULARITY_VERSION}/singularity-ce-${SINGULARITY_VERSION}.tar.gz"
tar -xzf "singularity-ce-${SINGULARITY_VERSION}.tar.gz"
cd "singularity-ce-${SINGULARITY_VERSION}"

# Configure and build
./mconfig --prefix=/usr/local/singularity
make -C builddir
make -C builddir install

# Add Singularity to PATH
echo 'export PATH="/usr/local/singularity/bin:${PATH}"' >> /etc/profile.d/singularity.sh

# Source the profile to make singularity available immediately
source /etc/profile.d/singularity.sh
export PATH="/usr/local/singularity/bin:${PATH}"

print_status "Creating Singularity definition file..."

# Create a comprehensive Rocky Linux 9.5 definition file
cat <<EOF > "${SINGULARITY_HOME}/${DEF_FILE_NAME}"
Bootstrap: docker
From: rockylinux/rockylinux:9.5

%post
    dnf -y install epel-release procps-ng
    dnf config-manager --set-enabled crb
    dnf -y groupinstall 'Xfce'
    dnf -y remove xfce4-screensaver
    dnf -y install https://yum.osc.edu/ondemand/latest/compute/el9Server/x86_64/python3-websockify-0.11.0-1.el9.noarch.rpm
    dnf -y install https://yum.osc.edu/ondemand/latest/compute/el9Server/x86_64/turbovnc-3.1.1-1.el9.x86_64.rpm
    dnf clean all
EOF

# build the Singularity image file (SIF)
print_status "Building Singularity image file (SIF)..."
singularity build --force "${SIF_OUTPUT_DIR}/${SIF_FILE_NAME}" "${SINGULARITY_HOME}/${DEF_FILE_NAME}"