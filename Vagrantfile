# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
ENV["VAGRANT_EXPERIMENTAL"] = "disks"

Vagrant.configure("2") do |config|
  config.vm.provider :virtualbox
  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 8
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end
  config.vm.box = "bento/rockylinux-8"
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.provision "shell", name: "check_kernel_version", path: "scripts/check_kernel_version.sh"

  config.vm.provision "shell", name: "create_file_hosts", path: "scripts/create_file_hosts.sh"

  config.vm.define "mxs" do |mxs|
    mxs.vm.hostname = "mxs"
    mxs.vm.network "private_network", ip: "192.168.10.10"
    mxs.vm.disk :disk, size: "10GB", name: "disk_for_lustre"
    mxs.vm.provision "shell", name: "create_repo", path: "scripts/create_repo.sh"
    mxs.vm.provision "shell", name: "install_packages_common", path: "scripts/install_packages_common.sh"
    mxs.vm.provision "shell", name: "install_packages_kernel_patched", path: "scripts/install_packages_kernel_patched.sh"
    mxs.vm.provision :reload
    mxs.vm.provision "shell", name: "install_packages_ldiskfs", path: "scripts/install_packages_server_ldiskfs.sh"
    mxs.vm.provision "shell", name: "install_packages_test_suite_server", path: "scripts/install_packages_test_suite_server.sh"
    mxs.vm.provision "shell", name: "disable_selinux", path: "scripts/disable_selinux.sh"
    mxs.vm.provision :reload
    mxs.vm.provision "shell", name: "configure_lnet", path: "scripts/configure_lnet.sh"
    mxs.vm.provision "shell", name: "configure_mgs_mds", path: "scripts/configure_lustre_server_mgs_mds.sh"
    mxs.vm.provision "shell", name: "start_lustre_server", path: "scripts/start_lustre_server.sh"
    mxs.vm.provision "shell", name: "install_slurm_basic", path: "scripts/install_slurm_basic.sh"
    mxs.vm.provision "shell", name: "create_slurm_environment", path: "scripts/create_slurm_environment.sh"
  end

  config.vm.define "oss" do |oss|
    oss.vm.hostname = "oss"
    oss.vm.network "private_network", ip: "192.168.10.20"
    oss.vm.disk :disk, size: "10GB", name: "disk_for_lustre_ost_1"
    oss.vm.disk :disk, size: "10GB", name: "disk_for_lustre_ost_2"
    oss.vm.provision "shell", name: "create_repo", path: "scripts/create_repo.sh"
    oss.vm.provision "shell", name: "install_packages_common", path: "scripts/install_packages_common.sh"
    oss.vm.provision "shell", name: "install_packages_kernel_patched", path: "scripts/install_packages_kernel_patched.sh"
    oss.vm.provision :reload
    oss.vm.provision "shell", name: "install_packages_zfs", path: "scripts/install_packages_server_zfs.sh"
    oss.vm.provision "shell", name: "install_packages_test_suite_server", path: "scripts/install_packages_test_suite_server.sh"
    oss.vm.provision "shell", name: "disable_selinux", path: "scripts/disable_selinux.sh"
    oss.vm.provision :reload
    oss.vm.provision "shell", name: "configure_lnet", path: "scripts/configure_lnet.sh"
    oss.vm.provision "shell", name: "configure_oss", path: "scripts/configure_lustre_server_oss_zfs.sh"
    oss.vm.provision "shell", name: "start_lustre_server", path: "scripts/start_lustre_server.sh"
    oss.vm.provision "shell", name: "install_slurm_basic", path: "scripts/install_slurm_basic.sh"
    oss.vm.provision "shell", name: "create_slurm_environment", path: "scripts/create_slurm_environment.sh"
  end

  # Renamed from "client" to "login" to serve as login node
  config.vm.define "login" do |login|
    login.vm.hostname = "login"
    login.vm.network "private_network", ip: "192.168.10.30"
    login.vm.provision "shell", name: "create_repo", path: "scripts/create_repo.sh"
    login.vm.provision "shell", name: "install_packages_common", path: "scripts/install_packages_common.sh"
    login.vm.provision "shell", name: "install_packages_client", path: "scripts/install_packages_client.sh"
    login.vm.provision "shell", name: "install_packages_test_suite_client", path: "scripts/install_packages_test_suite_client.sh"
    login.vm.provision "shell", name: "configure_lnet", path: "scripts/configure_lnet.sh"
    login.vm.provision "shell", name: "configure_client", path: "scripts/configure_lustre_client.sh"
    login.vm.provision "shell", name: "configure_login_node", path: "scripts/configure_login_node.sh"
    login.vm.provision "shell", name: "install_slurm_basic", path: "scripts/install_slurm_basic.sh"
    login.vm.provision "shell", name: "create_slurm_environment", path: "scripts/create_slurm_environment.sh"
    login.vm.provision "shell", name: "create_cluster_users", path: "scripts/create_cluster_users.sh"
    login.vm.provision "shell", name: "create_user_dirs", path: "scripts/create_user_dirs.sh"
    login.vm.provision "shell", name: "create_job_script", path: "scripts/create_job_script.sh"
    login.vm.provision "shell", name: "configure_ssh_for_ood", path: "scripts/configure_ssh_for_ood.sh"
  end

  # Add a dedicated compute node
  config.vm.define "compute1" do |compute1|
    compute1.vm.hostname = "compute1"
    compute1.vm.network "private_network", ip: "192.168.10.40"
    compute1.vm.provision "shell", name: "create_repo", path: "scripts/create_repo.sh"
    compute1.vm.provision "shell", name: "install_packages_common", path: "scripts/install_packages_common.sh"
    compute1.vm.provision "shell", name: "install_packages_client", path: "scripts/install_packages_client.sh"
    compute1.vm.provision "shell", name: "configure_lnet", path: "scripts/configure_lnet.sh"
    compute1.vm.provision "shell", name: "configure_client", path: "scripts/configure_lustre_client.sh"
    compute1.vm.provision "shell", name: "install_slurm_basic", path: "scripts/install_slurm_basic.sh"
    compute1.vm.provision "shell", name: "create_slurm_environment", path: "scripts/create_slurm_environment.sh"
    compute1.vm.provision "shell", name: "create_cluster_users", path: "scripts/create_cluster_users.sh"
    compute1.vm.provision "shell", name: "configure_ssh_for_ood", path: "scripts/configure_ssh_for_ood.sh"
  end

  # Add a Keycloak VM for OIDC authentication (must come before OOD)
  config.vm.define "keycloak" do |keycloak|
    keycloak.vm.hostname = "keycloak"
    keycloak.vm.network "private_network", ip: "192.168.10.60"
    # Forward port 8080 for direct Keycloak access (HTTP)
    keycloak.vm.network "forwarded_port", guest: 8080, host: 8080, auto_correct: true
    # Sync the current directory to /vagrant for access to scripts
    keycloak.vm.synced_folder ".", "/vagrant", disabled: false
    keycloak.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 2
    end
    # Install and configure Keycloak using the updated script
    keycloak.vm.provision "shell", name: "install_keycloak", path: "scripts/install_keycloak.sh"
  end

  # Add an Open OnDemand node (depends on Keycloak)
  config.vm.define "ood" do |ood|
    ood.vm.hostname = "ood"
    ood.vm.network "private_network", ip: "192.168.10.50"
    # open port 443 for HTTPS access to Open OnDemand
    ood.vm.network "forwarded_port", guest: 443, host: 8444, auto_correct: true
    # Sync the current directory to /vagrant for access to scripts
    ood.vm.synced_folder ".", "/vagrant", disabled: false
    ood.vm.provision "shell", name: "create_repo", path: "scripts/create_repo.sh"
    ood.vm.provision "shell", name: "install_packages_common", path: "scripts/install_packages_common.sh"
    ood.vm.provision "shell", name: "install_packages_client", path: "scripts/install_packages_client.sh"
    ood.vm.provision "shell", name: "configure_lnet", path: "scripts/configure_lnet.sh"
    ood.vm.provision "shell", name: "configure_client", path: "scripts/configure_lustre_client.sh"
    ood.vm.provision "shell", name: "install_slurm_basic", path: "scripts/install_slurm_basic.sh"
    ood.vm.provision "shell", name: "create_slurm_environment", path: "scripts/create_slurm_environment.sh"
    ood.vm.provision "shell", name: "install_open_ondemand", path: "scripts/install_open_ondemand.sh"
    ood.vm.provision "shell", name: "configure_open_ondemand", path: "scripts/configure_open_ondemand.sh"
    ood.vm.provision "shell", name: "create_cluster_users", path: "scripts/create_cluster_users.sh"
  end
