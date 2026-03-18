# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal dotfiles for an Arch Linux / Debian system running i3wm or Hyprland, with Neovim (AstroNvim-based), Zsh + Oh My Zsh, tmux, and kitty/alacritty as the terminal.

## Structure

| Path | Purpose |
|------|---------|
| `nvim/` | Active Neovim config (AstroNvim v5 + Lazy.nvim) |
| `astro.nvim/` | Older AstroNvim config (kept for reference) |
| `hyprland-configs/` | Hyprland WM, waybar, swaylock, hyprpaper |
| `config` | i3wm config (no extension — place at `~/.config/i3/config`) |
| `.zshrc` | Zsh config with Oh My Zsh, aliases, helpers |
| `.tmux.conf` | Tmux config |
| `.gitconfig` | Git config |
| `.vimrc` | Legacy Vim config (also sourced by Neovim via `nvim/vimrc.vim`) |
| `kitty.conf` / `alacritty.toml` | Terminal emulator configs |
| `setup_debian.sh` | Bootstrap script for Debian systems |
| `extra/` | Miscellaneous scripts (quote-of-the-day, wallpaper setter, meditations) |
| `xrandr/` | Monitor layout shell scripts |

## Neovim Architecture (`nvim/`)

- `init.lua` — bootstraps Lazy.nvim, sources `vimrc.vim` (which re-exports `~/.vimrc`), then loads `lazy_setup`, `statusline`, and `polish`
- `lua/lazy_setup.lua` — configures Lazy.nvim with AstroNvim v5 as the base distribution
- `lua/polish.lua` — **authoritative** place for vim options and keymaps; runs last so it overrides anything set by plugins
- `lua/statusline.lua` — custom hand-rolled statusline with git hunk counts via gitsigns
- `lua/community.lua` — AstroCommunity imports (currently disabled)
- `lua/plugins/` — plugin specs: `astrocore.lua` (features + buffer mappings), `astrolsp.lua` (LSP config), `astroui.lua` (colorscheme + highlight overrides), `mason.lua`, `treesitter.lua`, `render-markdown.lua`, colorschemes (`rose-pine.lua`, `gruvbox.lua`), `user.lua` (presence, lsp_signature, dashboard)
- `vimrc.vim` — re-exports `~/.vimrc` into Neovim's runtime path
- `.stylua.toml` — StyLua formatter config for Lua files

**Colorscheme:** `rose-pine-main` set in `astroui.lua`. Background forced to `#000000` via highlight override in the same file.
**Leader key:** `<Space>` | **Local leader:** `,`

## Formatting

- Lua (Neovim config): use `stylua` — config at `nvim/.stylua.toml`
- Python: use `black` (or `uv tool run black <file>`); bound to `<C-b>` in Neovim

## Deployment

Files are manually copied to their destinations (no symlink manager like stow). The `setup_debian.sh` script shows where each file lands:

- `~/.zshrc`, `~/.tmux.conf`, `~/.vimrc`, `~/.gitconfig`
- `~/.config/kitty/kitty.conf`
- `~/.config/nvim/` ← contents of `nvim/`
- `~/.config/i3/config` ← `config`
- `~/.config/hypr/`, `~/.config/waybar/`, `~/.config/swaylock/` ← from `hyprland-configs/`

---

# Thoughts from Claude

## Session 1 — Bonsai cleanup (nvim/)

### Done
- **Deleted dead files** (never loaded, never required):
  - `lua/settings/set.lua` — duplicated polish.lua options
  - `lua/settings/remap.lua` — duplicated polish.lua keymaps
  - `lua/settings/autoreload.lua` — referenced non-existent `neotree.lua`/`undotree.lua`
  - `lua/vimrc.vim` — stray duplicate of root `vimrc.vim`
  - `lua/plugins/lsp.lua` — called `lspconfig.pyright.setup({})` directly, conflicting with AstroLSP
- **Cleaned `polish.lua`**: removed double vimrc source (init.lua already does it), duplicate `mapleader`, duplicate `termguicolors`, redundant `vim.cmd("colorscheme ...")` (astroui.lua owns colorscheme)
- **Cleaned `astrocore.lua`**: removed fooscript placeholder filetypes, removed `options` block (conflicted with polish.lua; polish always wins since it runs last — `number=false` vs `nu=true`, `signcolumn="no"` vs `signcolumn="yes"`)
- **Cleaned `rose-pine.lua`**: all opts were gruvbox-style keys that rose-pine ignores; stripped to minimal spec with only `styles.transparency`
- **Cleaned `gruvbox.lua`**: removed invalid opts including `colorscheme` key (not a gruvbox opt)
- **Cleaned `user.lua`**: removed LuaSnip `javascript→javascriptreact` boilerplate, removed autopairs rules with `"xxx"`/`"xx"` placeholder conditions

- **Fixed `render-markdown.lua`**: wrong dependency `nvim-mini/mini.nvim` → `echasnovski/mini.nvim`
- **`lazy_setup.lua`**: added `rocks = { hererocks = false }` — suppresses luarocks ❌ in checkhealth (no plugins use luarocks; confirmed by checkhealth output)
- **`lazy_setup.lua`**: removed verbose comments from AstroNvim opts (self-explanatory fields)

### checkhealth notes (live config, 2026-03-18)
All remaining warnings/errors are pre-existing, not caused by our changes:
- `lazygit`, `node`, `gdu`, `btm` not installed — all flagged Optional, no action needed
- snacks image/input/picker errors — missing optional tools (imagemagick, gs, mmdc) or headless-mode artifacts
- treesitter: `tree-sitter` CLI only needed for TSInstallFromGrammar, not normal use

### Still to consider
- Add `pyright`, `clangd`, `rust-analyzer` to `mason.lua` `ensure_installed` (currently only `lua-language-server` auto-installs)
- Add `cpp`, `markdown`, `bash`, `toml` to treesitter `ensure_installed` (many already installed by AstroNvim defaults)
- README TODOs: floating Python REPL (`:terminal python3` in a float, no new plugin needed), snippets (LuaSnip already present), emoji picker (`telescope-emoji.nvim`)
- Note: `~/.config/nvim` is a separate git repo — deploy dotfiles changes manually with `rsync -av --exclude='.git' ~/code/github.com/temataro/dotfiles/nvim/ ~/.config/nvim/`
