# Ubuntu dev config

Basic Ubuntu configuration script for Python development server

## Description

This is a shell script that performs several tasks related to system configuration and installation of useful utilities. The script performs the following tasks:

1. Creates an admin user (if requested) and updates the system.
2. Sets up some Bash aliases.
3. Installs various utilities like `ripgrep`, `netcat`, `bat`, `lsof`, `htop`, `tmux`, `lazygit`, `exe`, `fd-find` and other.
4. Installs compilers like `make` and `gcc`.
5. Configures GIT with user email and name, and sets up some aliases.
6. Generates an SSH key and adds it to the system buffer, and configures access to a remote server by SSH.
7. Installs Python 3.11 from a repository, Node.js, and LSP.
8. Installs `nvim` and sets up its configuration.
9. Cleans up the system.
10. Finally, it notifies the user that the installation is completed.

Note: The script provides some optional tasks: admin user creation and configuring alias for access to a remote server by SSH.

## Installation

Clone repository
```
git clone https://github.com/DipodDP/ubuntu_config.git && cd ubuntu_config/
```

Run script
```
./my_config.sh
```

If you need add alias for ssh connection to server run script
```
./ssh.sh
```

If you need to add DNS servers to correct work WSL via VPN and connect to Windows localhost from WSL with `winhost`, run script
```
./wsl_DNS_fix.sh
```
