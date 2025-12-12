#!/bin/bash
set -e
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
  xcode-select --install
  echo "Please complete the Xcode Command Line Tools installation in the dialog,"
  echo "then press Enter to continue..."
  read -r
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

# Proxy configuration
echo ""
read -p "Do you want to configure proxy settings? (y/N): " choice
if [ "$choice" = "y" ]; then
  echo ""
  echo "=== Proxy Configuration Options ==="
  echo ""
  echo "1. System Proxy Sync - Auto-sync with macOS system proxy settings"
  echo "2. v2rayA - Advanced proxy with shunt rules (selective routing)"
  echo "3. Both"
  echo "4. Skip"
  echo ""
  read -p "Enter choice [1-4]: " proxy_choice

  # Option 1 or 3: System Proxy Sync
  if [ "$proxy_choice" = "1" ] || [ "$proxy_choice" = "3" ]; then
    echo ""
    echo "=== System Proxy Sync Setup ==="
    echo ""
    echo "This will create a script that automatically syncs macOS system proxy"
    echo "settings to your terminal environment variables."
    echo ""

    # Create sync-proxy.sh script
    cat > ~/sync-proxy.sh <<'EOF'
#!/bin/bash

# Check if HTTP proxy is enabled in system settings
HTTP_ENABLE=$(scutil --proxy | grep "HTTPEnable" | awk '{print $3}')

if [[ "$HTTP_ENABLE" == "1" ]]; then
  # Get HTTP proxy host and port
  HTTP_HOST=$(scutil --proxy | grep "HTTPProxy" | awk '{print $3}')
  HTTP_PORT=$(scutil --proxy | grep "HTTPPort" | awk '{print $3}')

  if [[ -n "$HTTP_HOST" ]] && [[ -n "$HTTP_PORT" ]]; then
    export http_proxy="http://${HTTP_HOST}:${HTTP_PORT}"
    export https_proxy="http://${HTTP_HOST}:${HTTP_PORT}"
    echo "✓ Proxy enabled: ${HTTP_HOST}:${HTTP_PORT}"
  fi
else
  # Proxy disabled in system settings
  unset http_proxy
  unset https_proxy
  unset all_proxy
fi

# Check if SOCKS proxy is enabled
SOCKS_ENABLE=$(scutil --proxy | grep "SOCKSEnable" | awk '{print $3}')

if [[ "$SOCKS_ENABLE" == "1" ]]; then
  SOCKS_HOST=$(scutil --proxy | grep "SOCKSProxy" | awk '{print $3}')
  SOCKS_PORT=$(scutil --proxy | grep "SOCKSPort" | awk '{print $3}')

  if [[ -n "$SOCKS_HOST" ]] && [[ -n "$SOCKS_PORT" ]]; then
    export all_proxy="socks5://${SOCKS_HOST}:${SOCKS_PORT}"
    echo "✓ SOCKS proxy enabled: ${SOCKS_HOST}:${SOCKS_PORT}"
  fi
fi
EOF

    chmod +x ~/sync-proxy.sh
    echo "Created ~/sync-proxy.sh"

    # Add to .zshrc
    if ! grep -q "sync-proxy.sh" ~/.zshrc; then
      cat >> ~/.zshrc <<'EOF'

# Auto-sync macOS system proxy to terminal
source ~/sync-proxy.sh

