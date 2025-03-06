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
   ``

## use the original perl code "fefssv.ph"
   on mxs
   ``` bash
   vagrant ssh mxs
   sudo collectl -f tmp -r00:00,30 -m -F60 -s+YZ -i10:60:300 import ~/fefssv.ph,mdt=phoenix-MDT0000,v
   ```
   
   below is the explanation of the command [manual](https://linux.die.net/man/1/collectl)

   - `-f tmp`
This is the name of a file to write the output to

   - `-r00:00,30`
When selected, collectl runs indefinately (or at least until the system reboots). The maximum number of raw and/or plot files that will be retained (older ones are automatically deleted) is controlled by the days field, the default is 7. When -m is also specified to direct collectl to write messages to a log file in the logging directory, the number of months to retain those logs is controlled by the months field and its default is 12. The increment field which is also optional (but is position dependent) specifies the duration of an individual collection file in minutes the default of which is 1440 or 1 day.

   - `-m`
Write status to a monthly log file in the same directory as the output file (requires -f to be specified as well). The name of the file will be collectl-yyyymm.log and will track various messages that may get generated during every run of collectl.

   - `-F60`
Flush output buffers after this number of seconds. 

   - `-s+YZ`
This field controls which subsystem data is to be collected or played back for. 
X - Interconnect
Y - Slabs (system object caches)

   - `-i10:60:300` interval[:interval2[:interval3]]

This is the sampling interval in seconds. The default is 10 seconds when run as a daemon and 1 second otherwise. The process subsystem and slabs (-sY and -sZ) are sampled at the lower rate of interval2. Environmentals (-sE), which only apply to a subset of hardware, are sampled at interval3. Both interval2 and interval3, if specified, must be an even multiple of interval1. The daemon default is -i10:60:300 and all other modes are -i1:60:300. To sample only processes once every 10 seconds use -i:10.

   - `import ~/fefssv.ph,mdt=phoenix-MDT0000,v`
Instructs collectl to load an external module. In this case:
      - ~/fefssv.ph is the Perl module file.
      - mdt=phoenix-MDT0000 passes a parameter to the module (it tells the script which MDT to monitor).
      - The trailing v might tell the module to run in verbose mode (or it could be setting another module-specific option).

   or on oss
   ``` bash
   vagrant ssh oss
   sudo collectl -f tmp -r00:00,30 -m -F60 -s+YZ -i10:60:300 import ~/fefssv.ph,ost=phoenix-OST0000,v
   ```

## to activate compute1 node
   ``` bash
   vagrant ssh mxs -c "sudo scontrol update NodeName=compute1 State=RESUME"
   ```

## to scp files

   instart vagrant-scp plugin
   ``` bash
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


