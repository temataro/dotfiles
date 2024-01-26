#!/usr/bin/bash
# Instructions:
# Each command has been structured into (hopefully) logical sections that work
# independently of eachother (apart from dependencies that I have attempted to
# put around the top). Comment out the sections you don't want to install.
# Happy travels!

sudo apt update -y && sudo apt upgrade -y && \
sudo apt install -y git vim build-essential gnome-tweaks ninja-build gettext cmake unzip curl && \

# Install Python3
sudo apt install -y python3 python3-pip ipython3 black
# Install 3rd party Python modules
pip install -r requirements.txt

# Install graphical monitor brightness controller
sudo add-apt-repository ppa:apandada1/brightness-controller -y && \
sudo apt install brightness-controller -y && \

# Install Rust
sudo apt install -y curl && \
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh && \

# Install Octave
sudo apt install -y octave && \

# Copy all dotfiles into ~ or their respective config documents
# ZSH, TMUX, Git, Vim, kitty
git clone https://github.com/temataro/dotfiles ~/Code/dotfiles && cd ~/Code/dotfiles && \
cp ./extra/fonts/jet-brains-mono ./extra/fonts/sf-mono-cufonfonts ~/.local/share/fonts && \
cp ./kitty.conf ~/.config/kitty/ && \
cp ./.tmux.conf ./.vimrc ./extra/.vim ./.gitconfig ./.zshrc ~ && \

# Install Zsh with oh-my-zsh and make it default shell
sudo apt install -y zsh && chsh -s $(which zsh) && \
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \

# Install tmux, kitty, and Konsole
sudo apt install -y kitty tmux && \
kitty +kitten themes Mayukai && \  # Set theme for Kitty.
tmux source ~/.tmux.conf && \
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && \  # Install Tmux Plugin Manager (TPM)

# Install other apps (Spotify, Microsoft Edge, ... VS Code)
sudo snap install spotify glow && \

# Install Lazygit
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin && \

# Install misc
sudo apt install fastfetch btop vlc dictd && \  # Fastfetch, VLC, process manager btop, terminal dictionary
sudo apt install golang-go && git clone git@github.com:BetaPictoris/wiki.git ~/Code/wiki && \
cd ~/Code/wiki && make && sudo make install && \

