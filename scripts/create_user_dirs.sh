#!/bin/bash
# Create user directories in Lustre

# Ensure the Lustre mount point has proper permissions
chmod 755 /lustre

for user in vagrant user1 user2 user3 user4 user5; do
  dir="/lustre/${user}"
  if [ ! -d "$dir" ]; then
    echo "Creating directory $dir"
    mkdir -p "$dir"
    chown "$user:$user" "$dir"
    chmod 755 "$dir"
  else
    echo "Directory $dir already exists."
    # Ensure proper ownership even if directory exists
    chown "$user:$user" "$dir"
    chmod 755 "$dir"
  fi
done
echo "User directories creation completed."
