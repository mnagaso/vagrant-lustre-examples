# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"
ENV["VAGRANT_EXPERIMENTAL"] = "disks"

hosts = %q(
127.0.0.1     localhost localhost.localdomain localhost4 localhost4.localdomain4
::1           localhost localhost.localdomain localhost6 localhost6.localdomain6

192.168.10.10 mxs
192.168.10.20 oss
192.168.10.30 client
)

$create_file_hosts = <<-SCRIPT
echo "#{hosts}" > /etc/hosts
SCRIPT

$create_repo = <<-SCRIPT
cat > /etc/yum.repos.d/e2fsprogs-wc.repo <<EOF
[e2fsprogs-wc]
name=e2fsprogs-wc
baseurl=https://downloads.whamcloud.com/public/e2fsprogs/1.47.1.wc2/el8
gpgcheck=0
enabled=0
EOF
cat > /etc/yum.repos.d/lustre-server.repo <<EOF
[lustre-server]
name=lustre-server
baseurl=https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server
gpgcheck=0
enabled=0
EOF
cat > /etc/yum.repos.d/lustre-client.repo <<EOF
[lustre-client]
name=lustre-client
baseurl=https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/client
gpgcheck=0
enabled=0
EOF
SCRIPT

$install_packages_common = <<-SCRIPT
dnf install -y epel-release linux-firmware
dnf install -y wget curl git vim kernel-devel perl
dnf install -y --enablerepo=powertools \
  libyaml-devel \
  libmount-devel

# install collectl
git clone https://github.com/sharkcz/collectl.git
cd collectl
sudo ./INSTALL
cd ..
rm -rf collectl
SCRIPT

$install_packages_kernel_patched = <<-SCRIPT
curl -O https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server/RPMS/x86_64/kernel-4.18.0-553.27.1.el8_lustre.x86_64.rpm
curl -O https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server/RPMS/x86_64/kernel-core-4.18.0-553.27.1.el8_lustre.x86_64.rpm
curl -O https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server/RPMS/x86_64/kernel-modules-4.18.0-553.27.1.el8_lustre.x86_64.rpm
curl -O https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server/RPMS/x86_64/kernel-devel-4.18.0-553.27.1.el8_lustre.x86_64.rpm
curl -O https://downloads.whamcloud.com/public/lustre/lustre-2.15.6/el8.10/server/RPMS/x86_64/kernel-headers-4.18.0-553.27.1.el8_lustre.x86_64.rpm
yum localinstall -y kernel-4.18.0-553.27.1.el8_lustre.x86_64.rpm \
kernel-core-4.18.0-553.27.1.el8_lustre.x86_64.rpm \
kernel-modules-4.18.0-553.27.1.el8_lustre.x86_64.rpm \
kernel-devel-4.18.0-553.27.1.el8_lustre.x86_64.rpm \
kernel-headers-4.18.0-553.27.1.el8_lustre.x86_64.rpm
rm -f *.rpm

# install e2fsprogs
yum install -y --nogpgcheck --disablerepo=* --enablerepo=e2fsprogs-wc \
  e2fsprogs
SCRIPT

$install_packages_server_ldiskfs = <<-SCRIPT
yum --nogpgcheck --enablerepo=lustre-server install -y \
lustre-osd-ldiskfs-mount \
lustre
SCRIPT

$install_packages_server_zfs = <<-SCRIPT
dnf install -y https://zfsonlinux.org/epel/zfs-release-2-3$(rpm --eval "%{dist}").noarch.rpm
dnf install -y kernel-devel
dnf install -y zfs
sudo dnf --enablerepo=lustre-server install -y lustre-dkms lustre-osd-zfs-mount lustre
SCRIPT

$install_packages_client = <<-SCRIPT
dnf install -y --enablerepo=lustre-client \
kmod-lustre-client \
lustre-client-dkms \
lustre-client
SCRIPT

$disable_selinux = <<-SCRIPT
echo "SELINUX=disabled" > /etc/selinux/config
SCRIPT

$configure_lnet = <<-SCRIPT
echo "options lnet networks=tcp0(eth1)" > /etc/modprobe.d/lnet.conf
SCRIPT

