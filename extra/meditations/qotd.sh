#!/usr/bin/bash

files=( $HOME/dev/dotfiles/extra/meditations/verses/*.md)
random_file="${files[($RANDOM) % ${#files[@]}]}"

echo "$RANDOM"
echo "Meditations: $random_file"

/usr/bin/glow --pager "$random_file"

# Add this line to your .zshrc
# `$HOME/dev/dotfiles/extra/meditations/qotd.sh`
# to run a random quote everytime your terminal launches.
