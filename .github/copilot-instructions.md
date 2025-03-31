# System Prompt:
- You are a helpful assistant that helps with the development of a Lustre cluster with Slurm.
- You are also a helpful assistant that helps with the development of a web application using Next.js and Tailwind CSS.
- You should help me to write the code and structure of the project directories/files.
- You work for writing HTML and CSS code for designing UI components, with Bootstrap and maybe TypeScript.

## Project Summary
- The project sets up a 4-node Lustre cluster with Slurm.
- It uses Vagrant and VirtualBox to provision MDS/MGS, OSS, client, and compute nodes.
    - **lustre-server** is installed on MDS/MGS and OSS nodes.
    - **lustre-client** is installed on the client and compute nodes.
    - **Slurm** is installed on the OSS, client, and compute nodes.
    - **Slurm control daemon** is installed on the MDS/MGS node.
- Slurm final configuration is done with the script `setup_slurm.sh`, which SCPs the `slurm_update_config.sh` script to the VMs and runs it on each VM.
- The Lustre file system is mounted on the client and compute node at `/lustre/vagrant`.
- Instructions include how to launch, configure Slurm, and monitor Lustre using collectl.
- **Always check** the `Vagrantfile`, `setup_slurm.sh`, and `slurm_update_config.sh` for the environment configuration.

## Web Management Interface

This application provides a web-based management interface for the Lustre cluster with Slurm workload manager.

### Overview

The web application allows users to:
- Monitor Lustre filesystem status
- View Slurm job statistics
- Manage user accounts
- Submit and monitor jobs through a web interface

### Project Structure

```
iib_app/
├── docker-compose.yml      # Docker configuration for web app and MongoDB
├── mongo-init.js           # MongoDB initialization script
└── web/                    # Next.js 15 application
    ├── app/                # Next.js App Router structure
    │   ├── globals.css     # Global styles with Tailwind
    │   ├── layout.tsx      # Root layout with font configuration
    │   └── page.tsx        # Main page component
    ├── components/         # Other components
    ├── Dockerfile          # Container configuration for Next.js app
    ├── package.json        # Dependencies and scripts
    └── ... (config files)
```

### Technology Stack

- **Frontend**: Next.js 15 with React 19, using the App Router architecture
- **Styling**: Tailwind CSS 4
- **Database**: MongoDB
- **Containerization**: Docker and Docker Compose
- **Authentication**: Custom auth with MongoDB user storage

### Integration with Lustre and Slurm

The application can be extended to integrate with Lustre and Slurm by:
1. Creating API routes in `web/app/api` directory
2. Implementing server-side code to execute shell commands
3. Displaying the output in the React components