$configure_lustre_server_mgs_mds = <<-SCRIPT
modprobe -v lnet
modprobe -v lustre
mkdir /mnt/mdt
mkfs.lustre --reformat --backfstype=ldiskfs --fsname=phoenix --mgs --mdt --index=0 /dev/sdb
mount -t lustre /dev/sdb /mnt/mdt
SCRIPT

$configure_lustre_server_oss_zfs = <<-SCRIPT
modprobe -v lnet
modprobe -v lustre
modprobe -v zfs
zpool create ostpool0 /dev/sdb
zpool create ostpool1 /dev/sdc
mkfs.lustre --reformat --backfstype=zfs --ost --fsname phoenix --index 0 --mgsnode mxs@tcp0 ostpool0/ost0
mkfs.lustre --reformat --backfstype=zfs --ost --fsname phoenix --index 1 --mgsnode mxs@tcp0 ostpool1/ost1
mkdir -p /lustre/phoenix/ost0
mkdir -p /lustre/phoenix/ost1
mount -t lustre ostpool0/ost0 /lustre/phoenix/ost0
mount -t lustre ostpool1/ost1 /lustre/phoenix/ost1
SCRIPT

$configure_lustre_client = <<-SCRIPT
mkdir -p /lustre
mount -t lustre mxs@tcp0:/phoenix /lustre
chown -R vagrant:vagrant /lustre
SCRIPT

$check_kernel_version = <<-SCRIPT
echo "Checking kernel version..."
uname -r
SCRIPT

$install_packages_test_suite_server = <<-SCRIPT
sudo dnf install -y --enablerepo=lustre-server lustre-devel kmod-lustre-tests lustre-iokit lustre-tests
SCRIPT

$install_packages_test_suite_client = <<-SCRIPT
sudo dnf install -y --enablerepo=lustre-client lustre-client-tests
SCRIPT

$start_lustre_server = <<-SCRIPT
systemctl stop firewalld
systemctl disable firewalld
systemctl enable lnet
systemctl start lnet
systemctl enable lustre
systemctl start lustre
SCRIPT

# install slurm for all nodes
$install_slurm = <<-SCRIPT
dnf install -y --enablerepo=powertools libaec
dnf install -y slurm slurm-slurmd slurm-slurmctld slurm-slurmdbd munge
SCRIPT

# configure munge authentication for all nodes
$configure_munge = <<-SCRIPT
dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key
chown munge:munge /etc/munge/munge.key
chmod 400 /etc/munge/munge.key
scp /etc/munge/munge.key root@oss:/etc/munge/
scp /etc/munge/munge.key root@client:/etc/munge/
systemctl enable --now munge
SCRIPT

# configure slurm controller on mxs
$configure_slurm_controller = <<-SCRIPT
cat > /etc/slurm/slurm.conf <<EOF
# Example slurm.conf file
ClusterName=lustre_cluster
ControlMachine=mxs
SlurmdPort=6818
SlurmctldPort=6817
AuthType=auth/munge
StateSaveLocation=/var/spool/slurmctld
SlurmdSpoolDir=/var/spool/slurmd
SlurmUser=slurm
SlurmdUser=root
EOF
systemctl enable --now slurmctld
SCRIPT

