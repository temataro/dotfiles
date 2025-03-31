#              █████╗ ███████╗███████╗ █████╗ ██╗   ██╗
#             ██╔══██╗██╔════╝██╔════╝██╔══██╗██║   ██║
#             ███████║█████╗  ███████╗███████║██║   ██║
#             ██╔══██║██╔══╝  ╚════██║██╔══██║██║   ██║
#             ██║  ██║███████╗███████║██║  ██║╚██████╔╝
#             ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝
#
#              Automated Environment Setter And Upper

# An automated way to get back up and running on a new systemas fast as
# possible (minus all the time it took to make this stupid thing not break)


# Getting started:
# For a barebones setup with my personal defaults, simply run `make basic`
# Imposing a few more liberal choices, I'd go for `make basic_plus`
# For a full on setup that my coworkers will judge me for, run `make full`
#
# Each individual config'd package can be setup with `make <pkg>`
# (neovim, tmux, kitty, vim, alacritty, i3, zsh)
# config files aren't managed by GNU Stow or symlinked places, but rather
# kept in sync using `make sync`... I'm currently (12/14/2024) unconvinced
# of the benefits of moving towards them.
#
# ! WARNING !
# The commands here will have yes piped into them for minimal user
# intervention, beware of what you're installing!

# Check your directory and see what package manager to use
DISTRO_TYPE := $(shell cat /etc/os-release | grep ID_LIKE | cut -d'=' -f2)

cmd = 'arch'
fetcher = 'fastfetch'
dotfiles_dir = '/home/tem/code/github.com/temataro/dotfiles'

ifeq ($(DISTRO_TYPE),"debian")
	cmd := 'sudo apt install -y'
	update_cmd := 'yes | sudo apt update && sudo apt upgrade'
	fetcher := 'neofetch'
	distro_specific := 'gnome-tweaks build-essential'

else ifeq ($(DISTRO_TYPE),"fedora")
	cmd := 'yes | sudo dnf install'
	update_cmd := 'yes | sudo dnf update && sudo dnf upgrade'
	distro_specific := 'cowsay'  # idk what distro specific thing to use w/ dnf

else ifeq ($(DISTRO_TYPE),"arch")
	cmd := yes | sudo pacman -S
	update_cmd := 'yes | sudo pacman -Syu'
	distro_specific := 'bat brightnessctl blueman '
endif


# === __ === Packages === __ ===
BASIC_COMMON       = 'git vim ripgrep cmake unzip curl arandr cowsay btop'
PLUS               = 'kitty tmux neovim $(fetcher)'
TEM                = '$(fetcher) spotify chromium'

all: basic

basic:
	@echo "empty for now..."
# `make basic_plus`
# Congratulations, you also get some nice fonts and a terminal that looks nice
basic_plus:

tmux:
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	# Changes the way the tmux-ip-address plugin gets its IP.
	sed -i '8s/.*/  local ip_address=$(hostname -I)/' ~/.tmux/plugins/tmux-ip-address/scripts/ip_address.sh
	cp .tmux.conf ~

refresh:
	@echo "Copying back your computers config to this repository"
	cp ~/.config/kitty/kitty.conf .
	cp ~/.config/i3/config .
	cp ~/.tmux.conf .
	cp ~/.vimrc .
	cp ~/.zshrc .

fonts:
	cd $(dotfiles_dir)
	mkdir -p extra/fonts
	wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/SpaceMono.zip" -O ./extra/fonts/SpaceMono.zip
	wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" -O ./extra/fonts/JetBrainsMono.zip
	wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/MartianMono.zip" -O ./extra/fonts/MartianMono.zip
	wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip" -O ./extra/fonts/FiraCode.zip
	wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/0xProto.zip" -O ./extra/fonts/0xProto.zip
	wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Iosevka.zip" -O ./extra/fonts/Iosevka.zip
	yes | unzip extra/fonts/SpaceMono.zip -d extra/fonts/SpaceMono
	yes | unzip extra/fonts/JetBrainsMono.zip -d extra/fonts/JetBrainsMono
	yes | unzip extra/fonts/MartianMono.zip -d extra/fonts/MartianMono
	yes | unzip extra/fonts/FiraCode.zip -d extra/fonts/FiraCode
	yes | unzip extra/fonts/0xProto.zip -d extra/fonts/0xProto
	yes | unzip extra/fonts/Iosevka.zip -d extra/fonts/Iosevka
	git clone https://github.com/MarkGG8181/Clean-Fonts extra/fonts
	sudo mv ./extra/fonts/* /usr/share/fonts
