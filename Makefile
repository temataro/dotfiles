# Packages to install

# Determines whether I apt, dnf, or pacman install packages
DISTRO_TYPE := $(shell 'ID_LIKE=' /etc/os-release | cut -d'=' -f2 | -d '"')

COMMON_PKGS=git vim ripgrep gnome-tweaks ninja-build cmake unzip curl arandr \
						octave golang-go alacritty vlc

DEBIAN_PKGS=
FEDORA_PKGS=
ARCH_PKGS=	


ifeq ($(DISTRO_TYPE),debian)
	cmd=sudo apt install -y
else ifeq ($(DISTRO_TYPE),fedora)
	cmd=sudo apt install -y
else ifeq ($(DISTRO_TYPE),arch)
	cmd=sudo apt install -y
endif

# TODO: Also get extra package managers like snap and yay
.PHONY: install_common update	upgrade

install_common $(COMMON_PKGS):
	$(cmd) $@

update:

upgrade:

keyboard_tweaks:
	# Make capslock a second ctrl key
	setxkbmap -option ctrl:nocaps

lazygit:
	LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
	curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
	tar xf lazygit.tar.gz lazygit
	sudo install lazygit /usr/local/bin && \

snap_installs:
	snap install spotify glow

tmux:

zsh:

git:

alacritty:

neovim:

i3:
# Install rofi (dmenu replacement)
	$(cmd) rofi
rust:

python:
	$(cmd) ipython3 python3 python3-pip black && \
	pip install -r requirements.txt

kitty:

init:
	git clone git@github.com:temataro/dotfiles.git ~/Code/dotfiles && \
	pushd ~/Code/dotfiles && \
	cp *.conf* *

arandr_screen_layout:
	cp ~/Code/dotfiles/xrandr ~/.screenlayout
	
fonts:
	wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/MartianMono.zip" && \
	wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"

symlink_dotfiles_to_config:
