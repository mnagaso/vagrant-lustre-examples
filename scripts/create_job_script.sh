#!/bin/bash
# Create a basic job submission script

cat > /lustre/vagrant/simple_job.sh <<EOF
#!/bin/bash
#SBATCH --job-name=simple_test
#SBATCH --output=job-%j.out
#SBATCH --error=job-%j.err
#SBATCH --ntasks=1
#SBATCH --time=5:00

echo "Running job on host \$(hostname)"
sleep 10
echo "Job completed successfully"
EOF
chmod +x /lustre/vagrant/simple_job.sh
