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

# OrbStack setup (fast, native Docker & Linux on macOS)
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to install OrbStack (fast Docker & Linux environment)? (y/N): " choice_orbstack
fi
if [ "$choice_orbstack" = "y" ] || [ "$SILENT_MODE" = "true" ]; then
  echo "Installing OrbStack..."
  brew install --cask orbstack
  echo "OrbStack installed successfully."
  echo "It provides a faster, native replacement for Docker Desktop."
  echo "Start OrbStack from your Applications folder to begin."
fi
