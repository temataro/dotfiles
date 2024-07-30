#!/usr/bin/env bash

# Temporary fix till i figure out how tf to ln -s files from here to my actual config directory
cp ./config ~/.config/i3/config
cp .zshrc .i3status.conf ~
cp ./alacritty.toml ~/.config/alacritty/alacritty.toml
rm -rf ~/.config/nvim
cp -r ./astro.nvim ~/.config/nvim
source ~/.zshrc
