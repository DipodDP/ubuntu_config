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

# Rust environment setup with rustup
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to set up Rust with rustup? (y/N): " choice_rust
fi
if [ "$choice_rust" = "y" ] || [ "$SILENT_MODE" = "true" ]; then
  echo "Installing Rust with rustup..."

  if ! command -v rustc &>/dev/null; then
    # Install rustup
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # Source cargo env for current session
    source "$HOME/.cargo/env"

    # Add to .zshrc if not already present
    if ! grep -q ".cargo/env" ~/.zshrc; then
      echo 'source "$HOME/.cargo/env"' >> ~/.zshrc
    fi

    echo "Rust installed successfully"
  else
    echo "Rust already installed"
  fi

  # Show version
  rustc --version
  cargo --version
fi
