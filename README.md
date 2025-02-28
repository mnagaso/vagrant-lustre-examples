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

2. SSH into the controller node:
   ```bash
   vagrant ssh mxs
   ```

3. Use the unified Slurm management script:
   ```bash
   sudo bash /home/vagrant/slurm_manager.sh
   ```

## Slurm Management Script

The `slurm_manager.sh` script provides a unified interface for managing Slurm:

- Quick Fix (Run All Repairs)
- Show Slurm Status
- Show Logs
- Fix Network Configuration
- Fix Munge Authentication
- Update Slurm Configuration
- Distribute Configuration to Compute Nodes
- Start/Restart Controller or Compute Nodes

### Usage

Interactive mode:
```bash
sudo bash slurm_manager.sh
```

Command-line mode:
```bash
sudo bash slurm_manager.sh [option-number]
```

Example:
```bash
sudo bash slurm_manager.sh 1  # Run quick fix
```

## Common Slurm Issues & Solutions

### "Unable to contact slurm controller (connect failure)"

This indicates a network connectivity or controller issue:

1. Verify the controller is running:
   ```bash
   sudo systemctl status slurmctld
   ```

2. Check network connectivity:
   ```bash
   ping mxs
   ```

3. Verify firewall is disabled:
   ```bash
   sudo systemctl status firewalld
   ```

4. Check that Munge authentication is working:
   ```bash
   munge -n | unmunge
   ```

5. Use the Slurm manager script to fix issues:
   ```bash
   sudo bash slurm_manager.sh 1
   ```

## Running Jobs

Once Slurm is working properly, you can submit jobs:

```bash
sinfo                    # Check partition and node status
srun -N1 hostname        # Run a simple job
sbatch job_script.sh     # Submit a batch job
squeue                   # Check job queue
```

## Troubleshooting

If you encounter issues, use the Slurm manager script to diagnose and fix problems:

```bash
sudo bash slurm_manager.sh 2  # Show current Slurm status
sudo bash slurm_manager.sh 3  # Show logs
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


## to get the lustre log with lctl command

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
