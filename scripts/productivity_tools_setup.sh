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

# Productivity tools
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to install productivity tools? (Rectangle, Raycast, Maccy, Karabiner-Elements, Ghostty) (y/N): " choice_productivity
else
  choice_productivity="n" # Default to no in silent mode
fi
if [ "$choice_productivity" = "y" ]; then
  echo "Installing productivity tools..."
  brew install --cask rectangle        # Window management
  brew install --cask raycast          # Spotlight replacement
  brew install --cask maccy            # Clipboard manager
  brew install --cask karabiner-elements  # Keyboard customization
  brew install --cask appcleaner       # App uninstaller
  brew install --cask ghostty          # Terminal emulator

  echo "Productivity tools installed"
  echo "  - Rectangle: Window management (⌃⌥ + arrows)"
  echo "  - Raycast: Press ⌥Space to launch"
  echo "  - Maccy: Clipboard history (⇧⌘C)"
  echo "  - Karabiner-Elements: Keyboard remapping"
  echo "  - AppCleaner: Clean app uninstall"
  echo "  - Ghostty: Modern, GPU-accelerated terminal"
fi
