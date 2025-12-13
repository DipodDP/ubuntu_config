# Development Environment Configuration Scripts

This repository contains a collection of scripts to automate the setup of development environments on Ubuntu and macOS.

## Ubuntu Development Environment

Basic Ubuntu configuration script for a Python development server.

### Description

This is a shell script (`my_config.sh`) that performs several tasks related to system configuration and installation of useful utilities. The script performs the following tasks:

1.  Creates an admin user (if requested) and updates the system.
2.  Sets up some Bash aliases.
3.  Installs various utilities like `ripgrep`, `netcat`, `bat`, `lsof`, `htop`, `tmux`, `lazygit`, `eza`, `fd-find` and other.
4.  Installs compilers like `make` and `gcc`.
5.  Configures GIT with user email and name, and sets up some aliases.
6.  Generates an SSH key and adds it to the system buffer, and configures access to a remote server by SSH.
7.  Installs Python 3.11 from a repository, Node.js, and LSP.
8.  Installs `nvim` and sets up its configuration.
9.  Cleans up the system.
10. Finally, it notifies the user that the installation is completed.

Note: The script provides some optional tasks: admin user creation and configuring alias for access to a remote server by SSH.

### Installation

Clone the repository and navigate into the directory:
```bash
git clone https://github.com/DipodDP/ubuntu_config.git
cd ubuntu_config/
```

### Usage

To run the main setup script for Ubuntu:
```bash
./my_config.sh
```

To configure an SSH connection alias:
```bash
./ssh.sh
```

For WSL users, to fix DNS issues when using a VPN and to connect to the Windows host:
```bash
./wsl_DNS_fix.sh
```

---

## macOS Development Environment

A comprehensive setup script for bootstrapping a macOS development environment.

### Description

The main script (`macos_config.sh`) automates the installation and configuration of a wide range of development tools and system preferences on macOS.

Key features include:
-   **Core Tools**: Installs Homebrew, Git, and essential CLI utilities (`ripgrep`, `fd`, `bat`, `eza`, `neovim`, etc.).
-   **Shell Environment**: Sets up Zsh with Oh My Zsh, Powerlevel10k theme, and useful plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`, `zoxide`).
-   **Development Runtimes**: Configures isolated development environments for Python (with `pyenv`) and Node.js (with `fnm`). Also supports Rust via `rustup` and Go for CLI tools.
-   **Gemini CLI**: Optionally installs the `gemini-cli` for interacting with Google's Gemini models.
-   **Editors**: Optionally installs VS Code and/or Cursor, and sets up a Neovim configuration (`nvscode`).
-   **Productivity Tools**: Optionally installs Rectangle for window management, Raycast as a Spotlight replacement, Maccy for clipboard history, and more.
-   **System Tweaks**: Optionally configures macOS preferences for a better development experience (e.g., fast key repeat, showing hidden files, freeing up port 5000).

### Usage

First, make the scripts executable:
```bash
chmod +x macos_*.sh
```

To run the interactive setup:
```bash
./macos_config.sh
```
The script will prompt you for each major section to be installed.

**Silent Mode (unattended installation)**

To run the script in a non-interactive "silent mode" that installs all tools with default settings, use the `--silent` or `all` parameter:
```bash
./macos_config.sh --silent
```
or
```bash
./macos_config.sh all
```
In silent mode, user-specific configurations like Git user/email and SSH keys will be skipped.

### Additional Scripts

-   `macos_fish_setup.sh`: Optional setup for the Fish shell.
-   `macos_remote_access.sh`: Optional setup for remote access using NoMachine and Tailscale.

For more detailed information, including tips for developers new to macOS, see [README_MACOS.md](README_MACOS.md).

---

## Gemini Account Switcher

Switch between multiple Google Gemini accounts without requiring Google Cloud SDK.

### How It Works

The Gemini CLI stores account information in `~/.gemini/`:
- **`google_accounts.json`**: Tracks which account is currently active
- **`oauth_creds.json`**: Contains OAuth tokens for the active account

The switcher works by:
1. Storing separate OAuth credential files for each account
2. Swapping `oauth_creds.json` when switching accounts
3. Updating `google_accounts.json` to reflect the active account

### Initial Setup

#### 1. Install via macos_config.sh

Run the main setup script and choose to install Gemini Account Switcher:

```bash
./macos_config.sh
# When prompted, choose "y" for Gemini Account Switcher
```

#### 2. Manual Installation

If you've already run `macos_config.sh`, you can set up manually:

```bash
# Copy the script
cp gemini_account_switcher.sh ~/
chmod +x ~/gemini_account_switcher.sh

