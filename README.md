# Slurm on Lustre Vagrant Cluster

This repository provides a Vagrant configuration for setting up a 3-node Lustre cluster with Slurm workload manager.

## Cluster Layout

- **MXS**: Combined MDS/MGS server and Slurm controller
- **OSS**: Lustre storage server and Slurm compute node
- **Client**: Lustre client and Slurm compute node

## Getting Started

1. Launch the cluster:
   ```bash
   vagrant up
   ```
2. setup slurm
   ```bash
   ./setup_slurm.sh
   ```

3. run slurm job
   ```bash
   vagrant ssh login
   cd /lustre/vagrant
   sbatch lustre_test_job.sh
   Ctrl+D # exit ssh
   ```

4. check the result

   on mxs
   ```
   vagrant ssh mxs
   lctl get_param md[ts].*.*
   ```

   on oss
   ```
   vagrant ssh oss
   lctl get_param obdfilter.*.*
   ```

## to scp files

   instart vagrant-scp plugin
   ```
   vagrant plugin install vagrant-scp
   ```
   
   then 
   ```
   vagrant scp <some_local_file_or_dir> [vm_name]:<somewhere_on_the_vm>
   ```


## Prerequisites

* [Vagrant](https://www.vagrantup.com/)     - Version tested: 2.2.14
* [VirtualBox](https://www.virtualbox.org/) - Version tested: 6.1.30

## Examples

* [lustre](lustre/)


## kvm error

If you get the following error message when running `vagrant up`:

```
There was an error while executing `VBoxManage`, a CLI used by Vagrant
for controlling VirtualBox. The command and stderr is shown below.

Command: ["startvm", "8c956e5d-a172-420a-876d-20f3c4087736", "--type", "headless"]

Stderr: VBoxManage: error: VirtualBox can't operate in VMX root mode. Please disable the KVM kernel extension, recompile your kernel and reboot (VERR_VMX_IN_VMX_ROOT_MODE)
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005), component ConsoleWrap, interface IConsole
```

You can disable the KVM kernel module by running the following command:

```
sudo modprobe -r kvm_intel
```

## firewall error

sometimes mounting the shared folder can fail due to firewall rules. If you get the following error message when running `vagrant up`:

```
sudo systemctl stop firewalld
```


## Workaround for VirtualBox7.1 

To use virtualbox 7.1, a small modification is necessary until updates of vagrant (as v7.1 is not supported yet.) 
ref: https://github.com/hashicorp/vagrant/issues/13501#issuecomment-2346267062

Edit /usr/bin/VBox to modify between #### #####

```diff
--- /tmp/orig/VBox	2024-09-14 15:40:52.961690431 +0200
+++ /usr/bin/VBox	2024-09-14 15:42:05.941525049 +0200
@@ -142,7 +142,11 @@
         exec "$INSTALL_DIR/VirtualBoxVM" "$@"
         ;;
     VBoxManage|vboxmanage)
-        exec "$INSTALL_DIR/VBoxManage" "$@"
+	if [[ $@ == "--version" ]]; then
+	  echo "7.0.0r164728"
+	else
+          exec "$INSTALL_DIR/VBoxManage" "$@"
+	fi
         ;;
     VBoxSDL|vboxsdl)
         exec "$INSTALL_DIR/VBoxSDL" "$@"
```