# configure slurm compute nodes on oss and client
$configure_slurm_compute = <<-SCRIPT
cat > /etc/slurm/slurm.conf <<EOF
# Example slurm.conf file
ClusterName=lustre_cluster
ControlMachine=mxs
SlurmdPort=6818
SlurmctldPort=6817
AuthType=auth/munge
StateSaveLocation=/var/spool/slurmctld
SlurmdSpoolDir=/var/spool/slurmd
SlurmUser=slurm
SlurmdUser=root
EOF
systemctl enable --now slurmd
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.provider :virtualbox
  config.vm.provider "virtualbox" do |v|
    v.memory = 512
    v.cpus = 2
  end
  config.vm.box = "bento/rockylinux-8"
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.provision "shell", name: "check_kernel_version", inline: $check_kernel_version

  config.vm.provision "shell", name: "create_file_hosts", inline: $create_file_hosts

  config.vm.define "mxs" do |mxs|
    mxs.vm.hostname = "mxs"
    mxs.vm.network "private_network", ip: "192.168.10.10"
    mxs.vm.disk :disk, size: "10GB", name: "disk_for_lustre"
    mxs.vm.provision "shell", name: "create_repo", inline: $create_repo
    mxs.vm.provision "shell", name: "install_packages_common", inline: $install_packages_common
    mxs.vm.provision "shell", name: "install_packages_kernel_patched", inline: $install_packages_kernel_patched
    mxs.vm.provision :reload
    mxs.vm.provision "shell", name: "install_packages_ldiskfs", inline: $install_packages_server_ldiskfs
    mxs.vm.provision "shell", name: "install_packages_test_suite_server", inline: $install_packages_test_suite_server
    mxs.vm.provision "shell", name: "disable_selinux", inline: $disable_selinux
    mxs.vm.provision :reload
    mxs.vm.provision "shell", name: "configure_lnet", inline: $configure_lnet
    mxs.vm.provision "shell", name: "configure_mgs_mds", inline: $configure_lustre_server_mgs_mds
    mxs.vm.provision "shell", name: "start_lustre_server", inline: $start_lustre_server
    mxs.vm.provision "shell", name: "install_slurm", inline: $install_slurm
    mxs.vm.provision "shell", name: "configure_munge", inline: $configure_munge
    mxs.vm.provision "shell", name: "configure_slurm_controller", inline: $configure_slurm_controller
    mxs.vm.provision "file", source: "fefssv_copy.py", destination: "/home/vagrant/fefssv_copy.py"
  end

  config.vm.define "oss" do |oss|
    oss.vm.hostname = "oss"
    oss.vm.network "private_network", ip: "192.168.10.20"
    oss.vm.disk :disk, size: "10GB", name: "disk_for_lustre_ost_1"
    oss.vm.disk :disk, size: "10GB", name: "disk_for_lustre_ost_2"
    oss.vm.provision "shell", name: "create_repo", inline: $create_repo
    oss.vm.provision "shell", name: "install_packages_common", inline: $install_packages_common
    oss.vm.provision "shell", name: "install_packages_kernel_patched", inline: $install_packages_kernel_patched
    oss.vm.provision :reload
    oss.vm.provision "shell", name: "install_packages_zfs", inline: $install_packages_server_zfs
    oss.vm.provision "shell", name: "install_packages_test_suite_server", inline: $install_packages_test_suite_server
    oss.vm.provision "shell", name: "disable_selinux", inline: $disable_selinux
    oss.vm.provision :reload
    oss.vm.provision "shell", name: "configure_lnet", inline: $configure_lnet
    oss.vm.provision "shell", name: "configure_oss", inline: $configure_lustre_server_oss_zfs
    oss.vm.provision "shell", name: "start_lustre_server", inline: $start_lustre_server
    oss.vm.provision "shell", name: "install_slurm", inline: $install_slurm
    oss.vm.provision "shell", name: "configure_munge", inline: $configure_munge
    oss.vm.provision "shell", name: "configure_slurm_compute", inline: $configure_slurm_compute
    oss.vm.provision "file", source: "fefssv_copy.py", destination: "/home/vagrant/fefssv_copy.py"
  end

  config.vm.define "client" do |client|
    client.vm.hostname = "client"
    client.vm.network "private_network", ip: "192.168.10.30"
    client.vm.provision "shell", name: "create_repo", inline: $create_repo
    client.vm.provision "shell", name: "install_packages_common", inline: $install_packages_common
    client.vm.provision "shell", name: "install_packages_kernel_patched", inline: $install_packages_kernel_patched
    client.vm.provision :reload
    client.vm.provision "shell", name: "install_packages_client", inline: $install_packages_client
    client.vm.provision "shell", name: "install_packages_test_suite_client", inline: $install_packages_test_suite_client
    client.vm.provision "shell", name: "configure_lnet", inline: $configure_lnet
    client.vm.provision "shell", name: "configure_client", inline: $configure_lustre_client
    client.vm.provision "shell", name: "install_slurm", inline: $install_slurm
    client.vm.provision "shell", name: "configure_munge", inline: $configure_munge
    client.vm.provision "shell", name: "configure_slurm_compute", inline: $configure_slurm_compute
    client.vm.provision "file", source: "fefssv_copy.py", destination: "/home/vagrant/fefssv_copy.py"
    client.vm.provision "file", source: "job_script.sh", destination: "/home/vagrant/job_script.sh"
  end
end
