#!/bin/bash

# Gemini Account Switcher
#
# This script allows you to switch between multiple Gemini accounts by swapping
# OAuth credential files and updating the active account configuration.
#
# Setup Instructions:
# 1. For each account you want to use:
#    a. Login to that account using: gemini auth login
#    b. Backup the OAuth credentials:
#       cp ~/.gemini/oauth_creds.json ~/.gemini/oauth_creds.account1.json
#    c. Repeat for account 2, 3, etc.
#
# 2. Create ~/.gemini_accounts with your account emails and project IDs:
#    GEMINI_ACCOUNT_1="account1@example.com"
#    GEMINI_PROJECT_1="project-id-1"
#    GEMINI_ACCOUNT_2="account2@example.com"
#    GEMINI_PROJECT_2="project-id-2"
#
# 3. Source this script in your .zshrc:
#    source ~/gemini_account_switcher.sh
#    alias gemini-switch='switch_gemini_account'
#
# Usage: gemini-switch [1|2]

function switch_gemini_account() {
  local config_file="$HOME/.gemini_accounts"
  local gemini_dir="$HOME/.gemini"

  # Check if config file exists
  if [[ ! -f "$config_file" ]]; then
    echo "❌ Configuration file not found: $config_file"
    echo ""
    echo "Create it with:"
    echo "  GEMINI_ACCOUNT_1=\"your_account_1@example.com\""
    echo "  GEMINI_ACCOUNT_2=\"your_account_2@example.com\""
    return 1
  fi

  # Source the config
  # shellcheck source=/dev/null
  source "$config_file"

  local account_choice=$1

  if [[ -z "$account_choice" ]]; then
    echo "Usage: switch_gemini_account [1|2]"
    echo ""
    echo "Available accounts:"
    [[ -n "$GEMINI_ACCOUNT_1" ]] && echo "  1: $GEMINI_ACCOUNT_1"
    [[ -n "$GEMINI_ACCOUNT_2" ]] && echo "  2: $GEMINI_ACCOUNT_2"
    return 1
  fi

  local target_account=""
  local target_project=""
  local target_creds_file=""

  # Determine which account to switch to
  if [[ "$account_choice" == "1" ]]; then
    target_account="$GEMINI_ACCOUNT_1"
    target_project="$GEMINI_PROJECT_1"
    target_creds_file="$gemini_dir/oauth_creds.account1.json"
  elif [[ "$account_choice" == "2" ]]; then
    target_account="$GEMINI_ACCOUNT_2"
    target_project="$GEMINI_PROJECT_2"
    target_creds_file="$gemini_dir/oauth_creds.account2.json"
  else
    echo "❌ Invalid account choice. Please use 1 or 2."
    return 1
  fi

  # Validate that the account email is configured
  if [[ -z "$target_account" ]]; then
    echo "❌ Account $account_choice is not configured in $config_file"
    return 1
  fi

  # Check if the credentials file exists
  if [[ ! -f "$target_creds_file" ]]; then
    echo "❌ Credentials file not found: $target_creds_file"
    echo ""
    echo "To create it:"
    echo "  1. Run: gemini auth login"
    echo "  2. Login with $target_account"
    echo "  3. Copy the credentials: cp ~/.gemini/oauth_creds.json $target_creds_file"
    return 1
  fi

  # Backup current oauth_creds.json if it exists
  if [[ -f "$gemini_dir/oauth_creds.json" ]]; then
    cp "$gemini_dir/oauth_creds.json" "$gemini_dir/oauth_creds.backup.json"
  fi

  # Swap in the new credentials
  cp "$target_creds_file" "$gemini_dir/oauth_creds.json"

  # Update google_accounts.json using jq if available, otherwise use sed
  if command -v jq &>/dev/null; then
    # Use jq for proper JSON manipulation
    local temp_file=$(mktemp)
    jq --arg email "$target_account" '.active = $email' "$gemini_dir/google_accounts.json" > "$temp_file"
    mv "$temp_file" "$gemini_dir/google_accounts.json"
  else
    # Fallback: simple sed replacement (less robust but works for simple cases)
    sed -i.bak "s/\"active\": \".*\"/\"active\": \"$target_account\"/" "$gemini_dir/google_accounts.json"
  fi

  # Set environment variable for Google Cloud Project
  if [[ -n "$target_project" ]]; then
    export GOOGLE_CLOUD_PROJECT="$target_project"
    echo "✓ Switched to Gemini Account $account_choice: $target_account"
    echo "  Project: $target_project"
  else
    echo "✓ Switched to Gemini Account $account_choice: $target_account"
    echo "  Warning: No project configured for this account"
  fi

  echo ""
  echo "Verify with: gemini auth status"
}

# Function to show current active account
function gemini_account_status() {
  local gemini_dir="$HOME/.gemini"

  if [[ -f "$gemini_dir/google_accounts.json" ]]; then
    if command -v jq &>/dev/null; then
      local active_account=$(jq -r '.active' "$gemini_dir/google_accounts.json")
      echo "Current active Gemini account: $active_account"
    else
      echo "Current google_accounts.json:"
      cat "$gemini_dir/google_accounts.json"
    fi
  else
    echo "No Gemini account configuration found"
  fi
}

# Function to backup current credentials
function gemini_backup_creds() {
  local gemini_dir="$HOME/.gemini"
  local account_num=$1

  if [[ -z "$account_num" ]]; then
    echo "Usage: gemini_backup_creds [1|2]"
    return 1
  fi

  if [[ ! -f "$gemini_dir/oauth_creds.json" ]]; then
    echo "❌ No credentials found at $gemini_dir/oauth_creds.json"
    echo "Run 'gemini auth login' first"
    return 1
  fi

  local backup_file="$gemini_dir/oauth_creds.account${account_num}.json"
  cp "$gemini_dir/oauth_creds.json" "$backup_file"
  echo "✓ Backed up credentials to $backup_file"
}