# Alias to manually sync proxy settings
alias proxy-sync='source ~/sync-proxy.sh'
EOF
      echo "Added sync-proxy.sh to ~/.zshrc"
    fi

    echo ""
    echo "System proxy sync configured!"
    echo ""
    echo "Your terminal will now automatically use macOS system proxy settings."
    echo "Configure proxy: System Settings > Network > [Your Network] > Proxies"
    echo ""
    echo "Commands:"
    echo "  proxy-sync      - Manually sync proxy settings"
    echo "  proxy_status    - View current proxy settings"
    echo ""
  fi

  # Option 2 or 3: v2rayA
  if [ "$proxy_choice" = "2" ] || [ "$proxy_choice" = "3" ]; then
    echo ""
    echo "=== v2rayA Configuration with Shunt Rules ==="
    echo ""
    echo "v2rayA provides shunt rules for selective proxying:"
    echo ""
    echo "Port Comparison:"
    echo "  - Port 20171: Basic HTTP proxy (all traffic proxied)"
    echo "  - Port 20172: HTTP with shunt rules (selective routing)"
    echo ""
    echo "Shunt rules enable selective proxying based on:"
    echo "  - Domains (e.g., proxy only GitHub)"
    echo "  - Geosites (e.g., proxy only foreign sites)"
    echo "  - IP addresses"
    echo ""

    read -p "Do you want to install v2rayA? (y/N): " install_v2raya
    if [ "$install_v2raya" = "y" ]; then
      echo "Installing v2rayA..."
      brew install v2raya

      echo ""
      echo "v2rayA installed successfully!"
      echo ""
      echo "To start v2rayA:"
      echo "  brew services start v2raya"
      echo ""
      echo "Access web interface at: http://localhost:2017"
      echo ""

      read -p "Do you want to add v2rayA proxy functions to ~/.zshrc? (y/N): " add_v2ray_env
      if [ "$add_v2ray_env" = "y" ]; then
        if ! grep -q "v2rayA proxy" ~/.zshrc; then
          cat >> ~/.zshrc <<'EOF'

# v2rayA proxy configuration (with shunt rules on port 20172)
# Functions to enable/disable v2rayA proxy
v2ray_proxy_on() {
  export http_proxy=http://127.0.0.1:20172
  export https_proxy=http://127.0.0.1:20172
  export all_proxy=socks5://127.0.0.1:20170
  echo "✓ v2rayA proxy enabled (with shunt rules)"
}

v2ray_proxy_off() {
  unset http_proxy
  unset https_proxy
  unset all_proxy
  echo "✓ v2rayA proxy disabled"
}

# Alias for basic proxy without shunt rules
v2ray_proxy_basic() {
  export http_proxy=http://127.0.0.1:20171
  export https_proxy=http://127.0.0.1:20171
  export all_proxy=socks5://127.0.0.1:20170
  echo "✓ v2rayA basic proxy enabled (no shunt rules)"
}
EOF
          echo "v2rayA proxy functions added to ~/.zshrc"
          echo ""
          echo "Commands:"
          echo "  v2ray_proxy_on    - Enable v2rayA with shunt rules (port 20172)"
          echo "  v2ray_proxy_basic - Enable v2rayA without shunt rules (port 20171)"
          echo "  v2ray_proxy_off   - Disable v2rayA proxy"
        fi
      fi
    else
      echo "Skipping v2rayA installation"
      echo "You can install it later with: brew install v2raya"
    fi
  fi

  # Add general proxy status function if not already present
  if ! grep -q "proxy_status()" ~/.zshrc; then
    cat >> ~/.zshrc <<'EOF'

# Check current proxy settings
proxy_status() {
  echo "=== Current Proxy Settings ==="
  echo ""
  echo "Terminal environment variables:"
  echo "  http_proxy:  ${http_proxy:-<not set>}"
  echo "  https_proxy: ${https_proxy:-<not set>}"
  echo "  all_proxy:   ${all_proxy:-<not set>}"
  echo ""
  echo "macOS system proxy (scutil --proxy):"
  scutil --proxy | grep -E "HTTPEnable|HTTPProxy|HTTPPort|HTTPSEnable|HTTPSProxy|HTTPSPort|SOCKSEnable|SOCKSProxy|SOCKSPort"
}
EOF
    echo "Added proxy_status function to ~/.zshrc"
  fi
fi

# Install essential CLI tools
echo ""
echo "Installing essential CLI tools..."
brew install git wget curl tree jq ripgrep fd bat eza htop tldr neovim

# Install GNU utilities for better compatibility
brew install coreutils findutils gnu-sed gnu-tar grep

# Install development utilities
brew install tmux unzip gpg

# Install build tools
brew install make gcc

