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
alias grep='rg'
EOF
fi
