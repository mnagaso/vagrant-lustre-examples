# Test environment for lustre cluster with Slurm

## Project Summary
- The project sets up a 4-node Lustre cluster with Slurm.  
- It uses Vagrant and VirtualBox to provision MDS/MGS, OSS, client, and compute nodes.  
    - lustre-server is installed on MDS/MGS and OSS nodes.
    - lustre-client is installed on the client and compute nodes.
    - Slurm is installed on the OSS, client and compute nodes.
    - Slurm control daemon is installed on the MDS/MGS node.
- Slurm final configuration is done with the script `setup_slurm.sh` which scp the `slurm_update_config.sh` script to the VMs and runs it on each VM.
- Lustre file system is mounted on the client and compute node at `/lustre/vagrant`.
- Instructions include how to launch, configure Slurm, and monitor Lustre using collectl.

- Always check Vagrantfile, setup_slurm.sh, and slurm_update_config.sh for the environment configuration.

## IIB GPU cluster setup specifications

### software specifications
- **Node Version:** Always use node23 for consistency across the project.
- **Styling:** Use Tailwind CSS for designing UI components.
- **Framework:** Use Next.js for the web application with app router (both frontend and backend).
- **Deployment:** Use Docker for containerization and always do docker build and docker run commands in iib_app directory.

### Use Cases

1. **Training / Prediction / Evaluation:**
   - Supports a Jupyter Notebook environment integrated with PyTorch.
   - Implements job scripts that launch a Jupyter server and expose a URL, port, and token.

2. **Inference Only:**
   - Deploys a Next.js application as a Docker container running on the login node.
   - Provides a terminal emulator accessible through the browser.
   - Hosts a web application modeled after Huggingface.co using Gradio, with Gradio capable of triggering Slurm jobs.
   - Enables submission of Slurm jobs directly from the application.
