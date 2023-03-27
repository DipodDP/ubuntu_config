#!/bin/bash

while true; do
read -p "Do you want to configure remote access to a remote server by SSH? (y/N): " choice

if [ "$choice" = "y" ]; then
  read -p "Enter the remote server alias name: " server_name
  read -p "Enter the remote server IP address: " ip_address
  read -p "Enter the username for SSH access: " username
  read -p "Enter the SSH port (default is 22): " ssh_port

  # Configure SSH access
  ssh_config="Host $server_name\n"
  ssh_config+="\tHostName $ip_address\n"
  ssh_config+="\tUser $username\n"
  if [ ! -z "$ssh_port" ]; then
    ssh_config+="\tPort $ssh_port\n"
  fi

  # Add the SSH configuration to the SSH config file
  echo -e $ssh_config >> ~/.ssh/config
  ssh-copy-id $server_name
  echo "SSH access has been configured for remote server $ip_address"
else
  echo "SSH access configuration not requested. Exiting."
fi
break

done
