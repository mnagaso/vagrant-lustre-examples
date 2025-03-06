#!/bin/bash

# Exit on error
set -e

# Check if vagrant-scp plugin is installed
if ! vagrant plugin list | grep -q vagrant-scp; then
    echo "Installing vagrant-scp plugin..."
    vagrant plugin install vagrant-scp
fi

# Check if fefssv.ph exists in the current directory
if [ ! -f "fefssv.ph" ]; then
    echo "Error: fefssv.ph file not found in the current directory."
    echo "Please place the fefssv.ph file in the same directory as this script."
    exit 1
fi

# Calculate a start time 1 minute from now
START_TIME=$(date -d "+1 minute" +%H:%M)
echo "Scheduling collectl to start at: $START_TIME"

echo "Copying fefssv.ph to MXS node..."
vagrant scp fefssv.ph mxs:/home/vagrant/

echo "Copying fefssv.ph to OSS node..."
vagrant scp fefssv.ph oss:/home/vagrant/

echo "Starting collectl on MXS node..."
vagrant ssh mxs -c "sudo collectl -f tmp -r$START_TIME,10 -m -F60 -s+YZ -i10:60:300 import ~/fefssv.ph,mdt=phoenix-MDT0000,v" &
MXS_PID=$!
echo "MXS collectl started with process ID: $MXS_PID"

echo "Starting collectl on OSS node..."
vagrant ssh oss -c "sudo collectl -f tmp -r$START_TIME,10 -m -F60 -s+YZ -i10:60:300 import ~/fefssv.ph,ost=phoenix-OST0000,v" &
OSS_PID=$!
echo "OSS collectl started with process ID: $OSS_PID"

echo "Collectl is now scheduled to run on both nodes starting at $START_TIME."
echo "To stop the collection, press Ctrl+C or run ./stop_collectl.sh"

# Wait for both background processes
wait $MXS_PID $OSS_PID
