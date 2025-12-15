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
