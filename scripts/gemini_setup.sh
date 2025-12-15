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

# Gemini Account Switcher Setup
choice_gemini="n"  # Initialize to prevent unbound variable error
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to set up Gemini Account Switcher? (y/N): " choice_gemini
fi
if [ "$choice_gemini" = "y" ]; then
  echo "Setting up Gemini Account Switcher..."
  echo ""
  echo "This allows you to switch between multiple Gemini accounts by swapping"
  echo "OAuth credentials. No Google Cloud SDK required!"
  echo ""

  # Copy the script to the home directory
  cp "$SCRIPT_DIR/scripts/gemini_account_switcher.sh" ~/
  chmod +x ~/gemini_account_switcher.sh

  # Create a default .gemini_accounts file if it doesn't exist
  if [ ! -f ~/.gemini_accounts ]; then
    cat > ~/.gemini_accounts <<'EOF'
GEMINI_ACCOUNT_1="your_account_1@example.com"
GEMINI_PROJECT_1="your_project_id_1"
GEMINI_ACCOUNT_2="your_account_2@example.com"
GEMINI_PROJECT_2="your_project_id_2"
EOF
    echo "Created ~/.gemini_accounts - update it with your account emails and project IDs"
  fi

  # Source the script in .zshrc
  if ! grep -q "gemini_account_switcher.sh" ~/.zshrc; then
    cat >> ~/.zshrc <<'EOF'

# Gemini Account Switcher
source ~/gemini_account_switcher.sh
alias gemini-switch='switch_gemini_account'
alias gemini-status='gemini_account_status'
alias gemini-backup='gemini_backup_creds'
EOF
  fi

  echo ""
  echo "Gemini Account Switcher setup complete!"
  echo ""
  echo "Setup Instructions:"
  echo "1. Edit ~/.gemini_accounts with your account emails"
  echo "2. For each account:"
  echo "   a. Login: gemini auth login"
  echo "   b. Backup credentials: gemini-backup 1  (or 2 for second account)"
  echo ""
  echo "Usage:"
  echo "  gemini-switch [1|2]  - Switch between accounts"
  echo "  gemini-status        - Show current active account"
  echo "  gemini-backup [1|2]  - Backup current credentials"
fi
