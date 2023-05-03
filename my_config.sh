#!/bin/bash
cd
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
if ! grep -q -E -e "cls=|bat=|tree=" ~/.zshrc; then 
  echo "alias cls='clear'" | tee -a ~/.bash_aliases | tee -a ~/.zshrc
  echo "alias bat='batcat'" | tee -a ~/.bash_aliases | tee -a ~/.zshrc
  echo "alias tree='exa -lF --tree --icons'" | tee -a ~/.bash_aliases | tee -a ~/.zshrc
fi

# install utils
sudo apt install ripgrep -y
sudo apt install netcat -y
sudo apt install bat -y
sudo apt install lsof -y
sudo apt install htop -y
sudo apt install tmux -y
# sudo apt install tree -y
sudo apt install exa -y
sudo apt install fd-find -y

# install shell features
sudo apt install zsh -y
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
if ! grep -q 'eval "$(zoxide init zsh)"' ~/.zshrc; then 
  echo 'eval "$(zoxide init zsh)"' | tee -a ~/.zshrc
fi
# curl -sS https://starship.rs/install.sh | sh
# echo 'eval "$(starship init zsh)"' | tee -a ~/.zshrc
# mkdir -p ~/.config && touch ~/.config/starship.toml

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

# install compilers
sudo apt install make -y
sudo apt install gcc -y

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

# Install Tmux config
cd
git clone https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .

if ! grep -q "export EDITOR=" ~/.zshrc; then 
  echo "export EDITOR='nvim'" | tee -a ~/.bashrc | tee -a ~/.zshrc
fi

# Install Python 3.11 from a repository
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11 -y

#Install Node.js
curl -fsSL https://deb.nodesource.com/setup_19.x | sudo -E bash - &&\
sudo apt install -y nodejs

# Install LSP
sudo npm i -g pyright

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

# Optional: exposing nvim globally.
sudo mv squashfs-root /
sudo ln -s /squashfs-root/AppRun /usr/bin/nvim

# Optional: install nvim config
mkdir -p ~/.config/nvim
git clone https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
sudo mkdir -p /root/.config/
sudo ln -s ~/.config/nvim /root/.config/nvim

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

