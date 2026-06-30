# Post-laptop-transition todo

- [x] fix the Makefile's weird issue with symlinks
      → root cause was a dangling nix-store symlink (home dir rsync'd from a nix
        box); cleaned up the orphaned symlinks, kitty.conf is a real file now.
- [x] rehaul tmux look → hand-rolled rose-pine status bar (cpu/ram, pills)
- [x] switch from oh-my-zsh to something faster → antidote + starship, cached
      compinit (OMZ was only ~7ms; real win was killing compinit-rebuild spikes)
- [x] rehaul kitty conf → slimmed 2230→~100 lines, rose-pine on true black
- [x] ghostty is too slow, transition back to kitty → i3 $mod+Return = kitty,
      ghostty config removed (snap binary left; `sudo snap remove ghostty` to drop)
- [x] how nice can i make i3 look → rose-pine colors/gaps/borders, picom
      (blur/rounded/shadows), i3blocks Nerd Font icons, rofi + dunst themes
- [x] neovim feels too bare → telescope, treesitter, which-key, LSP
      (lua_ls/clangd/jedi/ruff), nvim-cmp + LuaSnip

## Remaining

- [ ] the Makefile is unprepared to transition machines — it doesn't install
      everything used daily (claude, opencode, neovim, uv tools, mason servers,
      antidote, starship, picom/rofi/dunst/i3blocks deploys, etc.)
- [ ] add my ~/.claude/CLAUDE.md and ~/.claude/skills to the repo + deploy
