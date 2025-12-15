#!/bin/bash
set -e

# Validate environment
if [ -z "$SCRIPT_DIR" ]; then
  echo "Error: SCRIPT_DIR not set. This script must be called from macos_config.sh"
  exit 1
fi

if [ -z "$SILENT_MODE" ]; then
  echo "Warning: SILENT_MODE not set, defaulting to false"
  SILENT_MODE=false
fi

# SSH key generation
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to generate an SSH key? (y/N): " choice_ssh
else
  choice_ssh="n" # Default to no in silent mode
fi
if [ "$choice_ssh" = "y" ]; then
  if [ -n "$git_email" ]; then
    ssh-keygen -t ed25519 -C "$git_email"
  else
    read -p "Enter your email for SSH key: " ssh_email
    ssh-keygen -t ed25519 -C "$ssh_email"
  fi

  # Add to SSH agent
  eval "$(ssh-agent -s)"

  # Create SSH config for macOS keychain
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  if [ ! -f ~/.ssh/config ]; then
    cat > ~/.ssh/config <<'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
    chmod 600 ~/.ssh/config
  fi

  ssh-add --apple-use-keychain ~/.ssh/id_ed25519

  echo ""
  echo "SSH key for GitHub (copied to clipboard):"
  pbcopy < ~/.ssh/id_ed25519.pub
  cat ~/.ssh/id_ed25519.pub
  echo ""
  echo "The SSH public key has been copied to your clipboard."
  echo "Add it to GitHub: https://github.com/settings/keys"
fi

# Configure SSH access to remote server
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to configure SSH access to a remote server? (y/N): " choice_remote_ssh
else
  choice_remote_ssh="n" # Default to no in silent mode
fi
if [ "$choice_remote_ssh" = "y" ]; then
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
fi