# Install iTerm2
echo ""
read -p "Do you want to install iTerm2? (y/N): " choice
if [ "$choice" = "y" ]; then
  brew install --cask iterm2
  echo "iTerm2 installed. You can configure it later from:"
  echo "  Settings → Profiles → Text → Font → MesloLGS NF"
fi

# Install Nerd Font
echo ""
echo "Installing MesloLGS Nerd Font..."
brew install --cask font-meslo-lg-nerd-font

# Setup Zsh with Oh My Zsh
echo ""
echo "Setting up Zsh with Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "Oh My Zsh already installed"
fi

# Install Zsh plugins
echo "Installing Zsh plugins..."
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
fi

# Update .zshrc with plugins
if ! grep -q "zsh-autosuggestions" ~/.zshrc; then
  sed -i.bak 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker npm)/' ~/.zshrc
fi

# Update theme to powerlevel10k
if ! grep -q "powerlevel10k" ~/.zshrc; then
  sed -i.bak 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
fi

# Install zoxide
echo ""
echo "Installing zoxide..."
brew install zoxide
if ! grep -q 'eval "$(zoxide init zsh)"' ~/.zshrc; then
  echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
fi

# Shell aliases
echo ""
echo "Setting up shell aliases..."
if ! grep -q -E "bat=|tree=|ls=|ll=|la=" ~/.zshrc; then
  cat >> ~/.zshrc <<'EOF'

# Aliases
alias cls='clear'
alias tree='eza -lF --tree --icons'
alias ls='eza -F --icons'
alias ll='eza -lhHF --icons'
alias la='eza -alhHF --icons'
EOF
fi

# Install Tmux config
echo ""
echo "Installing Tmux configuration..."
if [ ! -d "$HOME/.tmux" ]; then
  git clone https://github.com/gpakosz/.tmux.git ~/.tmux
  ln -s -f ~/.tmux/.tmux.conf ~/.tmux.conf
  cp ~/.tmux/.tmux.conf.local ~/.tmux.conf.local
fi

if ! grep -q "set-clipboard\|terminal-features" ~/.tmux.conf.local; then
  cat >> ~/.tmux.conf.local <<'EOF'

# Settings for clipboard OSC 52 support
set -s set-clipboard on
set -as terminal-features ',$TERM'
EOF
fi

if ! grep -q "session()" ~/.zshrc; then
  echo 'session() { sh ~/projects/tmux-sessions/$1.sh }' >> ~/.zshrc
fi

if ! grep -q "export EDITOR" ~/.zshrc; then
  echo 'export EDITOR="nvim"' >> ~/.zshrc
fi

# Python environment setup with pyenv
echo ""
read -p "Do you want to set up Python with pyenv? (y/N): " choice
if [ "$choice" = "y" ]; then
  echo "Installing pyenv and dependencies..."
  brew install pyenv pyenv-virtualenv
  brew install openssl readline sqlite3 xz zlib tcl-tk

  # Add pyenv to shell
  if ! grep -q "PYENV_ROOT" ~/.zshrc; then
    cat >> ~/.zshrc <<'EOF'

# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"
eval "$(pyenv virtualenv-init -)"
EOF
  fi

  # Activate pyenv for current session
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"

  echo "Installing Python 3.12..."
  pyenv install 3.12 || echo "Python 3.12 already installed"
  pyenv global 3.12

  echo "Python 3.12 installed and set as global version"

  # Install pipx for CLI tools
  brew install pipx
  pipx ensurepath

  # Install uv (fast Python package installer)
  echo ""
  read -p "Do you want to install uv (fast Python package installer)? (y/N): " uv_choice
  if [ "$uv_choice" = "y" ]; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Source uv env for current session
    if [ -f "$HOME/.cargo/env" ]; then
      source "$HOME/.cargo/env"
    fi

    echo "uv installed successfully"
    echo ""
    echo "uv is a fast Python package installer and resolver."
    echo "Usage examples:"
    echo "  uv pip install package_name  # Install a package"
    echo "  uv pip list                   # List installed packages"
    echo "  uv venv                       # Create a virtual environment"
    echo ""
    echo "Learn more: https://github.com/astral-sh/uv"
  fi
fi

