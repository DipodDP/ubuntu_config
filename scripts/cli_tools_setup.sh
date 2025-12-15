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

# Install essential CLI tools
echo ""
echo "Installing essential CLI tools..."
brew install git wget curl tree jq ripgrep fd bat eza htop tldr neovim

# Install GNU utilities for better compatibility
brew install coreutils findutils gnu-sed gnu-tar grep

# Install development utilities
brew install tmux unzip gpg

# Install build tools
brew install make gcc

# Install Nerd Font
echo ""
echo "Installing MesloLGS Nerd Font..."
brew install --cask font-meslo-lg-nerd-font