# Add to ~/.zshrc
cat >> ~/.zshrc <<'EOF'

# Gemini Account Switcher
source ~/gemini_account_switcher.sh
alias gemini-switch='switch_gemini_account'
alias gemini-status='gemini_account_status'
alias gemini-backup='gemini_backup_creds'
EOF

# Reload shell
source ~/.zshrc
```

### Account Configuration

#### 1. Create Account Configuration File

Edit `~/.gemini_accounts`:

```bash
GEMINI_ACCOUNT_1="your_first_account@gmail.com"
GEMINI_PROJECT_1="your-project-id-1"
GEMINI_ACCOUNT_2="your_second_account@gmail.com"
GEMINI_PROJECT_2="your-project-id-2"
```

The `GOOGLE_CLOUD_PROJECT` environment variable is used by Gemini CLI for session management and other features.

#### 2. Backup Credentials for Each Account

For **Account 1**:
```bash
# Login to first account
gemini auth login
# Follow the browser authentication flow for account 1

# Backup the credentials
gemini-backup 1
```

For **Account 2**:
```bash
# Login to second account
gemini auth login
# Follow the browser authentication flow for account 2

# Backup the credentials
gemini-backup 2
```

This creates:
- `~/.gemini/oauth_creds.account1.json`
- `~/.gemini/oauth_creds.account2.json`

### Usage

#### Switch Between Accounts

```bash
# Switch to account 1
gemini-switch 1

# Switch to account 2
gemini-switch 2
```

#### Check Current Account

```bash
gemini-status
# Output: Current active Gemini account: your_first_account@gmail.com
```

#### Verify Switch Worked

```bash
gemini auth status
```

### Troubleshooting

#### "Credentials file not found" Error

This means you haven't backed up credentials for that account yet. Follow the setup steps:

```bash
# Login to the account
gemini auth login

# Backup the credentials
gemini-backup [1|2]
```

#### Manually Backup Credentials

If the `gemini-backup` command isn't working:

```bash
# For account 1
cp ~/.gemini/oauth_creds.json ~/.gemini/oauth_creds.account1.json

# For account 2
cp ~/.gemini/oauth_creds.json ~/.gemini/oauth_creds.account2.json
```

#### Check Credential Files Exist

```bash
ls -la ~/.gemini/oauth_creds*.json
```

You should see:
- `oauth_creds.json` (current active account)
- `oauth_creds.account1.json` (account 1 backup)
- `oauth_creds.account2.json` (account 2 backup)
- `oauth_creds.backup.json` (automatic backup created during switches)

### Technical Details

#### File Structure

```
~/.gemini/
├── google_accounts.json      # Active account tracker
├── oauth_creds.json          # Current active credentials
├── oauth_creds.account1.json # Account 1 credentials backup
├── oauth_creds.account2.json # Account 2 credentials backup
└── oauth_creds.backup.json   # Last active credentials backup
```

#### What Gets Swapped

When you run `gemini-switch 1`:

1. **Backup current credentials**:
   ```bash
   cp ~/.gemini/oauth_creds.json ~/.gemini/oauth_creds.backup.json
   ```

2. **Swap in account 1 credentials**:
   ```bash
   cp ~/.gemini/oauth_creds.account1.json ~/.gemini/oauth_creds.json
   ```

3. **Update active account** in `google_accounts.json`:
   ```json
   {
     "active": "your_first_account@gmail.com",
     "old": ["your_second_account@gmail.com"]
   }
   ```

4. **Set environment variable**:
   ```bash
   export GOOGLE_CLOUD_PROJECT="your-project-id-1"
   ```

#### OAuth Token Contents

The `oauth_creds.json` file contains:
- `access_token`: Short-lived token for API requests
- `refresh_token`: Long-lived token to get new access tokens
- `id_token`: JWT with user information
- `expiry_date`: When the access token expires

The Gemini CLI automatically refreshes expired access tokens using the refresh token.