end

# KEYCLOAK + OPEN ONDEMAND INTEGRATION SUMMARY:
#
# The Vagrantfile now uses external scripts from the scripts/ directory for better organization.
# All inline scripts have been moved to separate .sh files for easier maintenance and reusability.
#
# 1. Keycloak VM (192.168.10.60):
#    - Installs Keycloak 25.x using official container image with Podman
#    - Uses systemd service for container management and auto-restart
#    - Configured for development mode with HTTP access on port 8080
#    - Creates "ood" realm with OIDC client configuration
#    - Creates test users (testuser, admin with password123/admin123)
#    - Accessible at http://192.168.10.60:8080 (admin console: /admin)
#    - Accessible from host at http://localhost:8080
#
# 2. Open OnDemand VM (192.168.10.50):
#    - Installs Open OnDemand with mod_auth_openidc
#    - Uses ood-portal-generator for proper configuration
#    - Configured for OIDC authentication with Keycloak 25.x
#    - Uses correct Keycloak OIDC metadata endpoint
#    - Accessible at https://192.168.10.50
#    - Accessible from host at https://localhost:8444
#
# 3. Automated OIDC Configuration:
#    - Creates 'ood' realm in Keycloak with proper settings
#    - Creates OIDC client with ID 'ood-test'
#    - Creates users user1-user5 with password123
#    - Updates OOD configuration with Keycloak provider URL
#    - Integration script runs automatically during provisioning
#
# 4. Network Configuration:
#    - Keycloak: 192.168.10.60:8080 → localhost:8080
#    - Open OnDemand: 192.168.10.50:443 → localhost:8444
#    - Cross-VM communication for OIDC authentication
#
# The entire setup is now fully automated using modern Keycloak 25.x with container deployment.
# Just run 'vagrant up' and both Keycloak and Open OnDemand will be configured and ready to use!
#
