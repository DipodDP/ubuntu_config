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

# Node.js environment setup with fnm
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to set up Node.js with fnm? (y/N): " choice_node
fi
if [ "$choice_node" = "y" ] || [ "$SILENT_MODE" = "true" ]; then
  echo "Installing fnm (Fast Node Manager)..."
  brew install fnm

  # Add fnm to shell
  if ! grep -q "fnm env" ~/.zshrc; then
    cat >> ~/.zshrc <<'EOF'

# fnm configuration
eval "$(fnm env --use-on-cd)"
EOF
  fi

  # Activate fnm for current session
  eval "$(fnm env --use-on-cd)"

  echo "Installing Node.js LTS..."
  fnm install --lts
  fnm default lts-latest

  echo "Installing global npm packages..."
  npm install -g npm@latest pnpm
fi
