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
if [ "$SILENT_MODE" = true ]; then
  brew install -q git wget curl tree jq ripgrep fd bat eza htop tldr neovim
else
  brew install git wget curl tree jq ripgrep fd bat eza htop tldr neovim
fi

# Install GNU utilities for better compatibility
if [ "$SILENT_MODE" = true ]; then
  brew install -q coreutils findutils gnu-sed gnu-tar grep
else
  brew install coreutils findutils gnu-sed gnu-tar grep
fi

# Install development utilities
if [ "$SILENT_MODE" = true ]; then
  brew install -q tmux unzip gpg
else
  brew install tmux unzip gpg
fi

# Install build tools
brew install make gcc

# Install Nerd Font
echo ""
echo "Installing MesloLGS Nerd Font..."
if [ "$SILENT_MODE" = true ]; then
  brew install -q --cask font-meslo-lg-nerd-font
else
  brew install --cask font-meslo-lg-nerd-font
fi
