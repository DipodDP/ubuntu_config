#!/bin/bash
set -e

echo "Fish Shell Setup for macOS"
echo "==========================="
echo ""

# Check if Homebrew is installed
if ! command -v brew &>/dev/null; then
  echo "Error: Homebrew is not installed. Please run macos_config.sh first."
  exit 1
fi

# Detect Homebrew prefix
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
  BREW_PREFIX="/opt/homebrew"
else
  BREW_PREFIX="/usr/local"
fi

# Install Fish
echo "Installing Fish shell..."
if ! command -v fish &>/dev/null; then
  brew install fish
  echo "Fish installed successfully"
else
  echo "Fish already installed"
fi

# Add Fish to allowed shells
FISH_PATH="$BREW_PREFIX/bin/fish"
if ! grep -q "$FISH_PATH" /etc/shells; then
  echo "Adding Fish to /etc/shells..."
  echo "$FISH_PATH" | sudo tee -a /etc/shells
fi

# Ask to change default shell
echo ""
read -p "Do you want to set Fish as your default shell? (y/N): " choice
if [ "$choice" = "y" ]; then
  chsh -s "$FISH_PATH"
  echo "Default shell changed to Fish"
  echo "Please log out and log back in for changes to take effect"
fi

# Create Fish config directory
mkdir -p ~/.config/fish

# Create Fish configuration file
echo ""
echo "Creating Fish configuration..."
cat > ~/.config/fish/config.fish <<'EOF'
# Disable greeting
set fish_greeting ""

# Homebrew PATH configuration
EOF

echo "eval \"($BREW_PREFIX/bin/brew shellenv)\"" >> ~/.config/fish/config.fish

cat >> ~/.config/fish/config.fish <<'EOF'

# Abbreviations (Fish's better aliases)
abbr -a cls 'clear'
abbr -a ll 'eza -lhHF --icons'
abbr -a la 'eza -alhHF --icons'
abbr -a ls 'eza -F --icons'
abbr -a tree 'eza -lF --tree --icons'

# Git abbreviations
abbr -a gs 'git status'
abbr -a ga 'git add'
abbr -a gc 'git commit'
abbr -a gp 'git push'
abbr -a gl 'git log'
abbr -a gd 'git diff'

# Editor
set -gx EDITOR nvim

# Session helper
function session
    sh ~/projects/tmux-sessions/$argv[1].sh
end

# Lazygit change directory integration
function lg
    set -lx LAZYGIT_NEW_DIR_FILE ~/.lazygit/newdir
    lazygit $argv

    if test -f $LAZYGIT_NEW_DIR_FILE
        cd (cat $LAZYGIT_NEW_DIR_FILE)
        rm -f $LAZYGIT_NEW_DIR_FILE
    end
end
EOF

# Setup pyenv if installed
if command -v pyenv &>/dev/null; then
  echo ""
  echo "Configuring pyenv for Fish..."
  cat >> ~/.config/fish/config.fish <<'EOF'

# pyenv configuration
set -Ux PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin
pyenv init - fish | source
pyenv virtualenv-init - fish | source
EOF
fi

# Setup fnm if installed
if command -v fnm &>/dev/null; then
  echo ""
  echo "Configuring fnm for Fish..."
  cat >> ~/.config/fish/config.fish <<'EOF'

# fnm configuration
fnm env --use-on-cd | source
EOF
fi

# Setup zoxide if installed
if command -v zoxide &>/dev/null; then
  echo ""
  echo "Configuring zoxide for Fish..."
  cat >> ~/.config/fish/config.fish <<'EOF'

# zoxide configuration
zoxide init fish | source
EOF
fi

# Install Fisher (Fish plugin manager) - optional
echo ""
read -p "Do you want to install Fisher (Fish plugin manager)? (y/N): " choice
if [ "$choice" = "y" ]; then
  fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
  echo "Fisher installed successfully"
  echo ""
  echo "Useful Fisher plugins you can install:"
  echo "  fisher install jorgebucaran/nvm.fish          # nvm alternative"
  echo "  fisher install PatrickF1/fzf.fish              # fzf integration"
  echo "  fisher install jethrokuan/z                    # z directory jumper"
fi

# Install Fish syntax highlighting and autosuggestions (built-in, just note)
echo ""
echo "==========================================="
echo "Fish Shell Setup Complete!"
echo "==========================================="
echo ""
echo "Fish comes with syntax highlighting and autosuggestions built-in!"
echo ""
echo "Configuration file: ~/.config/fish/config.fish"
echo ""
echo "To start using Fish:"
if [ "$choice" = "y" ]; then
  echo "  - Log out and log back in (default shell changed)"
else
  echo "  - Type 'fish' in your current terminal"
  echo "  - Or change default shell: chsh -s $FISH_PATH"
fi
echo ""
echo "Fish vs Bash/Zsh differences:"
echo "  - Variables: set -gx VAR value (not export VAR=value)"
echo "  - Command substitution: (command) (not \$(command))"
echo "  - Abbreviations: abbr (expands before execution)"
echo "  - Config: ~/.config/fish/config.fish (not ~/.zshrc)"
echo ""
echo "Tip: Keep Zsh available for POSIX-compliant scripts"
echo "     Just type 'zsh' to switch temporarily"
echo ""
