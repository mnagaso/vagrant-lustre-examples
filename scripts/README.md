# Scripts Directory - Usage Documentation

This directory contains shell scripts used for provisioning and managing the Vagrant Lustre cluster environment.

## Script Categories

### 🟢 **Active Scripts** (Used by Vagrantfile)
These scripts are automatically executed during `vagrant up`:

#### Core System Setup
- `check_kernel_version.sh` - Validates kernel version compatibility
- `create_file_hosts.sh` - Creates /etc/hosts entries for cluster nodes
- `create_repo.sh` - Sets up package repositories
- `disable_selinux.sh` - Disables SELinux for Lustre compatibility

#### Package Installation
- `install_packages_common.sh` - Common packages for all nodes
- `install_packages_kernel_patched.sh` - Patched kernel for Lustre
- `install_packages_server_ldiskfs.sh` - Lustre server packages (ldiskfs)
- `install_packages_server_zfs.sh` - Lustre server packages (ZFS)
- `install_packages_client.sh` - Lustre client packages
- `install_packages_test_suite_server.sh` - Testing tools for servers
- `install_packages_test_suite_client.sh` - Testing tools for clients

#### Lustre Configuration
- `configure_lnet.sh` - LNet networking configuration
- `configure_lustre_server_mgs_mds.sh` - MGS/MDS server setup
- `configure_lustre_server_oss_zfs.sh` - OSS server setup
- `configure_lustre_client.sh` - Client configuration
- `start_lustre_server.sh` - Start Lustre services

#### Slurm Configuration
- `install_slurm_basic.sh` - Basic Slurm installation
- `create_slurm_environment.sh` - Slurm environment setup

#### User Management
- `create_cluster_users.sh` - Creates cluster users
- `create_user_dirs.sh` - Creates user directories
- `create_job_script.sh` - Creates sample job scripts

#### Specialized Node Setup
- `configure_login_node.sh` - Login node configuration
- `configure_ssh_for_ood.sh` - SSH setup for Open OnDemand
- `install_singularity.sh` - Singularity container runtime
- `distribute_container.sh` - Container distribution

#### Authentication & Web Services
- `install_keycloak.sh` - Keycloak identity provider setup
- `install_open_ondemand.sh` - Open OnDemand web portal
- `configure_open_ondemand.sh` - OOD configuration

#### Indirectly Used Scripts
- `create_keycloak_users.sh` - Called by install_keycloak.sh

---

### 🟡 **Utility Scripts** (Manual Use)
These scripts are available for manual testing and validation:

- `test_keycloak.sh` - Test Keycloak functionality
- `validate_scripts.sh` - Validate script syntax and functionality
- `validate_users.sh` - Validate user account setup

---

### 🔴 **Superseded Scripts** (Consider Removal)
These scripts are not currently used and have been replaced by newer implementations:

#### User Management (Legacy)
- `create_compute_users.sh` - **Superseded by** `create_cluster_users.sh`
  - *Original purpose*: Create users specifically for compute nodes
  - *Why unused*: Consolidated into create_cluster_users.sh for consistency

- `create_ood_users.sh` - **Superseded by** `create_cluster_users.sh`
  - *Original purpose*: Create users for Open OnDemand
  - *Why unused*: User creation is now handled uniformly

#### Keycloak Integration (Legacy)
- `integrate_ood_keycloak.sh` - **Superseded by** inline integration in `install_keycloak.sh`
  - *Original purpose*: Separate script for OOD-Keycloak integration
  - *Why unused*: Integration is now done during Keycloak installation

- `manage_keycloak_container.sh` - **Superseded by** systemd service management
  - *Original purpose*: Container lifecycle management
  - *Why unused*: Keycloak is now managed via systemd service

---

### 📋 **Configuration Files**
- `cluster_config.sh` - **Available for manual use**
  - *Purpose*: Centralized configuration variables
  - *Status*: Not used by Vagrantfile but available for manual administration
  - *Contains*: User definitions, network settings, authentication config

---

## Cleanup Recommendations

### Safe to Remove
The following scripts can be safely removed as they are superseded:
```bash
rm scripts/create_compute_users.sh
rm scripts/create_ood_users.sh  
rm scripts/integrate_ood_keycloak.sh
rm scripts/manage_keycloak_container.sh
```

### Keep for Manual Use
These should be retained for testing and validation:
- `test_keycloak.sh`
- `validate_scripts.sh` 
- `validate_users.sh`
- `cluster_config.sh`

---

## Usage Statistics
- **Total scripts**: 36
- **Used by Vagrant**: 29 scripts (81%)
- **Manual utilities**: 4 scripts (11%)
- **Superseded/unused**: 8 scripts (22%)

---

*Last updated: June 30, 2025*
