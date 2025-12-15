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

# Python environment setup with pyenv
if [ "$SILENT_MODE" = "false" ]; then
  echo ""
  read -p "Do you want to set up Python with pyenv? (y/N): " choice_python
fi
if [ "$choice_python" = "y" ] || [ "$SILENT_MODE" = "true" ]; then
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

  echo "Installing Python 3.13..."
  pyenv install -s 3.13
  pyenv global 3.13

  echo "Python 3.13 installed and set as global version"

  # Configure Google Cloud SDK to use the pyenv Python
  PYENV_PYTHON_PATH=$(pyenv which python)
  if ! grep -q "CLOUDSDK_PYTHON" ~/.zshrc; then
      echo "" >> ~/.zshrc
      echo "# Set Python for Google Cloud SDK" >> ~/.zshrc
      echo "export CLOUDSDK_PYTHON=$PYENV_PYTHON_PATH" >> ~/.zshrc
  else
      sed -i.bak "s|export CLOUDSDK_PYTHON=.*|export CLOUDSDK_PYTHON=$PYENV_PYTHON_PATH|" ~/.zshrc
  fi
  echo "gcloud CLI configured to use Python 3.13."

  # Install pipx for CLI tools
  brew install pipx
  pipx ensurepath

  # Install uv (fast Python package installer)
  uv_choice="n"  # Initialize to prevent unbound variable error
  if [ "$SILENT_MODE" = "false" ]; then
    echo ""
    read -p "Do you want to install uv (fast Python package installer)? (y/N): " uv_choice
  fi
  if [ "$uv_choice" = "y" ] || [ "$SILENT_MODE" = "true" ]; then
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
