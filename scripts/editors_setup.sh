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

# Function to install extensions from tracked list
install_extensions() {
  local editor_cmd="$1"
  local editor_name="$2"
  local extensions_file="$SCRIPT_DIR/config/vscode_extensions.txt"

  # Check if extensions file exists
  if [ ! -f "$extensions_file" ]; then
    echo "No extensions file found at $extensions_file"
    echo "Run scripts/editors_export_extensions.sh to create one"
    return 0
  fi

  # Check if editor command exists
  if ! command -v "$editor_cmd" &> /dev/null; then
    echo "Warning: $editor_cmd command not found, skipping extension installation"
    return 0
  fi

  echo ""
  echo "Installing extensions for $editor_name..."

  local total=0
  local installed=0
  local failed=0
  local skipped=0

  while IFS= read -r extension || [ -n "$extension" ]; do
    # Skip empty lines and comments
    [[ -z "$extension" || "$extension" =~ ^[[:space:]]*# ]] && continue

    total=$((total + 1))

    # Check if already installed
    if "$editor_cmd" --list-extensions 2>/dev/null | grep -qi "^${extension}$"; then
      echo "  ✓ $extension (already installed)"
      skipped=$((skipped + 1))
      continue
    fi

    # Install extension
    echo "  Installing $extension..."
    if "$editor_cmd" --install-extension "$extension" --force &> /dev/null; then
      echo "  ✓ $extension"
      installed=$((installed + 1))
    else
      echo "  ✗ $extension (failed)"
      failed=$((failed + 1))
    fi
  done < "$extensions_file"

  # Summary
  if [ $total -gt 0 ]; then
    echo ""
    echo "$editor_name Extension Installation Summary:"
    echo "  Total: $total extensions"
    echo "  Installed: $installed"
    echo "  Already present: $skipped"
    if [ $failed -gt 0 ]; then
      echo "  Failed: $failed"
    fi
  fi
}

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

  # Install extensions from tracked list
  install_extensions "code" "VS Code"
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

  # Install extensions from tracked list
  install_extensions "cursor" "Cursor"
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