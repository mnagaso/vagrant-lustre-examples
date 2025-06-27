#!/bin/bash
# Create user directories in Lustre

for user in vagrant user1 user2 user3 user4 user5; do
  dir="/lustre/${user}"
  if [ ! -d "$dir" ]; then
    echo "Creating directory $dir"
    mkdir -p "$dir"
    chown "$user:$user" "$dir"
  else
    echo "Directory $dir already exists."
  fi
done
echo "User directories creation completed."
