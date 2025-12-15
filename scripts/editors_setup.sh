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

# Development tools
choice_vscode="n" # Default to no
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to install VS Code? (y/N): " choice_vscode
fi
if [ "$choice_vscode" = "y" ]; then
  echo "Installing VS Code..."
  brew install --cask visual-studio-code

  # Enable key repeat for Vim mode
  defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

  echo "VS Code installed. Run 'code' command after sourcing ~/.zshrc"
fi

choice_cursor="n" # Default to no
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to install Cursor? (y/N): " choice_cursor
fi
if [ "$choice_cursor" = "y" ]; then
  echo "Installing Cursor..."
  brew install --cask cursor

  # Enable key repeat for Vim mode
  defaults write com.todesktop.230313mzl4w4u92 ApplePressAndHoldEnabled -bool false

  echo "Cursor installed"
fi

# Install Neovim config (optional)
choice_neovim_setup="n" # Default to no
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to set up a Neovim configuration? (y/N): " choice_neovim_setup
fi
if [ "$choice_neovim_setup" = "y" ]; then
  nvim_choice="1" # Default to nvscode
  if [ "$SILENT_MODE" = "false" ]; then
    echo ""
    echo "Choose Neovim configuration:"
    echo "  1. nvscode (VSCode/Cursor compatible)"
    echo "  2. Empty directory (manual setup)"
    echo "  3. Skip"
    read -p "Enter choice [1-3]: " nvim_choice
  fi

  case "$nvim_choice" in
    1)
      echo "Installing nvscode configuration..."

      # Backup existing config if present
      if [ -d ~/.config/nvim ]; then
        backup_dir=~/.config/nvim.backup.$(date +%s)
        echo "Backing up existing Neovim config to $backup_dir"
        mv ~/.config/nvim "$backup_dir"
      fi

      # Clone nvscode
      git clone https://github.com/DipodDP/nvscode.git "$HOME/.config/nvim"

      echo "nvscode configuration installed at $HOME/.config/nvim"
      echo ""
      echo "Setting up symlinks to VSCode/Cursor settings..."

      VSCODE_SETTINGS_PATH="$HOME/Library/Application Support/Code/User"
      CURSOR_SETTINGS_PATH="$HOME/Library/Application Support/Cursor/User"
      NVCODE_SETTINGS_PATH="$HOME/.config/nvim/.vscode"


      # Create VSCode/Cursor config directories if they don't exist
      mkdir -p "$VSCODE_SETTINGS_PATH"
      mkdir -p "$CURSOR_SETTINGS_PATH"

      # Check if nvscode has settings to symlink
      if [ -f "$NVCODE_SETTINGS_PATH/settings.json" ]; then
        # Backup existing VSCode settings if it's a regular file (not a symlink)
        if [ -f "$VSCODE_SETTINGS_PATH/settings.json" ] && [ ! -L "$VSCODE_SETTINGS_PATH/settings.json" ]; then
          cp "$VSCODE_SETTINGS_PATH/settings.json" "$VSCODE_SETTINGS_PATH/settings.json.backup.$(date +%s)"
          echo "Backed up existing VSCode settings"
        fi

        # Create symlink for VSCode
        rm -f "$VSCODE_SETTINGS_PATH/settings.json"
        ln -sf "$NVCODE_SETTINGS_PATH/settings.json" "$VSCODE_SETTINGS_PATH/settings.json"
        echo "✓ Created symlink: VSCode settings -> nvscode"

        # Backup existing Cursor settings if it's a regular file (not a symlink)
        if [ -f "$CURSOR_SETTINGS_PATH/settings.json" ] && [ ! -L "$CURSOR_SETTINGS_PATH/settings.json" ]; then
          cp "$CURSOR_SETTINGS_PATH/settings.json" "$CURSOR_SETTINGS_PATH/settings.json.backup.$(date +%s)"
          echo "Backed up existing Cursor settings"
        fi

        # Create symlink for Cursor
        rm -f "$CURSOR_SETTINGS_PATH/settings.json"
        ln -sf "$NVCODE_SETTINGS_PATH/settings.json" "$CURSOR_SETTINGS_PATH/settings.json"
        echo "✓ Created symlink: Cursor settings -> nvscode"
      else
        echo "Warning: settings.json not found in nvscode config at $NVCODE_SETTINGS_PATH"
      fi

      if [ -f "$NVCODE_SETTINGS_PATH/keybindings.json" ]; then
        # Create symlinks for keybindings
        rm -f "$VSCODE_SETTINGS_PATH/keybindings.json"
        ln -sf "$NVCODE_SETTINGS_PATH/keybindings.json" "$VSCODE_SETTINGS_PATH/keybindings.json"

        rm -f "$CURSOR_SETTINGS_PATH/keybindings.json"
        ln -sf "$NVCODE_SETTINGS_PATH/keybindings.json" "$CURSOR_SETTINGS_PATH/keybindings.json"
        echo "✓ Created symlinks: keybindings -> nvscode"
      else
        echo "Warning: keybindings.json not found in nvscode config at $NVCODE_SETTINGS_PATH"
      fi

      echo ""
      echo "nvscode setup complete!"
      echo "Make sure to install the VSCode Neovim extension:"
      echo "  - VSCode: https://marketplace.visualstudio.com/items?itemName=asvetliakov.vscode-neovim"
      echo "  - Or search for 'VSCode Neovim' in VS Code/Cursor extensions"
      ;;
    2)
      mkdir -p ~/.config/nvim
      echo "Neovim config directory created at ~/.config/nvim"
      echo "You can clone your preferred config there, for example:"
      echo "  git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim"
      ;;
    *)
      echo "Skipping Neovim configuration"
      ;;
  esac
fi