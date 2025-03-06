#!/bin/bash

echo "Stopping collectl on MXS node..."
vagrant ssh mxs -c "sudo pkill -f 'collectl.*fefssv.ph' || echo 'No collectl process running on MXS'"

echo "Stopping collectl on OSS node..."
vagrant ssh oss -c "sudo pkill -f 'collectl.*fefssv.ph' || echo 'No collectl process running on OSS'"

echo "Collectl stopped on both nodes."
