#!/bin/bash
set -e

read -p "Do you want to configure remote access to a remote server by SSH? (y/N): " choice

if [ "$choice" = "y" ]; then
  read -p "Enter the remote server alias name: " server_name
  read -p "Enter the remote server IP address: " ip_address
  read -p "Enter the username for SSH access: " username
  read -p "Enter the SSH port (default is 22): " ssh_port

  # Ensure SSH config directory exists
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  touch ~/.ssh/config
  chmod 600 ~/.ssh/config

  # Configure SSH access
  cat >> ~/.ssh/config <<EOF
Host $server_name
	HostName $ip_address
	User $username
EOF

  if [ -n "$ssh_port" ]; then
    echo "	Port $ssh_port" >> ~/.ssh/config
  fi

  # Copy SSH key to server
  ssh-copy-id "$server_name"
  echo "SSH access has been configured for remote server $ip_address"
else
  echo "SSH access configuration not requested. Exiting."
fi
