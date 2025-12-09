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
brew tap homebrew/cask-fonts
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
read -p "Do you want to set up a Neovim configuration directory? (y/N): " choice
if [ "$choice" = "y" ]; then
  mkdir -p ~/.config/nvim
  echo "Neovim config directory created at ~/.config/nvim"
  echo "You can clone your preferred config there, for example:"
  echo "  git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim"
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
