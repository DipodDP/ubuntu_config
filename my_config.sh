#!/bin/bash

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

# Bash settings
echo "alias cls='clear'" | tee -a ~/.bash_aliases
echo "alias bat='batcat'" | tee -a ~/.bash_aliases

# install utils
sudo apt install ripgrep -y
sudo apt install netcat -y
sudo apt install bat -y
sudo apt install lsof -y
sudo apt install htop -y
sudo apt install tmux -y
sudo apt install tree -y
sudo apt install fd-find -y

# install compilers
sudo apt install make -y
sudo apt install gcc -y

# GIT config
read -p "What is your GIT email?: " git_email
git config --global user.email "$git_email"
read -p "What is your GIT name?: " git_name
git config --global user.email "$git_name"

#SSH key generation
ssh-keygen -t ed25519 -C "$git_email"

printf '\033]52;c;%s\007' "$(base64 < ~/.ssh/id_ed25519.pub)"
echo "SSH key for Github (already in you system buffer): "
cat ~/.ssh/id_ed25519.pub

# Install Tmux config
cd
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
echo "export EDITOR='nvim'" | tee -a ~/.bashrc

# Install nvim
curl -LO https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb
sudo apt install ./nvim-linux64.deb

# Install Python 3.11 from a repository
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11 -y

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

# Clean up
sudo apt autoremove -y
sudo apt autoclean

# SSH key generation
# ssh-keygen

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

