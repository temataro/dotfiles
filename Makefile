#              █████╗ ███████╗███████╗ █████╗ ██╗   ██╗
#             ██╔══██╗██╔════╝██╔════╝██╔══██╗██║   ██║
#             ███████║█████╗  ███████╗███████║██║   ██║
#             ██╔══██║██╔══╝  ╚════██║██╔══██║██║   ██║
#             ██║  ██║███████╗███████║██║  ██║╚██████╔╝
#             ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝
#
#              Automated Environment Setter And Upper
#
# Bring a fresh work or home PC up to my dev environment with minimal prompting.
#
# Getting started:
#   make basic       - common base packages, my personal defaults
#   make basic_plus  - + terminal, shell, fonts-friendly extras
#   make tem         - the full setup (packages + configs + fonts + tools)
#   make deploy      - just copy configs into ~ (no installs)
#   make refresh     - reverse of deploy: pull live configs back into this repo
#   make help        - list every target
#
# Individual pieces: make <neovim|tmux|kitty|zsh|zoxide|uv|lazygit|fonts|...>
# Configs are kept in sync with `make deploy` / `make refresh`, not symlinked.
#
# ! WARNING ! Installs run non-interactively (-y / --noconfirm). Know what you're
# installing before running the aggregate targets.

# === Distro / package-manager detection ===
# Probe for the actual package-manager binary instead of parsing /etc/os-release
# (Arch has no ID_LIKE; Ubuntu's is unquoted) so detection is reliable.
PKG := $(shell command -v apt >/dev/null 2>&1 && echo apt || (command -v pacman >/dev/null 2>&1 && echo pacman))

ifeq ($(PKG),apt)
  INSTALL     := sudo apt install -y
  UPDATE      := sudo apt update && sudo apt upgrade -y
  BUILD_TOOLS := build-essential ninja-build gettext gnome-tweaks
  fetcher     := fastfetch
  EXTRA       := bat eza chromium fastfetch
else ifeq ($(PKG),pacman)
  INSTALL     := sudo pacman -S --noconfirm --needed
  UPDATE      := sudo pacman -Syu --noconfirm
  BUILD_TOOLS := base-devel ninja gettext
  fetcher     := fastfetch
  EXTRA       := bat eza chromium fastfetch brightnessctl blueman
else
  $(error No supported package manager found - need apt or pacman)
endif

dotfiles_dir := $(CURDIR)
FONT_SRC     := $(dotfiles_dir)/extra/fonts
FONT_DEST    := $(HOME)/.local/share/fonts

# === Package sets ===
BASIC_COMMON = git vim ripgrep cmake unzip curl arandr cowsay btop vlc $(BUILD_TOOLS)
PLUS         = kitty tmux zsh octave $(fetcher)
TEM          = zoxide $(EXTRA)

# === Reusable status banner ===
# Usage: $(call status,Some message)   -- no commas in the message (call splits on them).
define status
	@printf '\n╔═══════════════════════════════════════════════════════════════╗\n  [STATUS] %s\n╚═══════════════════════════════════════════════════════════════╝\n\n' "$(1)"
endef

.PHONY: all help basic basic_plus tem deploy refresh fonts uv lazygit \
        zoxide zsh tmux kitty neovim update snaps wise_choice

all: basic

help:
	@echo "Targets:"
	@echo "  basic basic_plus tem    aggregate setups"
	@echo "  deploy refresh          configs <-> repo"
	@echo "  fonts uv lazygit zoxide  individual tools"
	@echo "  zsh tmux kitty neovim   individual app setup"
	@echo "  update snaps            system update / snap apps"
	@echo "Detected package manager: $(PKG)"

basic:
	$(call status,Installing common base packages)
	$(INSTALL) $(BASIC_COMMON)

basic_plus: basic
	$(call status,Installing terminal shell and fetcher extras)
	$(INSTALL) $(PLUS)

# The full ride. Order: packages -> configs -> fonts -> extra tools.
tem: wise_choice basic basic_plus deploy fonts uv zoxide tmux kitty
	$(call status,Installing the rest of my favourites)
	$(INSTALL) $(TEM)

update:
	$(call status,Updating system packages)
	$(UPDATE)

# === Deploy: repo -> live locations =========================================
deploy:
	$(call status,Deploying dotfiles into the home directory)
	cp $(dotfiles_dir)/.zshrc $(dotfiles_dir)/.tmux.conf $(dotfiles_dir)/.vimrc $(dotfiles_dir)/.gitconfig $(HOME)/
	mkdir -p $(HOME)/.config/kitty   && cp $(dotfiles_dir)/kitty.conf $(HOME)/.config/kitty/kitty.conf
	mkdir -p $(HOME)/.config/i3      && cp $(dotfiles_dir)/config $(HOME)/.config/i3/config
	mkdir -p $(HOME)/.config/nvim    && rsync -a --exclude='.git' $(dotfiles_dir)/nvim/ $(HOME)/.config/nvim/
	mkdir -p $(HOME)/.config/ghostty && rsync -a $(dotfiles_dir)/ghostty/ $(HOME)/.config/ghostty/

neovim: deploy

