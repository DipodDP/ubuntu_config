# macOS Development Environment Setup Guide

Complete guide for bootstrapping a macOS development environment, with special focus for developers transitioning from Windows or Linux.

## Quick Start

```bash
# Clone this repository
git clone <repository-url>
cd ubuntu_config

# Checkout macOS branch
git checkout feature/macos-bootstrap

# Make scripts executable
chmod +x macos_*.sh

# Run main setup script
./macos_config.sh

# Optional: Setup Fish shell
./macos_fish_setup.sh

# Optional: Setup remote access
./macos_remote_access.sh
```

## What Gets Installed

### Core Development Tools
- **Homebrew** - Package manager for macOS
- **Git** - Version control
- **Essential CLI tools**: ripgrep, fd, bat, eza, htop, neovim, jq, tree
- **Build tools**: make, gcc
- **GNU utilities**: coreutils, findutils, gnu-sed, gnu-tar

### Terminal & Shell
- **iTerm2** - Advanced terminal emulator
- **Zsh** with Oh My Zsh framework
- **Powerlevel10k** theme
- **Plugins**: zsh-autosuggestions, zsh-syntax-highlighting
- **zoxide** - Smarter cd command
- **tmux** - Terminal multiplexer with gpakosz config

### Development Environments
- **Python**: pyenv + pyenv-virtualenv + Python 3.12
- **Node.js**: fnm (Fast Node Manager) + LTS version + pnpm
- **Neovim**: Ready for your preferred configuration

### Editors & IDEs
- **VS Code** (optional) - With key repeat enabled for Vim mode
- **Cursor** (optional) - AI-powered editor with key repeat enabled

### Productivity Tools (optional)
- **Rectangle** - Window management (⌃⌥ + arrows)
- **Raycast** - Spotlight replacement (⌥Space)
- **Maccy** - Clipboard manager (⇧⌘C)
- **Karabiner-Elements** - Keyboard customization
- **AppCleaner** - Clean app uninstall
- **Lazygit** - Terminal UI for git

### Remote Access (optional)
- **Tailscale** - Zero-config VPN for secure access
- **NoMachine** - Remote desktop for iPad/iPhone access

## macOS Fundamentals for Windows/Linux Users

### The Return Key Renames Files (Not Opens Them!)

This is the **most confusing difference** for new macOS users:

| Action | macOS | Windows/Linux |
|--------|-------|---------------|
| Open file | **⌘O** or **⌘↓** or **Double-click** | Enter |
| Rename file | **Return/Enter** | F2 |
| Quick preview | **Spacebar** | - |

### Window Management

The traffic light buttons (red, yellow, green) work differently:

- **Red (X)**: Closes window **but keeps app running** (look for dot under Dock icon)
- **Yellow (-)**: Minimizes to Dock
- **Green**: Full screen mode (or **Option+Green** for traditional maximize)

To fully quit an app: **⌘Q**

### Native Window Tiling (macOS Sequoia)

| Action | Shortcut |
|--------|----------|
| Left half | **Fn + ⌃ + ←** |
| Right half | **Fn + ⌃ + →** |
| Fill screen | **Fn + ⌃ + F** |
| Top half | **Fn + ⌃ + ↑** |
| Bottom half | **Fn + ⌃ + ↓** |

Or hover over the green button for tiling options.

### File Operations

**No traditional "Cut" for files** - Instead:
1. **⌘C** to copy
2. Navigate to destination
3. **⌘⌥V** to move (not paste)

Or hold **Option** when right-clicking to see "Move Item Here"

### Essential Keyboard Shortcuts

