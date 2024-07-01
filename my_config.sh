#!/bin/bash
cd

# Setting locale
sudo update-locale LANG=C.UTF-8

# Creating user
while true; do
read -p "Do you want to create admin users? (y/N): " choice

if [ "$choice" = "y" ]; then
  read -p "Enter user name: " user_name
  adduser $user_name
  usermod -aG sudo $user_name
fi
break

done

# Update the system
sudo apt update
sudo apt upgrade -y

# install utils
sudo apt install ripgrep -y
sudo apt install netcat-traditional -y
sudo apt install bat -y
sudo apt install lsof -y
sudo apt install htop -y
sudo apt install tmux -y
sudo apt install exa -y
sudo apt install fd-find -y
sudo apt install unzip -y

# install compilers
sudo apt install make -y
sudo apt install gcc -y
sudo apt install g++ -y

# install shell features
sudo apt install zsh -y
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k

cp .profile .zprofile

if ! grep -q ".local/bin" ~/.zprofile; then
  echo 'if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi' | tee -a ~/.zprofile
fi

if ! grep -q "usr/local/bin" ~/.zprofile; then
  echo 'if [ -d "/usr/local/bin" ] ; then
    PATH="/usr/local/bin:$PATH"
fi' | tee -a ~/.zprofile
fi

curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
if ! grep -q 'eval "$(zoxide init zsh)"' ~/.zshrc; then 
  echo 'eval "$(zoxide init zsh)"' | tee -a ~/.zshrc
fi

# curl -sS https://starship.rs/install.sh | sh
# echo 'eval "$(starship init zsh)"' | tee -a ~/.zshrc
# mkdir -p ~/.config && touch ~/.config/starship.toml

# Shell settings
if ! grep -q -E -e "cls=|bat=|tree=" ~/.zshrc; then 
  echo "alias cls='clear'" | tee -a ~/.bash_aliases | tee -a ~/.zshrc
  echo "alias bat='batcat'" | tee -a ~/.bash_aliases | tee -a ~/.zshrc
  echo "alias tree='exa -lF --tree --icons'" | tee -a ~/.bash_aliases | tee -a ~/.zshrc
  echo "alias ls='exa -F --icons'" | tee -a ~/.bash_aliases | tee -a ~/.zshrc
  echo "alias ll='exa -lFhH --icons'" | tee -a ~/.bash_aliases | tee -a ~/.zshrc
  echo "alias la='exa -alFhH --icons'" | tee -a ~/.bash_aliases | tee -a ~/.zshrc
fi

# Install Tmux config
cd
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .

if ! grep -q "set-clipboard|terminal-features" ~/.tmux.conf.local; then 
  echo # Settings for clipboard OSC 52 support
  echo "set -s set-clipboard on" | tee -a ~/.tmux.conf.local
  echo "set -as terminal-features ',$TERM'" | tee -a ~/.tmux.conf.local
fi

if ! grep -q "session()" ~/.zshrc; then 
  echo 'session() { sh ~/projects/tmux-sessions/$1.sh }' | tee -a ~/.bashrc | tee -a ~/.zshrc
fi

if ! grep -q "export EDITOR" ~/.zshrc; then 
  echo 'export EDITOR="nvim"' | tee -a ~/.bashrc | tee -a ~/.zshrc
fi

# Install fly.io CLI
curl -L https://fly.io/install.sh | sh
# For Microsoft WSL users
sudo ln -s /usr/bin/wslview /usr/local/bin/xdg-open

if ! grep -q "FLYCTL_INSTALL" ~/.zshrc; then 
  echo 'export FLYCTL_INSTALL="~/.fly"' | tee -a ~/.bashrc | tee -a ~/.zshrc
  echo 'export PATH="$FLYCTL_INSTALL/bin:$PATH"' | tee -a ~/.bashrc | tee -a ~/.zshrc
fi

# GIT config
while true; do
read -p "Do you want to configure GIT? (y/N): " choice

if [ "$choice" = "y" ]; then
  read -p "What is your GIT email?: " git_email
  git config --global user.email "$git_email"
  read -p "What is your GIT name?: " git_name
  git config --global user.name "$git_name"
  git config --global alias.st status
  git config --global alias.unstage 'reset HEAD --'
fi
break

done

# install Lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin

if ! grep -q "lg()" ~/.zshrc; then
  echo 'lg()
{
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    lazygit "$@"

    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
      cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
      rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}' | tee -a ~/.zshrc
fi

# Install Python 3.11 from a repository
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11 -y
sudo apt install python3.11-venv -y

# Install development tools for Python 3.11
sudo apt install python3.11-dev -y

# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -
mkdir ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/poetry
poetry completions zsh > ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/poetry/_poetry

#Install Node.js and pnpm
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - &&\
sudo apt-get install -y nodejs
sudo npm install -g pnpm

# Install LSP
# sudo npm i -g pyright

# Install from a download link
# wget download-link
# sudo dpkg -i downloaded-file-name.deb
# sudo apt install -f -y

# Install from source code
# git clone git-repository-link
# cd repository-folder
# ./configure
# make
# sudo make install

# Install nvim
sudo add-apt-repository universe
sudo apt install libfuse2 -y
curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage --appimage-extract
./squashfs-root/AppRun --version

# Exposing nvim globally.
sudo rm -r /squashfs-root/nvim
sudo mkdir /squashfs-root
sudo mv squashfs-root /squashfs-root/nvim
sudo ln -s /squashfs-root/nvim/AppRun /usr/bin/nvim

# Install nvim config
mkdir -p ~/.config/nvim
# git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
git clone --depth 1 https://github.com/AstroNvim/AstroNvim ~/.config/nvim
git clone https://github.com/DipodDP/astro_config.git ~/.config/nvim/lua/user
sudo mkdir -p /root/.config/
sudo ln -s ~/.config/nvim /root/.config/

# Clean up
sudo apt autoremove -y
sudo apt autoclean
rm nvim.appimage
rm -r squashfs-root
rm -r lazygit
rm lazygit.tar.gz

#SSH key generation
ssh-keygen -C "$git_email"

printf '\033]52;c;%s\007' "$(base64 < ~/.ssh/id_rsa.pub)"
echo "SSH key for Github (already in you system buffer): "
cat ~/.ssh/id_ed25519.pub

# Configure access to a remote server by SSH
while true; do
read -p "Do you want to configure remote access to a remote server by SSH? (y/N): " choice

if [ "$choice" = "y" ]; then
  read -p "Enter the remote server alias name: " server_name
  read -p "Enter the remote server IP address: " ip_address
  read -p "Enter the username for SSH access: " username
  read -p "Enter the SSH port (default is 22): " ssh_port

  # Configure SSH access
  ssh_config="Host $server_name\n"
  ssh_config+="\tHostName $ip_address\n"
  ssh_config+="\tUser $username\n"
  if [ ! -z "$ssh_port" ]; then
    ssh_config+="\tPort $ssh_port\n"
  fi

  # Add the SSH configuration to the SSH config file
  echo -e $ssh_config >> ~/.ssh/config
  ssh-copy-id $server_name
  echo "SSH access has been configured for remote server $ip_address"
else
  echo "SSH access configuration not requested. Exiting."
fi
break

done

echo "Installation completed!"
