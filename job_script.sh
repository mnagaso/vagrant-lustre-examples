#!/bin/bash
#SBATCH --job-name=create_file
#SBATCH --output=/lustre/job_output.txt
#SBATCH --error=/lustre/job_error.txt
#SBATCH --ntasks=1
#SBATCH --time=00:05:00
#SBATCH --mem=100MB

# Create a 100MB file and store it in the Lustre disk
dd if=/dev/zero of=/lustre/100MB_file bs=1M count=100
