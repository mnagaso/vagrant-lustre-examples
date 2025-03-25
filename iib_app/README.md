# Lustre Cluster Web Management Interface

This application provides a web-based management interface for the Lustre cluster with Slurm workload manager.

## Overview

The web application allows users to:
- Monitor Lustre filesystem status
- View Slurm job statistics
- Manage user accounts
- Submit and monitor jobs through a web interface

## Project Structure

```
iib_app/
├── docker-compose.yml    # Docker configuration for web app and MongoDB
├── mongo-init.js         # MongoDB initialization script
├── scripts/              # Utility scripts
│   └── add_user.sh       # Script for adding users to MongoDB
└── web/                  # Next.js 15 application
    ├── app/              # Next.js App Router structure
    │   ├── components/   # React components
    │   ├── globals.css   # Global styles with Tailwind
    │   ├── layout.tsx    # Root layout with font configuration
    │   └── page.tsx      # Main page component
    ├── Dockerfile        # Container configuration for Next.js app
    ├── package.json      # Dependencies and scripts
    └── ... (config files)
```

## Technology Stack

- **Frontend**: Next.js 15 with React 19, using the App Router architecture
- **Styling**: Tailwind CSS 4
- **Database**: MongoDB
- **Containerization**: Docker and Docker Compose
- **Authentication**: Custom auth with MongoDB user storage

## Setup and Development

### Prerequisites

- Docker and Docker Compose
- Node.js 18+ (for local development)

### Local Development

1. Install dependencies:
   ```bash
   cd web
   npm install
   ```

2. Start the development server:
   ```bash
   npm run dev
   ```

3. Open [http://localhost:3000](http://localhost:3000) to view the application

### Using Docker

1. Start the entire stack:
   ```bash
   cd iib_app
   docker-compose up
   ```

2. The application will be accessible at [http://localhost:3000](http://localhost:3000)

## MongoDB Configuration

The MongoDB database is initialized with a default admin user:
- Username: `admin`
- Password: `admin` (should be changed in production)

Additional users can be added using the `scripts/add_user.sh` script.

## Deployment on the Lustre Cluster

This application is designed to run on the login node of the Lustre cluster. The web interface is accessible on port 3000.

To deploy on the login node:

1. SSH into the login node:
   ```bash
   vagrant ssh login
   ```

2. Navigate to the shared directory:
   ```bash
   cd /lustre/vagrant/iib_app
   ```

3. Start the application:
   ```bash
   docker-compose up -d
   ```

## Adding Components

To extend the UI, create new components in the `web/app/components` directory and import them into the appropriate pages.

## Connecting to Lustre and Slurm

The application can be extended to integrate with Lustre and Slurm by:
1. Creating API routes in `web/app/api` directory
2. Implementing server-side code to execute shell commands
3. Displaying the output in the React components

See documentation for more details on implementing these integrations.