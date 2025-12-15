#!/bin/bash
set -e

SILENT_MODE=false
if [ "$1" = "--silent" ] || [ "$1" = "all" ]; then
  SILENT_MODE=true
  echo "Running in silent mode - installing essential tools only, skipping optional components"
else
  echo "Running in interactive mode - will prompt for each optional component"
fi

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# Validate critical environment variables
if [ -z "$SCRIPT_DIR" ]; then
  echo "Error: Failed to determine script directory"
  exit 1
fi

if [ ! -d "$SCRIPT_DIR/scripts" ]; then
  echo "Error: Scripts directory not found at $SCRIPT_DIR/scripts"
  exit 1
fi

export SILENT_MODE
export SCRIPT_DIR

cd

echo "macOS Development Environment Setup"
echo "===================================="
echo ""

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  BREW_PREFIX="/opt/homebrew"
  echo "Detected: Apple Silicon (ARM64)"
else
  BREW_PREFIX="/usr/local"
  echo "Detected: Intel (x86_64)"
fi
echo ""

# Install Xcode Command Line Tools
echo "Installing Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  if [ "$SILENT_MODE" = "true" ]; then
    echo "Error: Xcode Command Line Tools are not installed. Cannot proceed in silent mode."
    echo "Please install them manually by running 'xcode-select --install' and run this script again."
    exit 1
  else
    xcode-select --install
    echo "Please complete the Xcode Command Line Tools installation in the dialog,"
    echo "then press Enter to continue..."
    read -r
  fi
else
  echo "Xcode Command Line Tools already installed"
fi

# Install Homebrew
echo ""
echo "Installing Homebrew..."
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH
  eval "$($BREW_PREFIX/bin/brew shellenv)"

  # Add to shell profiles
  if ! grep -q "brew shellenv" ~/.zprofile; then
    echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> ~/.zprofile
  fi

  if ! grep -q "brew shellenv" ~/.zshrc; then
    echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> ~/.zshrc
  fi
else
  echo "Homebrew already installed"
  eval "$($BREW_PREFIX/bin/brew shellenv)"
fi

# Update Homebrew
brew update

# Function to run scripts with error context
run_script() {
  local script_path="$1"
  local script_name=$(basename "$script_path")

  if [ ! -f "$script_path" ]; then
    echo "Error: Script not found: $script_path"
    exit 1
  fi

  if ! bash "$script_path"; then
    echo "Error: $script_name failed. Aborting setup."
    exit 1
  fi
}

# Proxy setup
run_script "$SCRIPT_DIR/scripts/proxy_setup.sh"

# Install essential CLI tools
run_script "$SCRIPT_DIR/scripts/cli_tools_setup.sh"

# Zsh setup
run_script "$SCRIPT_DIR/scripts/zsh_setup.sh"

# Tmux setup
run_script "$SCRIPT_DIR/scripts/tmux_setup.sh"

# Python environment setup
run_script "$SCRIPT_DIR/scripts/python_setup.sh"

# Node.js environment setup
run_script "$SCRIPT_DIR/scripts/node_setup.sh"

# Rust environment setup
run_script "$SCRIPT_DIR/scripts/rust_setup.sh"

# OrbStack setup
run_script "$SCRIPT_DIR/scripts/orbstack_setup.sh"



# Gemini Account Switcher Setup
run_script "$SCRIPT_DIR/scripts/gemini_setup.sh"

# GIT and Lazygit setup
run_script "$SCRIPT_DIR/scripts/git_setup.sh"

# Development tools
run_script "$SCRIPT_DIR/scripts/editors_setup.sh"

# Productivity tools setup
run_script "$SCRIPT_DIR/scripts/productivity_tools_setup.sh"

# macOS system preferences setup
run_script "$SCRIPT_DIR/scripts/preferences/macos_preferences_setup.sh"

# SSH setup
run_script "$SCRIPT_DIR/scripts/ssh_setup.sh"



echo ""
echo "============================================"
echo "macOS Development Environment Setup Complete!"
echo "============================================"
echo ""
echo "Important next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Configure p10k theme: p10k configure"
echo "3. If you installed Ghostty, configure the font:"
echo "   Settings → Profiles → Text → Font → MesloLGS NF"
echo "4. Grant necessary permissions to apps in System Settings"
echo ""
echo "Optional:"
echo "- Run macos_fish_setup.sh for Fish shell configuration"
echo "- Run macos_remote_access.sh for NoMachine + Tailscale setup"
echo ""