# Node.js environment setup with fnm
echo ""
read -p "Do you want to set up Node.js with fnm? (y/N): " choice
if [ "$choice" = "y" ]; then
  echo "Installing fnm (Fast Node Manager)..."
  brew install fnm

  # Add fnm to shell
  if ! grep -q "fnm env" ~/.zshrc; then
    cat >> ~/.zshrc <<'EOF'

# fnm configuration
eval "$(fnm env --use-on-cd)"
EOF
  fi

  # Activate fnm for current session
  eval "$(fnm env --use-on-cd)"

  echo "Installing Node.js LTS..."
  fnm install --lts
  fnm default lts-latest

  echo "Installing global npm packages..."
  npm install -g npm@latest pnpm
fi

# Rust environment setup with rustup
echo ""
read -p "Do you want to set up Rust with rustup? (y/N): " choice
if [ "$choice" = "y" ]; then
  echo "Installing Rust with rustup..."

  if ! command -v rustc &>/dev/null; then
    # Install rustup
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    # Source cargo env for current session
    source "$HOME/.cargo/env"

    # Add to .zshrc if not already present
    if ! grep -q ".cargo/env" ~/.zshrc; then
      echo 'source "$HOME/.cargo/env"' >> ~/.zshrc
    fi

    echo "Rust installed successfully"
  else
    echo "Rust already installed"
  fi

  # Show version
  rustc --version
  cargo --version
fi

# GIT configuration
echo ""
read -p "Do you want to configure Git? (y/N): " choice
if [ "$choice" = "y" ]; then
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

# Development tools
echo ""
read -p "Do you want to install VS Code? (y/N): " choice
if [ "$choice" = "y" ]; then
  brew install --cask visual-studio-code

  # Enable key repeat for Vim mode
  defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false

  echo "VS Code installed. Run 'code' command after sourcing ~/.zshrc"
fi

echo ""
read -p "Do you want to install Cursor? (y/N): " choice
if [ "$choice" = "y" ]; then
  brew install --cask cursor

  # Enable key repeat for Vim mode
  defaults write com.todesktop.230313mzl4w4u92 ApplePressAndHoldEnabled -bool false

  echo "Cursor installed"
fi

# Productivity tools
echo ""
read -p "Do you want to install productivity tools? (Rectangle, Raycast, Maccy, Karabiner-Elements) (y/N): " choice
if [ "$choice" = "y" ]; then
  echo "Installing productivity tools..."
  brew install --cask rectangle        # Window management
  brew install --cask raycast          # Spotlight replacement
  brew install --cask maccy            # Clipboard manager
  brew install --cask karabiner-elements  # Keyboard customization
  brew install --cask appcleaner       # App uninstaller

  echo "Productivity tools installed"
  echo "  - Rectangle: Window management (⌃⌥ + arrows)"
  echo "  - Raycast: Press ⌥Space to launch"
  echo "  - Maccy: Clipboard history (⇧⌘C)"
  echo "  - Karabiner-Elements: Keyboard remapping"
  echo "  - AppCleaner: Clean app uninstall"
fi

# macOS system preferences
echo ""
read -p "Do you want to configure macOS system preferences for development? (y/N): " choice
if [ "$choice" = "y" ]; then
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

# SSH key generation
echo ""
read -p "Do you want to generate an SSH key? (y/N): " choice
if [ "$choice" = "y" ]; then
  if [ -n "$git_email" ]; then
    ssh-keygen -t ed25519 -C "$git_email"
  else
    read -p "Enter your email for SSH key: " ssh_email
    ssh-keygen -t ed25519 -C "$ssh_email"
  fi

  # Add to SSH agent
  eval "$(ssh-agent -s)"

  # Create SSH config for macOS keychain
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  if [ ! -f ~/.ssh/config ]; then
    cat > ~/.ssh/config <<'EOF'
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
    chmod 600 ~/.ssh/config
  fi

  ssh-add --apple-use-keychain ~/.ssh/id_ed25519

  echo ""
  echo "SSH key for GitHub (copied to clipboard):"
  pbcopy < ~/.ssh/id_ed25519.pub
  cat ~/.ssh/id_ed25519.pub
  echo ""
  echo "The SSH public key has been copied to your clipboard."
  echo "Add it to GitHub: https://github.com/settings/keys"
