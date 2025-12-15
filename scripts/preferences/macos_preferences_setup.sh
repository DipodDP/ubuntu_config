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

# macOS system preferences
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to configure macOS system preferences for development? (y/N): " choice_macos_prefs
else
  choice_macos_prefs="n" # Default to no in silent mode
fi
if [ "$choice_macos_prefs" = "y" ]; then
  echo "Configuring system preferences..."

  # Show hidden files in Finder
  defaults write com.apple.finder AppleShowAllFiles -bool true

  # Show file extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # Show path bar in Finder
  defaults write com.apple.finder ShowPathbar -bool true

  # Disable press-and-hold for keys in favor of key repeat
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

  # Set fast key repeat rate
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  # Disable AirPlay Receiver to free port 5000
  defaults write com.apple.ControlCenter AirplayRecieverEnabled -bool false

  # Restart Finder to apply changes
  killall Finder

  echo "System preferences configured"
fi
