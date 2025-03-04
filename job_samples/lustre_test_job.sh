#!/bin/bash
#SBATCH --job-name=lustre_test_job
#SBATCH --output=lustre_test_job.out
#SBATCH --error=lustre_test_job.err
#SBATCH --ntasks=1
#SBATCH --time=00:10:00

# Define Lustre mount point and test file name
LUSTRE_MOUNT="/lustre"
TEST_FILE="${LUSTRE_MOUNT}/lustre_test_$(date +%s).bin"

# data size to be written in MB
DATA_SIZE_MB=1024
# create a file of size DATA_SIZE_MB
dd if=/dev/zero of="$TEST_FILE" bs=1M count=$DATA_SIZE_MB

echo "Starting Lustre test job..."
echo "This is a test file for Lustre system" > "$TEST_FILE"
echo "Created test file: $TEST_FILE"

echo "Displaying file content:"
cat "$TEST_FILE"

echo "Disk usage for ${LUSTRE_MOUNT}:"
df -h "$LUSTRE_MOUNT"