| Action | macOS | Windows |
|--------|-------|---------|
| Quit app | **⌘Q** | Alt+F4 |
| Close window | **⌘W** | Ctrl+W |
| New window | **⌘N** | Win+E |
| Switch apps | **⌘Tab** | Alt+Tab |
| Switch windows (same app) | **⌘`** | - |
| Spotlight search | **⌘Space** | Win+S |
| Force quit | **⌥⌘Esc** | Ctrl+Shift+Esc |
| Screenshot selection | **⇧⌘4** | Win+Shift+S |
| Screenshot menu | **⇧⌘5** | - |
| Lock screen | **⌃⌘Q** | Win+L |
| Show/hide hidden files | **⌘⇧.** | - |
| Get Info (Properties) | **⌘I** | Alt+Enter |

### Text Navigation in Editors

| Action | macOS | Windows |
|--------|-------|---------|
| Word left/right | **⌥←/→** | Ctrl+←/→ |
| Line start/end | **⌘←/→** | Home/End |
| Document start/end | **⌘↑/↓** | Ctrl+Home/End |
| Delete word | **⌥Delete** | Ctrl+Backspace |

## File System Layout

### No Drive Letters

Everything mounts under a single root `/`:
- Your home: `/Users/username` (shortcut: `~`)
- Applications: `/Applications`
- External drives: `/Volumes/DriveName`

### Important Directories

| Windows | macOS |
|---------|-------|
| `C:\Users\YourName\Documents` | `/Users/YourName/Documents` |
| `C:\Program Files` | `/Applications` |
| `%APPDATA%` | `~/Library/Application Support` |
| Backslashes `\` | Forward slashes `/` |

### Hidden Folders

- `~/.config` - Application configs (XDG standard)
- `~/.ssh` - SSH keys
- `~/.zshrc` - Zsh configuration
- `~/Library` - macOS app data (hidden by default)
- `/opt/homebrew` - Homebrew on Apple Silicon
- `/usr/local` - Homebrew on Intel

**Access ~/Library**: Finder → Go menu → hold **Option** → Library appears

### Finder Tips

**Show path bar**: Finder → View → Show Path Bar (**⌥⌘P**)

**Show file extensions**: Finder → Settings → Advanced → "Show all filename extensions"

**Go to folder**: **⌘⇧G** then type path (e.g., `/usr/local/bin`)

**Copy file path**: Right-click → hold **Option** → "Copy as Pathname"

## Installing Applications

### Methods

1. **App Store** (easiest, most secure)
2. **DMG files** (most common):
   - Download .dmg
   - Double-click to mount
   - Drag .app to Applications folder
   - Eject DMG
   - Delete .dmg file
3. **PKG installers** (for system-level apps)
4. **Homebrew** (recommended for developers)

```bash
brew install --cask google-chrome
brew install --cask visual-studio-code
```

### Uninstalling

- App Store apps: Launchpad → Hold click → X
- Other apps: Drag from Applications to Trash
- Complete removal: Use AppCleaner (removes leftover files)

## Python Development

### Never Use System Python

macOS includes Python at `/usr/bin/python3` - **never use it**:
- Apple controls updates
- Can break system tools
- Often has SSL certificate issues

### Using pyenv

The setup script installs pyenv with Python 3.12:

```bash
# List available versions
pyenv install --list

# Install specific version
pyenv install 3.11.8

# Set global default
pyenv global 3.12

# Set local version for project
pyenv local 3.11.8

# Create virtual environment
pyenv virtualenv 3.12 my-project
pyenv activate my-project
```

### Common Issues

**SSL certificate errors**:
```bash
pip install --upgrade certifi
export SSL_CERT_FILE=$(python -c "import certifi; print(certifi.where())")
```

**tkinter missing**: tcl-tk is installed by the script before Python

## Node.js Development

### Using fnm

The setup script uses fnm (Fast Node Manager) instead of nvm for better Fish shell support:

```bash
# Install LTS
fnm install --lts

# Install specific version
fnm install 18.19.0

# Set default
fnm default lts-latest

# Use specific version
fnm use 18.19.0

# Auto-switch based on .node-version
# Already configured with --use-on-cd
```

### The Port 5000 Problem

AirPlay Receiver uses port 5000, conflicting with Flask and other dev servers.

**Solutions**:
1. Disable in System Settings → General → AirDrop & Handoff → Toggle off "AirPlay Receiver"
2. Use different port: `flask run --port 5001`
3. Check port usage: `lsof -i :5000`

## Remote Access Setup

The `macos_remote_access.sh` script sets up:

1. **Tailscale** - Creates a private VPN network for secure access
2. **NoMachine** - Provides remote desktop functionality

### Use Case: Control Mac from iPad

Perfect for working on your Mac while away from home.

**Setup Flow**:
1. Run `./macos_remote_access.sh` on Mac
2. Install Tailscale on iPad (same account)
3. Install NoMachine on iPad
4. Connect using Mac's Tailscale IP

**No port forwarding or public IP needed** - Tailscale creates a mesh VPN.

## Fish Shell (Optional)

Fish provides autocomplete and syntax highlighting out of the box, without configuration.

### When to Use Fish

- You want a modern, user-friendly shell experience
- You like autocomplete that "just works"
- You prefer abbreviations over aliases

### When to Keep Zsh

- You need POSIX compliance
- You run many bash scripts
- You want maximum compatibility

**Recommendation**: Install both. Use Fish as default, switch to Zsh when needed with `zsh` command.

### Fish Syntax Differences

| Operation | Bash/Zsh | Fish |
|-----------|----------|------|
| Set variable | `export VAR=value` | `set -gx VAR value` |
| Command substitution | `$(command)` | `(command)` |
| Aliases | `alias ll='ls -la'` | `abbr -a ll 'ls -la'` |
| Config file | `~/.zshrc` | `~/.config/fish/config.fish` |

## System Preferences

The script optionally configures:

- Show hidden files in Finder
- Show all file extensions
- Show path bar
- Enable key repeat (disable press-and-hold)
- Fast key repeat rate
- Disable AirPlay Receiver (frees port 5000)

## Troubleshooting

### Homebrew Issues

```bash
# Fix permissions
sudo chown -R $(whoami) /opt/homebrew  # Apple Silicon
sudo chown -R $(whoami) /usr/local     # Intel