# === Refresh: live locations -> repo (reverse of deploy) ====================
# Guarded with '-' so a config that doesn't exist on this box doesn't abort it.
refresh:
	$(call status,Copying live configs back into this repo)
	-cp $(HOME)/.zshrc $(HOME)/.tmux.conf $(HOME)/.vimrc $(HOME)/.gitconfig $(dotfiles_dir)/
	-cp $(HOME)/.config/kitty/kitty.conf $(dotfiles_dir)/kitty.conf
	-cp $(HOME)/.config/i3/config $(dotfiles_dir)/config
	-rsync -a --exclude='.git' $(HOME)/.config/nvim/ $(dotfiles_dir)/nvim/
	-rsync -a $(HOME)/.config/ghostty/ $(dotfiles_dir)/ghostty/

# === Individual tools =======================================================
zoxide:
	$(call status,Installing zoxide)
	$(INSTALL) zoxide
	@echo "zoxide init is handled by .zshrc (guarded), nothing appended."

uv:
	$(call status,Installing uv)
	@command -v uv >/dev/null 2>&1 && echo "uv already installed." \
		|| curl -LsSf https://astral.sh/uv/install.sh | sh

lazygit:
	$(call status,Installing lazygit)
	@VERSION=$$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*') && \
		echo "lazygit version: $${VERSION}" && \
		curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v$${VERSION}/lazygit_$${VERSION}_Linux_x86_64.tar.gz" && \
		tar xf /tmp/lazygit.tar.gz -C /tmp lazygit && \
		sudo install /tmp/lazygit -D -t /usr/local/bin/ && \
		rm -f /tmp/lazygit /tmp/lazygit.tar.gz

zsh:
	$(call status,Installing zsh and oh-my-zsh)
	$(INSTALL) zsh
	chsh -s $$(which zsh)
	@if [ ! -d "$$HOME/.oh-my-zsh" ]; then \
		sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended; \
	else \
		echo "oh-my-zsh already installed, skipping."; \
	fi

tmux:
	$(call status,Installing tmux and its plugin manager)
	$(INSTALL) tmux
	@if [ ! -d "$$HOME/.tmux/plugins/tpm" ]; then \
		git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm; \
	else \
		echo "tpm already installed, skipping."; \
	fi

kitty:
	$(call status,Installing kitty and applying theme)
	$(INSTALL) kitty
	# NOTE: `kitty +kitten themes` is interactive; pick "Mayukai" from the list.
	-kitty +kitten themes Mayukai

snaps:
	$(call status,Installing snap apps)
	sudo snap install glow
	sudo snap install onefetch

fonts:
	$(call status,Downloading and installing nerd fonts)
	@mkdir -p $(FONT_SRC) $(FONT_DEST)
	wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/SpaceMono.zip"      -O $(FONT_SRC)/SpaceMono.zip
	wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip"  -O $(FONT_SRC)/JetBrainsMono.zip
	wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/MartianMono.zip"    -O $(FONT_SRC)/MartianMono.zip
	wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"       -O $(FONT_SRC)/FiraCode.zip
	wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/0xProto.zip"        -O $(FONT_SRC)/0xProto.zip
	wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Iosevka.zip"        -O $(FONT_SRC)/Iosevka.zip
	wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/MPlus.zip"          -O $(FONT_SRC)/MPlus.zip
	wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/ShareTechMono.zip"  -O $(FONT_SRC)/ShareTechMono.zip
	wget -q "https://www.ffonts.net/jsMath-cmr10.font.zip"                                        -O $(FONT_SRC)/cmr10.zip
	@for z in $(FONT_SRC)/*.zip; do unzip -o "$$z" -d "$(FONT_SRC)/$$(basename $$z .zip)" >/dev/null; done
	@test -d $(FONT_SRC)/marksfonts || git clone --depth 1 https://github.com/MarkGG8181/Clean-Fonts $(FONT_SRC)/marksfonts
	@find $(FONT_SRC) -type f \( -iname '*.ttf' -o -iname '*.otf' \) -exec cp -f {} $(FONT_DEST)/ \;
	fc-cache -f $(FONT_DEST)

wise_choice:
	@echo " \
	███████╗██╗  ██╗ ██████╗███████╗██╗     ██╗     ███████╗███╗   ██╗████████╗     ██████╗██╗  ██╗ ██████╗ ██╗ ██████╗███████╗██╗ \n \
	██╔════╝╚██╗██╔╝██╔════╝██╔════╝██║     ██║     ██╔════╝████╗  ██║╚══██╔══╝    ██╔════╝██║  ██║██╔═══██╗██║██╔════╝██╔════╝██║ \n \
	█████╗   ╚███╔╝ ██║     █████╗  ██║     ██║     █████╗  ██╔██╗ ██║   ██║       ██║     ███████║██║   ██║██║██║     █████╗  ██║ \n \
	██╔══╝   ██╔██╗ ██║     ██╔══╝  ██║     ██║     ██╔══╝  ██║╚██╗██║   ██║       ██║     ██╔══██║██║   ██║██║██║     ██╔══╝  ╚═╝ \n \
	███████╗██╔╝ ██╗╚██████╗███████╗███████╗███████╗███████╗██║ ╚████║   ██║       ╚██████╗██║  ██║╚██████╔╝██║╚██████╗███████╗██╗ \n \
	╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═══╝   ╚═╝        ╚═════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝ ╚═════╝╚══════╝╚═╝ \n \
	"
