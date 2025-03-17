# GitHub Copilot Usage

## Project Summary
- Deploys a Lustre cluster with Slurm.
- Uses Vagrant and VirtualBox to provision multiple nodes.
- Slurm final configuration is done with the script `setup_slurm.sh` which scp the `slurm_update_config.sh` script to the VMs and runs it on each VM.
- Lustre file system is mounted on the client and compute node at `/lustre/vagrant`.

## Copilot Tips
- Create descriptive comments or function signatures for better suggestions.
- Evaluate generated code carefully before committing.