# Update and cleanup
brew update
brew doctor
brew cleanup
```

### Command Not Found After Installation

```bash
# Reload shell configuration
source ~/.zshrc

# Check PATH
echo $PATH

# Verify Homebrew is in PATH
which brew
```

### Python SSL Issues

```bash
# Install certificates
pip install --upgrade certifi

# Use system certificates
export SSL_CERT_FILE=$(python -c "import certifi; print(certifi.where())")

# Add to ~/.zshrc for persistence
echo 'export SSL_CERT_FILE=$(python -c "import certifi; print(certifi.where())")' >> ~/.zshrc
```

### VS Code/Cursor: Can't Hold Key to Repeat

```bash
# VS Code
defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

# Cursor
defaults write com.todesktop.230313mzl4w4u92 ApplePressAndHoldEnabled -bool false

# Restart the app
```

### NoMachine Black Screen

1. System Settings → Privacy & Security
2. Grant permissions:
   - Screen Recording
   - Accessibility
   - Full Disk Access
3. Restart NoMachine

## App Equivalents

| Windows | macOS |
|---------|-------|
| Task Manager | **Activity Monitor** |
| Control Panel | **System Settings** |
| PowerShell/CMD | **Terminal** / iTerm2 |
| Notepad++ | VS Code, Sublime Text |
| WinRAR/7-Zip | The Unarchiver, Keka |
| Snipping Tool | **⇧⌘4** or **⇧⌘5** |
| PuTTY | Native SSH: `ssh user@host` |
| WSL | **Not needed** - macOS IS Unix |
| Explorer | **Finder** |
| Paint | Preview (basic editing) |

## Post-Setup Checklist

- [ ] Restart terminal or run `source ~/.zshrc`
- [ ] Configure p10k theme: `p10k configure`
- [ ] Set iTerm2 font to MesloLGS NF
- [ ] Grant permissions to installed apps in System Settings
- [ ] Add SSH key to GitHub/GitLab
- [ ] Configure Git user name and email
- [ ] Test Python with `python --version`
- [ ] Test Node.js with `node --version`
- [ ] Set up your preferred Neovim configuration
- [ ] Install VSCode extensions if using VS Code
- [ ] Configure Rectangle window management shortcuts
- [ ] Set up Raycast/Spotlight preferences

## Additional Resources

- [Homebrew Documentation](https://docs.brew.sh/)
- [Oh My Zsh](https://ohmyz.sh/)
- [Fish Shell](https://fishshell.com/)
- [pyenv GitHub](https://github.com/pyenv/pyenv)
- [fnm GitHub](https://github.com/Schniz/fnm)
- [Tailscale Docs](https://tailscale.com/kb/)
- [NoMachine Guides](https://www.nomachine.com/getting-started-with-nomachine)

## Script Overview

### macos_config.sh
Main bootstrap script that installs and configures:
- Homebrew and essential tools
- Terminal setup (iTerm2, Zsh, plugins)
- Development environments (Python, Node.js)
- Editors (VS Code, Cursor)
- Productivity tools
- System preferences
- SSH keys

### macos_remote_access.sh
Sets up remote access via Tailscale + NoMachine:
- Installs Tailscale VPN
- Installs NoMachine remote desktop
- Displays connection information
- Provides iPad setup instructions

### macos_fish_setup.sh
Optional Fish shell configuration:
- Installs Fish
- Creates configuration file
- Sets up abbreviations
- Integrates with pyenv, fnm, zoxide
- Optionally installs Fisher plugin manager

### macos_sibling_user_setup.sh
Multi-user environment setup script:
- Creates a second "sibling" user account (optional)
- Sets up shared group and directory structure
- Safely shares development tools and configs
- Copies SSH keys (never symlinks them)
- Uses macOS ACLs for fine-grained permissions
- Follows security best practices from Linux experience

## Multi-User Setup Guide

If you need to share your development environment between two macOS users (e.g., personal and work accounts, or collaborating with another developer), use the sibling user setup script.

### Quick Start

```bash
# Run as the primary user with sudo
sudo ./macos_sibling_user_setup.sh
```

### What It Does

1. **Creates Sibling User** (optional)
   - Creates a new macOS user account
   - Sets up home directory
   - Optionally grants admin privileges

2. **Shared Group & Directory**
   - Creates custom group: `devshared`
   - Adds both users to the group
   - Creates `/Users/Shared/dev` for shared projects
   - Sets up proper ACLs and permissions

3. **Shared Development Tools**
   - Shares `.local/bin`, `.local/lib`, `.local/share`
   - Tools installed by primary user become available to sibling
   - Uses symlinks with proper ACL protection

4. **Shared Configurations** (safe subset)
   - `.zshrc` - Shell configuration
   - `.oh-my-zsh` - Zsh framework
   - `.p10k.zsh` - Powerlevel10k theme
   - `.tmux` / `.tmux.conf` - Terminal multiplexer
   - Custom list configurable in script

5. **SSH Keys - Copied Safely**
   - **Never symlinks** `.ssh` directory
   - Copies all SSH keys with correct ownership
   - Sets strict permissions (700 for dir, 600 for keys)
   - Removes ACLs that interfere with SSH

### Safety Rules (Critical!)

#### ❌ NEVER Symlink:
- `.ssh` directory or files
- Entire `.local` directory
- Entire `.config` directory
- Keychain or credential files
- Any security-sensitive files

#### ✅ Safe to Symlink:
- Project folders in shared directory
- `.local/bin`, `.local/lib`, `.local/share` (with ACLs)
- Shell configs without secrets
- Development tool configs

#### ✅ Must Copy (Not Symlink):
- `.ssh` and all keys
- Credentials and API tokens
- Personal `.gitconfig` with email

### Usage Example

```bash
# 1. Run main setup on primary user
./macos_config.sh

