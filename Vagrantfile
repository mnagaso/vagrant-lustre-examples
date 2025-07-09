# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
ENV["VAGRANT_EXPERIMENTAL"] = "disks"

Vagrant.configure("2") do |config|
  config.vm.provider :virtualbox
  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 4
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end
  config.vm.box = "bento/rockylinux-8"
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.provision "shell", name: "check_kernel_version", path: "scripts/check_kernel_version.sh"
  config.vm.provision "shell", name: "create_file_hosts", path: "scripts/create_file_hosts.sh"

  # File provisioner for Slurm configuration files (run on demand)
  #config.vm.provision "file", source: "slurm_update_config.sh", destination: "/home/vagrant/slurm_update_config.sh", run: "never"
  #config.vm.provision "file", source: "slurm.conf", destination: "/home/vagrant/slurm.conf", run: "never"
  #config.vm.provision "file", source: "munge.key", destination: "/home/vagrant/munge.key", run: "never"

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
    #mxs.vm.provision "shell", name: "install_slurm_basic", path: "scripts/install_slurm_basic.sh"
    #mxs.vm.provision "shell", name: "create_slurm_environment", path: "scripts/create_slurm_environment.sh"
    #mxs.vm.provision "shell", name: "create_cluster_users", path: "scripts/create_cluster_users.sh"
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
    #oss.vm.provision "shell", name: "install_slurm_basic", path: "scripts/install_slurm_basic.sh"
    #oss.vm.provision "shell", name: "create_slurm_environment", path: "scripts/create_slurm_environment.sh"
    #oss.vm.provision "shell", name: "create_cluster_users", path: "scripts/create_cluster_users.sh"
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
    # sharing home directories make a duplication of .ssh/authorized_keys which is required from vagrant ssh
    # to work properly (independent key for each vm is required), so we disable it for now
    #login.vm.provision "shell", name: "configure_shared_home_nfs", path: "scripts/configure_shared_home_nfs.sh"
    login.vm.provision "shell", name: "configure_ssh_for_ood", path: "scripts/configure_ssh_for_ood.sh"
  end

  # Add a dedicated compute node
  config.vm.define "compute1" do |compute1|
    #compute1.vm.provider "virtualbox" do |v|
    #  v.memory = 4096
    #  v.cpus = 4
    #end
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
    compute1.vm.provision "shell", name: "create_user_dirs", path: "scripts/create_user_dirs.sh"
    # sharing home directories make a duplication of .ssh/authorized_keys which is required from vagrant ssh
    # to work properly (independent key for each vm is required), so we disable it for now
    #compute1.vm.provision "shell", name: "configure_shared_home_nfs", path: "scripts/configure_shared_home_nfs.sh"
    compute1.vm.provision "shell", name: "configure_ssh_for_ood", path: "scripts/configure_ssh_for_ood.sh"
    compute1.vm.provision "shell", name: "install_singularity", path: "scripts/install_singularity.sh"
    compute1.vm.provision "shell", name: "distribute_container", path: "scripts/distribute_container.sh"
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
    ood.vm.provision "shell", name: "create_user_dirs", path: "scripts/create_user_dirs.sh"
    # sharing home directories make a duplication of .ssh/authorized_keys which is required from vagrant ssh
    # to work properly (independent key for each vm is required), so we disable it for now
    #ood.vm.provision "shell", name: "configure_shared_home_nfs", path: "scripts/configure_shared_home_nfs.sh"
  end
end

