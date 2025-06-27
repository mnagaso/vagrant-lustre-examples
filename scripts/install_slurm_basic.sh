#!/bin/bash
# Install basic Slurm packages

dnf install -y --enablerepo=powertools libaec
dnf install -y slurm slurm-slurmd slurm-slurmctld slurm-slurmdbd munge