# 2. Create and configure sibling user
sudo ./macos_sibling_user_setup.sh

# 3. Log in as sibling user
su - dpdev

# 4. Run development setup for sibling user
cd /Users/dp/ubuntu_config
./macos_config.sh

# 5. Verify everything works
ssh -T git@github.com
which python
which node
cd ~/shared_projects
```

### Customization

Edit the script variables at the top:

```bash
PRIMARY_USER="dp"              # Your main user
SIBLING_USER="dpdev"           # Second user name
SHARED_GROUP="devshared"       # Group name
SHARED_DIR="/Users/Shared/dev" # Shared directory

# Add/remove configs to share
CONFIGS_TO_LINK=(
  ".zshrc"
  ".oh-my-zsh"
  ".p10k.zsh"
  ".tmux.conf"
  # Add your own...
)
```

### Troubleshooting

**SSH "Bad owner or permissions" error**:
```bash
# Fix .ssh permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*
chmod 644 ~/.ssh/*.pub
```

**Can't access shared directory**:
```bash
# Check group membership
groups

# Re-login to activate group
exit
su - dpdev
```

**Primary user's tools not visible**:
```bash
# Check .local symlinks
ls -la ~/.local/bin ~/.local/lib ~/.local/share

# Verify ACLs
ls -led ~/.local/bin
```

**Permission denied on shared projects**:
```bash
# Check shared directory permissions
ls -led /Users/Shared/dev

# Verify group membership
dseditgroup -o checkmember -m dpdev devshared
```

### macOS-Specific Notes

1. **ACL Syntax**: macOS uses `chmod +a` instead of Linux `setfacl`
2. **User IDs**: Must be ≥501 (1-500 reserved for system)
3. **Default Group**: All users belong to `staff` (gid=20)
4. **Shared Location**: `/Users/Shared/` (not `/home/shared`)
5. **Shell**: Default is `zsh` (not bash)

## License

Same as parent repository.

## Contributing

Improvements and suggestions welcome via pull requests.
