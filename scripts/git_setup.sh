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

# GIT configuration
if [ "$SILENT_MODE" = "false" ]; then
    echo ""
    read -p "Do you want to configure Git? (y/N): " choice_git
else
    choice_git="n" # Default to no in silent mode
fi

if [ "$choice_git" = "y" ]; then
  read -p "What is your Git email?: " git_email
  git config --global user.email "$git_email"
  read -p "What is your Git name?: " git_name
  git config --global user.name "$git_name"
  git config --global alias.st status
  git config --global alias.unstage 'reset HEAD --'

  echo "Git configured successfully"
fi

# Install Lazygit
echo ""
echo "Installing Lazygit..."
brew install lazygit

if ! grep -q "lg()" ~/.zshrc; then
  cat >> ~/.zshrc <<'EOF'

# Lazygit change directory integration
lg()
{
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    lazygit "$@"

    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
      cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
      rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}
EOF
fi
