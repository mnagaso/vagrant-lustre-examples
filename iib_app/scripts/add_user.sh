#!/bin/bash
# This script adds a new user directly to MongoDB.
# Usage: ./add_user.sh <username> <password>

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <username> <password>"
  exit 1
fi

USERNAME="$1"
PASSWORD="$2"

if [ -z "$MONGODB_URI" ]; then
  echo "Please set the MONGODB_URI environment variable."
  exit 1
fi

echo "Adding user '$USERNAME' to the 'mydatabase' database..."

mongo "$MONGODB_URI" --quiet --eval "db.getSiblingDB('mydatabase').users.insert({ username: '$USERNAME', password: '$PASSWORD' })"

if [ $? -eq 0 ]; then
  echo "User added successfully."
else
  echo "Failed to add user."
fi
