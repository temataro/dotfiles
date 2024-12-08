# NOTE: THIS IS STILL IN DEVELOPMENT. IT WILL SURELY FAIL ON YOUR SYSTEM. DO
# NOT USE!!! (Unless you wanna, idk)
# Makefile Build Environment Functionality:
# 	- Specify between a lite build or a normal build by using `make lite` for
# 	small systems like SBCs or computers you won't use regularly.
# 	-
# ! WARNING !
# The commands here will have yes piped into them for minimal user
# intervention, beware of what you're installing!
#
# 																		Happy travels, Space Cowboy.

# Packages to install
# Determines whether I apt, dnf, or pacman install packages
DISTRO_TYPE := $(shell cat /etc/os-release | grep ID_LIKE | cut -d'=' -f2)

ifeq ($(DISTRO_TYPE),debian)
	cmd=sudo apt install -y
	update=yes | sudo apt update && sudo apt upgrade
	fetcher=neofetch  # Yes, yes, yes neofetch discontinued wah wah
	extra_pkg_mngr=sudo apt install snapd && sudo snap install core  # Test this works...

else ifeq ($(DISTRO_TYPE),fedora)
	cmd=yes | sudo dnf install
	update=yes | sudo dnf update && sudo dnf upgrade
	fetcher=fastfetch
	extra_pkg_mngr=echo "nah"

else ifeq ($(DISTRO_TYPE),arch)
	cmd=yes | sudo pacman -S
	upgrade=yes | sudo pacman -Syu
	fetcher=fastfetch
	extra_pkg_mngr= pacman -S --needed git base-devel && pushd ~/dev/ && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && popd

endif

COMMON_PKGS          = git vim ripgrep ninja-build cmake \
								     	unzip curl arandr cowsay btop alacritty \
								     	bat

COMMON_PKGS_LITE     = git vim ripgrep ninja-build cmake \
								     	unzip curl btop

COMMON_APPLICATIONS  = chromium spotify

DEBIAN_PKGS   = gnome-tweaks glow neofetch
FEDORA_PKGS   = fastfetch
ARCH_PKGS     = glow fastfetch
config_dir    = "$(HOME)/.config"
dotfiles_dir ?= "$(HOME)/code/github.com/temataro/dotfiles"

.PHONY: init whoisthis install_common upgrade symlink_dotfiles_to_config lazygit tmux zsh alacritty vim neovim i3 python

install_common:
	$(cmd) $(COMMON_PKGS)
	$(cmd) $(COMMON_APPLICATIONS)

lite:
	$(cmd) $(COMMON_PKGS_LITE)

upgrade:
	$(upgrade)

install_extra_pkg_manager:
	$(extra_pkg_mngr)

init:
	git clone git@github.com:temataro/dotfiles.git ~/dev/dotfiles && \
	pushd ~/dev/dotfiles

keyboard_tweaks:
	# Make capslock a second ctrl key
	# TODO: Make and run a script to do this at runtime instead of depending on
	# i3's exec_always functionality to execute commands at startup.
	setxkbmap -option ctrl:nocaps

lazygit:
	LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
	curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
	tar xf lazygit.tar.gz lazygit
	sudo install lazygit /usr/local/bin

tmux:
	$(cmd) lm-sensors nvidia-smi
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
	# Changes the way the tmux-ip-address plugin gets its IP.
	sed -i '8s/.*/  local ip_address=$(hostname -I)/' ~/.tmux/plugins/tmux-ip-address/scripts/ip_address.sh
	$(cmd) tmux
	# symlinking dotfile in a later recipe

zsh:
	$(cmd) zsh
	chsh --shell "$(which zsh)"
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

alacritty:
	$(cmd) alacritty
	# symlinking dotfile in a later recipe

vim:
	cp -r ./.vim/ $(HOME)
	# symlinking dotfile in a later recipe

neovim:
	$(cmd) neovim
	cp -r neovim $(config_dir)/nvim

i3:
	$(cmd) i3
	# Install rofi (dmenu replacement)
	$(cmd) rofi
	# Install picom (Compositor to manage transparency, animations, etc)
	$(cmd) picom
	# symlinking dotfile in a later recipe

rust:
	curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh

python:
	$(cmd) ipython \
				 python3 \
				 python3-pip \
				 black \
				 python3.12-venv \
				 pip install -r requirements.txt

octave:
	$(cmd) octave

go:
	$(cmd) golang-go

kitty:
	$(cmd) kitty
	kitty +kitten themes Mayukai  # Set theme for Kitty.

arandr_screen_layout:
	cp ~/dev/dotfiles/xrandr ~/.screenlayout


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
	sudo mv ./extra/fonts/* /usr/share/fonts

sync:
	# Temporary fix till i figure out how tf to ln -s files from here to my actual config directory
	cp ./config ~/.config/i3/config
	cp ./.vimrc ~/.vimrc
	cp ./kitty.conf ~/.config/kitty/kitty.conf
	cp .tmux.conf .zshrc .i3status.conf ~
	cp ./alacritty.toml ~/.config/alacritty/alacritty.toml
	rm -rf ~/.config/nvim ~/local/share/nvim
	cp -r ./astro.nvim ~/.config/nvim
	echo "Run source ~/.zshrc to reload zsh without closing your terminal"

symlink_dotfiles_to_config:
	ln ./alacritty.toml $(config_dir)/alacritty/alacritty.toml
	ln ./config $(config_dir)/i3/config
	ln ./.tmux.conf $(config_dir)/.tmux.conf
	ln ./.vimrc $(HOME)/.vimrc
	ln ./kitty.conf $(config_dir)/kitty/.kitty.conf
	ln ./ipython_config.py ~/.ipython/profile_default/ipython_config.py

whoisthis:
	$(fetcher)
	cowsay -f dragon-and-cow $(DISTRO_TYPE)
	$(cmd) cpufetch