fi

# Configure SSH access to remote server
echo ""
read -p "Do you want to configure SSH access to a remote server? (y/N): " choice
if [ "$choice" = "y" ]; then
  read -p "Enter the remote server alias name: " server_name
  read -p "Enter the remote server IP address: " ip_address
  read -p "Enter the username for SSH access: " username
  read -p "Enter the SSH port (default is 22): " ssh_port

  # Ensure SSH config directory exists
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  touch ~/.ssh/config
  chmod 600 ~/.ssh/config

  # Configure SSH access
  cat >> ~/.ssh/config <<EOF

Host $server_name
	HostName $ip_address
	User $username
EOF

  if [ -n "$ssh_port" ]; then
    echo "	Port $ssh_port" >> ~/.ssh/config
  fi

  # Copy SSH key to server
  ssh-copy-id "$server_name"
  echo "SSH access has been configured for remote server $ip_address"
fi

# Install Neovim config (optional)
echo ""
read -p "Do you want to set up a Neovim configuration? (y/N): " choice
if [ "$choice" = "y" ]; then
  echo ""
  echo "Choose Neovim configuration:"
  echo "  1. nvscode (VSCode/Cursor compatible)"
  echo "  2. Empty directory (manual setup)"
  echo "  3. Skip"
  read -p "Enter choice [1-3]: " nvim_choice

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
      git clone https://github.com/DipodDP/nvscode.git ~/.config/nvim

      echo "nvscode configuration installed at ~/.config/nvim"
      echo ""
      echo "Setting up symlinks to VSCode/Cursor settings..."

      # Create VSCode/Cursor config directories if they don't exist
      mkdir -p ~/Library/Application\ Support/Code/User
      mkdir -p ~/Library/Application\ Support/Cursor/User

      # Check if nvscode has settings to symlink
      if [ -f ~/.config/nvim/vscode/settings.json ]; then
        # Backup existing VSCode settings
        if [ -f ~/Library/Application\ Support/Code/User/settings.json ] && [ ! -L ~/Library/Application\ Support/Code/User/settings.json ]; then
          cp ~/Library/Application\ Support/Code/User/settings.json ~/Library/Application\ Support/Code/User/settings.json.backup.$(date +%s)
        fi

        # Create symlink for VSCode
        ln -sf ~/.config/nvim/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
        echo "Created symlink: VSCode settings -> ~/.config/nvim/vscode/settings.json"

        # Backup existing Cursor settings
        if [ -f ~/Library/Application\ Support/Cursor/User/settings.json ] && [ ! -L ~/Library/Application\ Support/Cursor/User/settings.json ]; then
          cp ~/Library/Application\ Support/Cursor/User/settings.json ~/Library/Application\ Support/Cursor/User/settings.json.backup.$(date +%s)
        fi

        # Create symlink for Cursor
        ln -sf ~/.config/nvim/vscode/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
        echo "Created symlink: Cursor settings -> ~/.config/nvim/vscode/settings.json"
      fi

      if [ -f ~/.config/nvim/vscode/keybindings.json ]; then
        # Create symlinks for keybindings
        ln -sf ~/.config/nvim/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
        ln -sf ~/.config/nvim/vscode/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json
        echo "Created symlinks for keybindings"
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

echo ""
echo "============================================"
echo "macOS Development Environment Setup Complete!"
echo "============================================"
echo ""
echo "Important next steps:"
echo "1. Restart your terminal or run: source ~/.zshrc"
echo "2. Configure p10k theme: p10k configure"
echo "3. If you installed iTerm2, configure the font:"
echo "   Settings → Profiles → Text → Font → MesloLGS NF"
echo "4. Grant necessary permissions to apps in System Settings"
echo ""
echo "Optional:"
echo "- Run macos_fish_setup.sh for Fish shell configuration"
echo "- Run macos_remote_access.sh for NoMachine + Tailscale setup"
echo ""
