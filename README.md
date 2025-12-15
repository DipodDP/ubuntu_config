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
./scripts/my_config.sh
```

To configure an SSH connection alias:
```bash
./scripts/ssh.sh
```

For WSL users, to fix DNS issues when using a VPN and to connect to the Windows host:
```bash
./scripts/wsl_DNS_fix.sh
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
chmod +x scripts/*.sh
```

To run the interactive setup:
```bash
./macos_config.sh
```
The script will prompt you for each major section to be installed.

**Silent Mode (unattended installation)**

To run the script in a non-interactive "silent mode" that installs essential development tools without prompts, use the `--silent` or `all` parameter:
```bash
./macos_config.sh --silent
```
or
```bash
./macos_config.sh all
```

In silent mode:
- **Essential tools are installed automatically**: Homebrew, CLI tools (git, wget, curl, ripgrep, fd, bat, eza, etc.), Zsh with Oh My Zsh, Tmux, Python with pyenv, Node.js with fnm, Rust with rustup, and OrbStack
- **Optional components are skipped**: Proxy configuration, Git user configuration, SSH key generation, code editors (VS Code, Cursor, Neovim), productivity tools (Rectangle, Raycast, Maccy), and macOS system preferences

Use silent mode for automated provisioning of new development machines. For full customization, run in interactive mode (default).

### Additional Scripts

-   `scripts/macos_fish_setup.sh`: Optional setup for the Fish shell.
-   `scripts/macos_remote_access.sh`: Optional setup for remote access using NoMachine and Tailscale.
-   `scripts/gemini_setup.sh`: Optional setup for the Gemini Account Switcher.
-   `scripts/editors_setup.sh`: Optional setup for VS Code, Cursor, and Neovim.
-   `scripts/git_setup.sh`: Optional setup for GIT and Lazygit.
-   `scripts/python_setup.sh`: Optional setup for Python with pyenv.
-   `scripts/node_setup.sh`: Optional setup for Node.js with fnm.
-   `scripts/rust_setup.sh`: Optional setup for Rust with rustup.
-   `scripts/orbstack_setup.sh`: Optional setup for OrbStack.
-   `scripts/productivity_tools_setup.sh`: Optional setup for productivity tools.
-   `scripts/zsh_setup.sh`: Optional setup for Zsh with Oh My Zsh, plugins, and aliases.
-   `scripts/tmux_setup.sh`: Optional setup for Tmux.
-   `scripts/proxy_setup.sh`: Optional setup for proxy configuration.
-   `scripts/ssh_setup.sh`: Optional setup for SSH key generation and remote server access.
-   `scripts/preferences/macos_preferences_setup.sh`: Optional setup for macOS system preferences.
-   `scripts/cli_tools_setup.sh`: Optional setup for essential CLI tools.

For more detailed information, including tips for developers new to macOS, see [README_MACOS.md](README_MACOS.md).
